resource "aws_ecr_repository" "app" {
  name = var.project_name
  image_scanning_configuration { scan_on_push = true }
  image_tag_mutability = "MUTABLE"
  tags                 = { Name = var.project_name }
}

output "ecr_repo_url" {
  value = aws_ecr_repository.app.repository_url
}

