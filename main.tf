#################################################
# Provider and Data
#################################################

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

#################################################
# Network Module (This is dynamic)
#################################################

module "network" {
  source = "./modules/network"

  vpc_cidr                            = var.vpc_cidr
  enable_dns_support                  = var.enable_dns_support
  enable_dns_hostnames                = var.enable_dns_hostnames
  azs                                 = var.azs
  preferred_number_of_public_subnets  = var.preferred_number_of_public_subnets
  preferred_number_of_private_subnets = var.preferred_number_of_private_subnets
  tags                                = var.tags
  name                                = var.name
}

#################################################
# IAM Module
#################################################

module "iam" {
  source = "./modules/iam"
  tags   = var.tags
}

#################################################
# Security Module
#################################################

module "security" {
  source = "./modules/security"
  vpc_id = module.network.vpc_id
  tags   = var.tags
}

#################################################
# ALB Module
#################################################

module "alb" {
  source = "./modules/ALB"

  vpc_id = module.network.vpc_id

  public_subnets_by_az  = module.network.public_subnets_by_az
  private_subnets_by_az = module.network.private_subnets_by_az

  ext_alb_sg_id = module.security.ext_alb_sg_id
  int_alb_sg_id = module.security.int_alb_sg_id
  tags          = var.tags
}


#################################################
# Compute Module
#################################################

module "compute" {
  source = "./modules/compute"

  region               = var.region
  images               = var.images
  keypair              = var.keypair
  tags                 = var.tags
  iam_instance_profile = module.iam.instance_profile_name

  bastion_sg_id  = module.security.bastion_sg_id
  nginx_sg_id    = module.security.nginx_sg_id
  web_sg_id      = module.security.webserver_sg_id

  subnets_public  = module.network.public_subnet_ids
  subnets_private = module.network.private_subnet_ids

  alb_target_groups = {
    nginx     = module.alb.nginx_tgt_arn
    wordpress = module.alb.wordpress_tgt_arn
    tooling   = module.alb.tooling_tgt_arn
  }
}

#################################################
# EFS Module
#################################################

module "efs" {
  source = "./modules/EFS"

  account_no              = var.account_no
  tags                    = var.tags
  private_subnets_by_az   = module.network.private_subnets_by_az
  efs_sg_id               = module.security.datalayer_sg_id
}

#################################################
# RDS Module
#################################################

module "rds" {
  source           = "./modules/RDS"
  private_subnets  = module.network.private_subnet_ids
  datalayer_sg_id  = module.security.datalayer_sg_id
  tags             = var.tags
  master_username  = var.master-username
  master_password  = var.master-password
  db_name          = "maxidb"
}
