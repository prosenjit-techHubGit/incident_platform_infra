resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${local.name}/triage-frontend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${local.name}/triage-backend"
  retention_in_days = 7
}
