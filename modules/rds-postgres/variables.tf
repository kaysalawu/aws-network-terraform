
variable "identifier" {
  description = "Identifier for the RDS instance"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the RDS instance will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the RDS subnet group"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the RDS instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
}

variable "db_username" {
  description = "Username for the PostgreSQL database"
  type        = string
}

variable "db_password" {
  description = "Password for the PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "13.20"
}

variable "instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage for the RDS instance (in GB)"
  type        = number
  default     = 20
}

variable "parameter_group_name" {
  description = "Parameter group name for the RDS instance"
  type        = string
  default     = "default.postgres13"
}

variable "publicly_accessible" {
  description = "Whether the RDS instance should be publicly accessible"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Whether the RDS instance should be deployed in multiple availability zones"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot when deleting the RDS instance"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
