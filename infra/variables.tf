variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "sample-python-app"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs (2 minimum)"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDRs (2 minimum)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "azs" {
  description = "AZs to use (2 values recommended)"
  type        = list(string)
  default     = [2]
}

variable "app_container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 5000
}

variable "desired_count" {
  description = "ECS desired count"
  type        = number
  default     = 2
}

variable "image_uri" {
  description = "ECR image URI (including tag). Provided by CI pipeline."
  type        = string
  default     = ""
}
