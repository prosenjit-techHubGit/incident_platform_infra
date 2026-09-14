variable "aws_region" {
  description = "AWS region. us-east-1 is cheapest and has the clearest Free Tier."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for most resources. ECS cluster stays incident-platform."
  type        = string
  default     = "incident-platform"
}

variable "environment" {
  description = "Environment label (single root module; use dev for the trial account)."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR. Public + private /24s are carved from this."
  type        = string
  default     = "10.40.0.0/16"
}

variable "private_dns_namespace" {
  description = "Cloud Map private DNS namespace (replaces Compose service names)."
  type        = string
  default     = "incident.local"
}

variable "image_tag" {
  description = "ECR image tag for both triage services."
  type        = string
  default     = "latest"
}

variable "openai_api_key" {
  description = "OpenAI API key stored in Secrets Manager and injected into the backend task."
  type        = string
  sensitive   = true
}

variable "openai_model_name" {
  description = "Model id passed through to the triage backend (OPENAI_MODEL_NAME)."
  type        = string
  default     = "gpt-4o-mini"
}

variable "budget_notification_email" {
  description = "Email for AWS Budget warnings at $20 and $50."
  type        = string
}

variable "db_name" {
  type    = string
  default = "triage"
}

variable "db_username" {
  type    = string
  default = "triage"
}

variable "desired_count" {
  description = "Desired Fargate tasks per service (keep at 1 for credits)."
  type        = number
  default     = 1
}
