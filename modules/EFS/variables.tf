variable "account_no" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "efs_sg_id" {
  type = string
}
