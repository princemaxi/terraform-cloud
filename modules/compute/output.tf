output "asg_ids" {
  description = "Map of Auto Scaling Group IDs"
  value = {
    for k, v in aws_autoscaling_group.asg :
    k => v.id
  }
}

output "asg_names" {
  description = "Map of Auto Scaling Group names"
  value = {
    for k, v in aws_autoscaling_group.asg :
    k => v.name
  }
}
