##########################################
# Security Groups
##########################################

resource "aws_security_group" "ext_alb_sg" {
  name   = "ext-alb-sg"
  vpc_id = var.vpc_id
  tags   = merge(var.tags, { Name = "ext-alb-sg" })
}

resource "aws_security_group" "bastion_sg" {
  name   = "bastion-sg"
  vpc_id = var.vpc_id
  tags   = merge(var.tags, { Name = "bastion-sg" })
}

resource "aws_security_group" "nginx_sg" {
  name   = "nginx-sg"
  vpc_id = var.vpc_id
  tags   = merge(var.tags, { Name = "nginx-sg" })
}

resource "aws_security_group" "int_alb_sg" {
  name   = "int-alb-sg"
  vpc_id = var.vpc_id
  tags   = merge(var.tags, { Name = "int-alb-sg" })
}

resource "aws_security_group" "webserver_sg" {
  name   = "webserver-sg"
  vpc_id = var.vpc_id
  tags   = merge(var.tags, { Name = "webserver-sg" })
}

resource "aws_security_group" "datalayer_sg" {
  name   = "datalayer-sg"
  vpc_id = var.vpc_id
  tags   = merge(var.tags, { Name = "datalayer-sg" })
}

##########################################
# Locals – Security Group Rules + Map
##########################################

locals {
  sg_rules = {
    ext_alb_sg = [
      { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTP from Internet" }
    ]
    bastion_sg = [
      { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "SSH from Internet" }
    ]
    nginx_sg = [
      { from_port = 80, to_port = 80, protocol = "tcp", source = "ext_alb_sg" },
      { from_port = 22, to_port = 22, protocol = "tcp", source = "bastion_sg" }
    ]
    int_alb_sg = [
      { from_port = 80, to_port = 80, protocol = "tcp", source = "nginx_sg" }
    ]
    webserver_sg = [
      { from_port = 80, to_port = 80, protocol = "tcp", source = "int_alb_sg" },
      { from_port = 22, to_port = 22, protocol = "tcp", source = "bastion_sg" }
    ]
    datalayer_sg = [
      { from_port = 2049, to_port = 2049, protocol = "tcp", source = "webserver_sg" },
      { from_port = 3306, to_port = 3306, protocol = "tcp", source = "webserver_sg" },
      { from_port = 3306, to_port = 3306, protocol = "tcp", source = "bastion_sg" }
    ]
  }

  sg_map = {
    ext_alb_sg   = aws_security_group.ext_alb_sg.id
    bastion_sg   = aws_security_group.bastion_sg.id
    nginx_sg     = aws_security_group.nginx_sg.id
    int_alb_sg   = aws_security_group.int_alb_sg.id
    webserver_sg = aws_security_group.webserver_sg.id
    datalayer_sg = aws_security_group.datalayer_sg.id
  }

  sg_to_sg_rules = flatten([
    for target, rules in local.sg_rules : [
      for rule in rules : {
        target = target
        source = rule.source
        port   = rule.from_port
        proto  = rule.protocol
      }
      if contains(keys(rule), "source")
    ]
  ])

  cidr_rules = flatten([
    for sg, rules in local.sg_rules : [
      for rule in rules : {
        sg          = sg
        from_port   = rule.from_port
        to_port     = rule.to_port
        protocol    = rule.protocol
        cidr_blocks = rule.cidr_blocks
        description = lookup(rule, "description", null)
      }
      if contains(keys(rule), "cidr_blocks")
    ]
  ])
}

##########################################
# CIDR-based ingress rules
##########################################

resource "aws_security_group_rule" "cidr_ingress" {
  for_each = { for r in local.cidr_rules : "${r.sg}-${r.from_port}" => r }

  type              = "ingress"
  security_group_id = local.sg_map[each.value.sg]
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
}

##########################################
# SG-to-SG ingress rules
##########################################

resource "aws_security_group_rule" "sg_to_sg_ingress" {
  for_each = { for r in local.sg_to_sg_rules : "${r.target}-${r.source}-${r.port}" => r }

  type                     = "ingress"
  security_group_id        = local.sg_map[each.value.target]
  source_security_group_id = local.sg_map[each.value.source]
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = each.value.proto
}

##########################################
# Egress rules (allow all)
##########################################

resource "aws_security_group_rule" "egress_all" {
  for_each = local.sg_map

  type              = "egress"
  security_group_id = each.value
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
