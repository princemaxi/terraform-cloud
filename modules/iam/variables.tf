variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}

variable "role_name" {
  type        = string
  description = "IAM role name"
  default     = "ec2_instance_role"
}

variable "policy_name" {
  type        = string
  description = "IAM policy name"
  default     = "ec2_instance_policy"
}

variable "instance_profile_name" {
  type        = string
  description = "IAM instance profile name"
  default     = "ec2_instance_profile"
}
