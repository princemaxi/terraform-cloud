##########################################
# Common
##########################################

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

##########################################
# ALB Security Groups
##########################################

variable "ext_alb_sg_id" {
  description = "Security group ID for external ALB"
  type        = string
}

variable "int_alb_sg_id" {
  description = "Security group ID for internal ALB"
  type        = string
}

##########################################
# Subnets (ONE per AZ)
##########################################

variable "public_subnets_by_az" {
  description = "Map of Availability Zone to PUBLIC subnet ID (one per AZ)"
  type        = map(string)
}

variable "private_subnets_by_az" {
  description = "Map of Availability Zone to PRIVATE subnet ID (one per AZ)"
  type        = map(string)
}
