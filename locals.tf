data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  name = "${var.project_name}-${var.environment}"
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnet_cidrs  = [for i in range(2) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnet_cidrs = [for i in range(2) : cidrsubnet(var.vpc_cidr, 8, i + 10)]

  cluster_name          = "incident-platform"
  backend_service_name  = "triage-backend"
  frontend_service_name = "triage-frontend"

  backend_discovery_url = "http://${local.backend_service_name}.${var.private_dns_namespace}:8000"
  alb_origin            = "http://${aws_lb.this.dns_name}"
}
