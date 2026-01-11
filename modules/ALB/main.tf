##########################################
# ALB Module – Production Safe
# One Subnet per AZ (Terraform Cloud Safe)
##########################################

###########################
# External ALB (PUBLIC)
###########################
resource "aws_lb" "ext_alb" {
  name               = "ext-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [var.ext_alb_sg_id]

  # One subnet per AZ (values of AZ → subnet map)
  subnets = values(var.public_subnets_by_az)

  tags = merge(var.tags, {
    Name = "ACS-ext-alb"
  })
}

###########################
# Internal ALB (PRIVATE)
###########################
resource "aws_lb" "int_alb" {
  name               = "int-alb"
  internal           = true
  load_balancer_type = "application"

  security_groups = [var.int_alb_sg_id]

  # One subnet per AZ (values of AZ → subnet map)
  subnets = values(var.private_subnets_by_az)

  tags = merge(var.tags, {
    Name = "ACS-int-alb"
  })
}

###########################
# Target Groups
###########################
resource "aws_lb_target_group" "nginx" {
  name     = "nginx-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-399"
  }

  tags = merge(var.tags, {
    Name = "ACS-nginx-tg"
  })
}

resource "aws_lb_target_group" "wordpress" {
  name     = "wordpress-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-399"
  }

  tags = merge(var.tags, {
    Name = "ACS-wordpress-tg"
  })
}

resource "aws_lb_target_group" "tooling" {
  name     = "tooling-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-399"
  }

  tags = merge(var.tags, {
    Name = "ACS-tooling-tg"
  })
}
