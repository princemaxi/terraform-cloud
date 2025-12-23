output "efs_id" {
  description = "EFS File System ID"
  value       = aws_efs_file_system.acs_efs.id
}

output "wordpress_ap_id" {
  description = "EFS Access Point ID for WordPress"
  value       = aws_efs_access_point.wordpress.id
}

output "tooling_ap_id" {
  description = "EFS Access Point ID for Tooling"
  value       = aws_efs_access_point.tooling.id
}

output "kms_key_id" {
  description = "KMS Key ID used to encrypt EFS"
  value       = aws_kms_key.acs_kms.id
}
