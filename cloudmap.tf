resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = var.private_dns_namespace
  description = "Service discovery for incident triage (frontend → backend)"
  vpc         = aws_vpc.this.id
}

resource "aws_service_discovery_service" "backend" {
  name = local.backend_service_name

  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.this.id
    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = 5
      type = "A"
    }
  }

  # No custom health check: custom mode starts instances UNHEALTHY and
  # keeps them out of DNS until UpdateInstanceCustomHealthStatus is called.
  # ECS still registers/deregisters task IPs on start/stop.
}

