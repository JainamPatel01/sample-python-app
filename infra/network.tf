# Get AZs if not provided
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  use_azs = length(var.azs) >= 2 ? var.azs : slice(data.aws_availability_zones.available.names, 0, 2)
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Public subnets across 2 AZs
resource "aws_subnet" "public" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = var.azs[index(keys(var.public_subnets), each.key)]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-public-${each.key}"
  }
}

# Private subnets across 2 AZs
resource "aws_subnet" "private" {
  for_each                = var.private_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = var.azs[index(keys(var.private_subnets), each.key)]
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project_name}-private-${each.key}"
  }
}


# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

# Associate public subnets with public rt
resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# EIPs and NAT Gateways (one per AZ/private subnet)
resource "aws_eip" "nat_eip" {
  for_each = aws_subnet.public
  domain   = "vpc"
  tags     = { Name = "${var.project_name}-nat-eip-${each.key}" }
}

resource "aws_nat_gateway" "nat" {
  for_each      = aws_subnet.public
  allocation_id = aws_eip.nat_eip[each.key].id
  subnet_id     = each.value.id
  tags          = { Name = "${var.project_name}-nat-${each.key}" }
  depends_on    = [aws_internet_gateway.igw]
}

# Private route tables with NAT gateway (one per AZ)
resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[each.key].id
  }

  tags = {
    Name = "${var.project_name}-private-rt-${each.key}"
  }
}



# Associate private subnets with their private rt
resource "aws_route_table_association" "private_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
