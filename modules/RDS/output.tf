output "rds_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.acs_rds.id
}

output "rds_endpoint" {
  description = "RDS endpoint address"
  value       = aws_db_instance.acs_rds.endpoint
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.acs_rds.port
}
