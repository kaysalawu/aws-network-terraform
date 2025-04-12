
# Security group for RDS

resource "aws_security_group" "rds_security_group" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Security group for RDS PostgreSQL instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Subnet group for RDS

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.name_prefix}-rds-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

# RDS PostgreSQL instance

resource "aws_db_instance" "rds_instance" {
  identifier              = "${var.name_prefix}-rds-instance"
  allocated_storage       = var.allocated_storage
  engine                  = "postgres"
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  name                    = var.db_name
  username                = var.db_username
  password                = var.db_password
  parameter_group_name    = var.parameter_group_name
  publicly_accessible     = var.publicly_accessible
  skip_final_snapshot     = var.skip_final_snapshot
  vpc_security_group_ids  = [aws_security_group.rds_security_group.id]
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  tags                    = var.tags
}
