terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"          # Express Mode needs a recent provider
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# -------------------------------------------------
# IAM Roles required by ECS Express Mode
# -------------------------------------------------

# 1. Task Execution Role (pulls images + writes logs)
resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole-simple-flask"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 2. Infrastructure Role (lets ECS create ALB, security groups, etc.)
resource "aws_iam_role" "ecs_infrastructure" {
  name = "ecsInfrastructureRoleForExpressServices"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_infrastructure" {
  role       = aws_iam_role.ecs_infrastructure.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSInfrastructureRoleforExpressGatewayServices"
}

# -------------------------------------------------
# ECS Express Mode Service
# -------------------------------------------------

resource "aws_ecs_express_gateway_service" "staging" {
  service_name            = "simple-flask-app-staging"
  execution_role_arn      = aws_iam_role.ecs_task_execution.arn
  infrastructure_role_arn = aws_iam_role.ecs_infrastructure.arn

  primary_container {
    image          = var.ecr_image_identifier
    container_port = 5000          # <-- change this if your Flask app listens on a different port
  }

  # Optional but recommended
  health_check_path = "/"          # change to /health if you have a health endpoint
  cpu               = "256"
  memory            = "512"
}

# -------------------------------------------------
# Variables & Outputs
# -------------------------------------------------

variable "ecr_image_identifier" {
  description = "Full URI of the Docker image in ECR"
  type        = string
}

output "service_url" {
  value = aws_ecs_express_gateway_service.staging.service_arn
}