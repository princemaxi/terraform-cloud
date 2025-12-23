variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "tags" {
  description = "Common tags for all security groups"
  type        = map(string)
}
