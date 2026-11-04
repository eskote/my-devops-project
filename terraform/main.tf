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

data "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole-simple-flask"
}

data "aws_iam_role" "ecs_infrastructure" {
  name = "ecsInfrastructureRoleForExpressServices"
}

# -------------------------------------------------
# ECS Express Mode Service
# -------------------------------------------------

resource "aws_ecs_express_gateway_service" "staging" {
  service_name            = "simple-flask-app-staging"
  execution_role_arn      = data.aws_iam_role.ecs_task_execution.arn
  infrastructure_role_arn = data.aws_iam_role.ecs_infrastructure.arn

  primary_container {
    image          = var.ecr_image_identifier
    container_port = 5000
  }

  health_check_path = "/"
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