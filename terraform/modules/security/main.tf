############################################
# Security Module - Security Groups
############################################

# --- Bastion SG: SSH from trusted CIDR only ---
resource "aws_security_group" "bastion" {
  name_prefix = "${var.project_name}-bastion-"
  description = "Allow SSH from trusted IPs only"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from trusted CIDRs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.trusted_ssh_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-bastion-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

# --- ALB SG: HTTP/HTTPS from the internet ---
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  description = "Allow HTTP/HTTPS from the internet"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-alb-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

# --- App tier SG: only from ALB + SSH only from bastion ---
resource "aws_security_group" "app" {
  name_prefix = "${var.project_name}-app-"
  description = "Allow app traffic from ALB and SSH from bastion only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App port from ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "SSH from bastion only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-app-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

# --- Database SG: only from app tier, no public access ever ---
resource "aws_security_group" "database" {
  name_prefix = "${var.project_name}-db-"
  description = "Allow DB traffic from app tier only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "DB port from app tier"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-db-sg" })

  lifecycle {
    create_before_destroy = true
  }
}
