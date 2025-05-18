
####################################################
# security group
####################################################

resource "aws_security_group" "this" {
  name        = "${var.identifier}-rds-sg"
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

####################################################
# subnet group
####################################################

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-rds-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

####################################################
# rds postgresql instance
####################################################

resource "aws_db_instance" "this" {
  identifier              = var.identifier
  allocated_storage       = var.allocated_storage
  engine                  = "postgres"
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  parameter_group_name    = var.parameter_group_name
  publicly_accessible     = var.publicly_accessible
  skip_final_snapshot     = var.skip_final_snapshot
  vpc_security_group_ids  = [aws_security_group.this.id]
  db_subnet_group_name    = aws_db_subnet_group.this.name
  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  tags                    = var.tags
}
