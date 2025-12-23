variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "enable_dns_support" {
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  type        = bool
  default     = true
}

variable "azs" {
  type        = list(string)
  description = "List of availability zones"
}

variable "preferred_number_of_public_subnets" {
  type        = number
  default     = 2
}

variable "preferred_number_of_private_subnets" {
  type        = number
  default     = 2
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
}

variable "name" {
  type        = string
  description = "Name of the environment/project"
}
