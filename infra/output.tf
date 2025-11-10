output "alb_dns" {
  description = "ALB DNS name"
  value       = aws_lb.alb.dns_name
}

output "ecr_repo_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecs_cluster" {
  value = aws_ecs_cluster.cluster.id
}
