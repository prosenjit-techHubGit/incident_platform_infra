# Incident platform infra (triage only)

Terraform for a credit-conscious **ECS Fargate** deploy of `incident_triage_workflow`:

public ALB → frontend nginx → Cloud Map `triage-backend.incident.local` → FastAPI → private RDS Postgres.

**Architecture (app + AWS):** see [`../incident_triage_workflow/docs/architecture.md`](../incident_triage_workflow/docs/architecture.md).

**Not in this phase:** `incident_telemetry_platform` (Spring / Option 3+4). Add that later.

## What this creates

- VPC in 2 AZs (public + private), Internet Gateway, **no NAT Gateway**
- Fargate tasks in public subnets with public IPs (ECR + OpenAI without NAT)
- RDS `db.t4g.micro` Postgres 16 in private subnets (backend SG only on 5432)
- ECR repos: `incident-triage-frontend`, `incident-triage-backend`
- Secrets Manager: `OPENAI_API_KEY`, `DATABASE_URL`
- ECS cluster `incident-platform` (2 services, 1 task each)
- Cloud Map namespace `incident.local`
- Public ALB `:80` (idle timeout 300s)
- AWS Budget emails at **$20** (40% of $50) and **$50**

## Prerequisites

- AWS CLI logged in (`aws sts get-caller-identity`)
- Terraform >= 1.5
- Docker
- Sibling checkout: `../incident_triage_workflow`

## Deploy

```powershell
copy terraform.tfvars.example terraform.tfvars
# set openai_api_key and budget_notification_email

terraform init
terraform apply
.\scripts\build-and-push.ps1
```

First apply creates ECR/RDS/ECS before images exist; tasks fail to pull until the script pushes. Then:

```powershell
terraform output alb_url
```

Open the ALB URL, submit an incident in the chat UI, and confirm a triage response.

Tear down after each demo day (ALB + Fargate + RDS keep billing while they exist):

```powershell
terraform destroy
```

## App wiring

| Env | Value |
| --- | --- |
| Frontend `TRIAGE_BACKEND_URL` | `http://triage-backend.incident.local:8000` |
| Backend `CORS_ORIGINS` | ALB `http://` DNS name |
| Backend `DATABASE_URL` / `OPENAI_API_KEY` | Secrets Manager |

Compose still defaults `TRIAGE_BACKEND_URL` to `http://backend:8000`.
