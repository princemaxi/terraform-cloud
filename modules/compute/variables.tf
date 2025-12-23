variable "region" {
  type        = string
  description = "AWS region to deploy resources"
}

variable "images" {
  type        = map(string)
  description = "AMI IDs per region"
}

variable "keypair" {
  type        = string
  description = "Key pair name for EC2 instances"
}

variable "tags" {
  type        = map(string)
  description = "Common tags for resources"
}

variable "bastion_sg_id" {
  type        = string
  description = "Security Group ID for Bastion instances"
}

variable "nginx_sg_id" {
  type        = string
  description = "Security Group ID for Nginx instances"
}

variable "web_sg_id" {
  type        = string
  description = "Security Group ID for WordPress/Tooling instances"
}

variable "subnets_public" {
  type        = list(string)
  description = "List of public subnet IDs"
}

variable "subnets_private" {
  type        = list(string)
  description = "List of private subnet IDs"
}

variable "iam_instance_profile" {
  type        = string
  description = "IAM instance profile name"
}

variable "alb_target_groups" {
  type = map(string)
  description = "Target groups for ASG attachment: keys = bastion/nginx/wordpress/tooling, values = TG ARNs"
}
