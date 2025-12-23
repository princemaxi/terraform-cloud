################################################
# SNS Topic for Auto Scaling Notifications
################################################
resource "aws_sns_topic" "asg_notifications" {
  name = "default-autoscaling-topic"
}

resource "aws_autoscaling_notification" "asg_events" {
  group_names = [
  for asg in aws_autoscaling_group.asg :
  asg.name
]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.asg_notifications.arn
}

################################################
# Random AZ shuffle for placement
################################################
resource "random_shuffle" "az_list" {
  input = var.subnets_public
}

################################################
# Launch Templates
################################################
locals {
  instances = [
    {
      name      = "bastion"
      sg_id     = var.bastion_sg_id
      subnets   = var.subnets_public
      user_data = "userdata/bastion.sh"
      placement = 0
    },
    {
      name      = "nginx"
      sg_id     = var.nginx_sg_id
      subnets   = var.subnets_public
      user_data = "userdata/nginx.sh"
      placement = 1
    },
    {
      name      = "wordpress"
      sg_id     = var.web_sg_id
      subnets   = var.subnets_private
      user_data = "userdata/wordpress.sh"
      placement = 0
    },
    {
      name      = "tooling"
      sg_id     = var.web_sg_id
      subnets   = var.subnets_private
      user_data = "userdata/tooling.sh"
      placement = 1
    }
  ]

  instances_map = {
    for i in local.instances :
    i.name => i.subnets
  }
}

# Create Launch Templates dynamically
resource "aws_launch_template" "lt" {
  for_each = { for i in local.instances : i.name => i }

  name_prefix   = "${each.key}-lt-"
  image_id      = lookup(var.images, var.region, "ami-default123")
  instance_type = "t2.micro"
  vpc_security_group_ids = [each.value.sg_id]

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  key_name = var.keypair

  placement {
    availability_zone = each.value.subnets[each.value.placement]
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${each.key}-instance" })
  }

  user_data = filebase64(each.value.user_data)

  lifecycle {
    create_before_destroy = true
  }
}

################################################
# Auto Scaling Groups
################################################
resource "aws_autoscaling_group" "asg" {
  for_each = aws_launch_template.lt

  name                      = "${each.key}-asg"
  max_size                  = 2
  min_size                  = 1
  desired_capacity          = 1
  health_check_type         = "EC2"
  health_check_grace_period = 300

  vpc_zone_identifier = lookup(local.instances_map, each.key, var.subnets_private)

  launch_template {
    id      = each.value.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${each.key}-instance"
    propagate_at_launch = true
  }
}

################################################
# Attach ASGs to ALB Target Groups
################################################
resource "aws_autoscaling_attachment" "asg_attach" {
  for_each = var.alb_target_groups

  autoscaling_group_name = aws_autoscaling_group.asg[each.key].id
  lb_target_group_arn    = each.value
}
