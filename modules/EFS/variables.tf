variable "account_no" {
  description = "AWS account number"
  type        = string
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
}

variable "efs_sg_id" {
  description = "Security group ID for EFS"
  type        = string
}

variable "private_subnets_by_az" {
  description = "Map of AZ => private subnet ID (ONE per AZ)"
  type        = map(string)
}
