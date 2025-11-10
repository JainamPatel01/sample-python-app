output "alb_dns" {
  description = "ALB DNS name"
  value       = aws_lb.alb.dns_name
}


output "ecs_cluster" {
  value = aws_ecs_cluster.cluster.id
}
