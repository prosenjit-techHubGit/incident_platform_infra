output "alb_url" {
  description = "Public chat UI (HTTP). Open this after images are pushed and tasks are healthy."
  value       = local.alb_origin
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecr_frontend_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "ecr_backend_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "backend_discovery_url" {
  description = "Cloud Map URL the frontend nginx uses (TRIAGE_BACKEND_URL)."
  value       = local.backend_discovery_url
}

output "rds_address" {
  value = aws_db_instance.this.address
}
