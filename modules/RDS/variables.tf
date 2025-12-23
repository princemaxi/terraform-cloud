variable "private_subnets" {
  description = "List of private subnet IDs for the RDS subnet group"
  type        = list(string)
}

variable "tags" {
  description = "Common tags applied to all RDS resources"
  type        = map(string)
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "maxidb"
}

variable "master_username" {
  description = "RDS master username"
  type        = string
}

variable "master_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "datalayer_sg_id" {
  description = "Security group ID for the RDS instance"
  type        = string
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = true
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small"
}

variable "allocated_storage" {
  description = "RDS allocated storage (GB)"
  type        = number
  default     = 20
}

variable "storage_type" {
  description = "RDS storage type"
  type        = string
  default     = "gp2"
}

variable "engine" {
  description = "Database engine"
  type        = string
  default     = "mysql"
}

variable "engine_version" {
  description = "Engine version"
  type        = string
  default     = "5.7"
}
