resource "aws_security_group" "alb" {
  name        = "${local.name}-alb"
  description = "Public ALB HTTP"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-alb"
  }
}

resource "aws_security_group" "frontend" {
  name        = "${local.name}-frontend"
  description = "Triage frontend nginx (ALB only inbound)"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Public IP + IGW: ECR pull, no NAT. Also reach backend over Cloud Map.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-frontend"
  }
}

resource "aws_security_group" "backend" {
  name        = "${local.name}-backend"
  description = "Triage backend (frontend only inbound)"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "API from frontend nginx"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  # Public IP + IGW: ECR, Secrets Manager, OpenAI. Private: RDS.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-backend"
  }
}

resource "aws_security_group" "rds" {
  name        = "${local.name}-rds"
  description = "Postgres from triage backend only"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "Postgres from backend"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  tags = {
    Name = "${local.name}-rds"
  }
}
