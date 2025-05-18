
output "endpoint" {
  description = "The endpoint of the RDS PostgreSQL instance"
  value       = aws_db_instance.this.endpoint
}

output "security_group_id" {
  description = "The security group ID for the RDS instance"
  value       = aws_security_group.this.id
}
