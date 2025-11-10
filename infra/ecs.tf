resource "aws_ecs_cluster" "cluster" {
  name = "${var.project_name}-cluster"
}

# Task definition
resource "aws_ecs_task_definition" "task" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name  = "${var.project_name}-container"
      image = var.image_uri != "" ? var.image_uri : "${aws_ecr_repository.app.repository_url}:latest"
      portMappings = [
        {
          containerPort = var.app_container_port
          hostPort      = var.app_container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = var.project_name
        }
      }
    }
  ])
}

resource "aws_ecs_service" "service" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    subnets         = [for s in aws_subnet.private : s.id]
    security_groups = [aws_security_group.svc_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "${var.project_name}-container"
    container_port   = var.app_container_port
  }

  depends_on = [aws_lb_listener.http]
}
