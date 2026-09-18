############################################
# Database Module - RDS
############################################

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.database_subnet_ids

  tags = merge(var.tags, { Name = "${var.project_name}-db-subnet-group" })
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db"
  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.allocated_storage
  storage_type           = "gp3"
  storage_encrypted      = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password # supply via TF_VAR_db_password / secrets manager, never commit

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.database_sg_id]

  multi_az            = var.multi_az
  publicly_accessible = false
  skip_final_snapshot = var.skip_final_snapshot
  backup_retention_period = var.backup_retention_period

  tags = merge(var.tags, { Name = "${var.project_name}-db" })
}
