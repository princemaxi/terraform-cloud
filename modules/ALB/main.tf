###########################
# Resolve ONE subnet per AZ
###########################
data "aws_subnet" "private" {
  for_each = toset(var.private_subnets)
  id       = each.value
}

data "aws_subnet" "public" {
  for_each = toset(var.public_subnets)
  id       = each.value
}

locals {
  private_subnets_per_az = {
    for s in data.aws_subnet.private :
    s.availability_zone => s.id...
  }

  public_subnets_per_az = {
    for s in data.aws_subnet.public :
    s.availability_zone => s.id...
  }

  # pick FIRST subnet per AZ (AWS requirement)
  private_alb_subnets = [
    for az, ids in local.private_subnets_per_az : ids[0]
  ]

  public_alb_subnets = [
    for az, ids in local.public_subnets_per_az : ids[0]
  ]
}

###########################
# External ALB (PUBLIC)
###########################
resource "aws_lb" "ext_alb" {
  name               = "ext-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.ext_alb_sg_id]
  subnets            = local.public_alb_subnets

  tags = merge(var.tags, { Name = "ACS-ext-alb" })
}

###########################
# Internal ALB (PRIVATE)
###########################
resource "aws_lb" "int_alb" {
  name               = "int-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.int_alb_sg_id]
  subnets            = local.private_alb_subnets

  tags = merge(var.tags, { Name = "ACS-int-alb" })
}

###########################
# Target Groups
###########################
resource "aws_lb_target_group" "nginx" {
  name     = "nginx-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id  = var.vpc_id
}

resource "aws_lb_target_group" "wordpress" {
  name     = "wordpress-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id  = var.vpc_id
}

resource "aws_lb_target_group" "tooling" {
  name     = "tooling-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id  = var.vpc_id
}
