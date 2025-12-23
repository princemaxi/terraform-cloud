output "ext_alb_sg_id" {
  description = "External ALB security group ID"
  value       = aws_security_group.ext_alb_sg.id
}

output "int_alb_sg_id" {
  description = "Internal ALB security group ID"
  value       = aws_security_group.int_alb_sg.id
}

output "bastion_sg_id" {
  description = "Bastion security group ID"
  value       = aws_security_group.bastion_sg.id
}

output "nginx_sg_id" {
  description = "Nginx security group ID"
  value       = aws_security_group.nginx_sg.id
}

output "webserver_sg_id" {
  description = "Webserver security group ID"
  value       = aws_security_group.webserver_sg.id
}

output "datalayer_sg_id" {
  description = "Datalayer security group ID"
  value       = aws_security_group.datalayer_sg.id
}
