output "ext_alb_arn" {
  value = aws_lb.ext_alb.arn
}

output "int_alb_arn" {
  value = aws_lb.int_alb.arn
}

output "nginx_tgt_arn" {
  value = aws_lb_target_group.nginx.arn
}

output "wordpress_tgt_arn" {
  value = aws_lb_target_group.wordpress.arn
}

output "tooling_tgt_arn" {
  value = aws_lb_target_group.tooling.arn
}
