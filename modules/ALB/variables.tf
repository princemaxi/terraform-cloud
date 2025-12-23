variable "tags" {
  type = map(string)
}

variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "ext_alb_sg_id" {
  type = string
}

variable "int_alb_sg_id" {
  type = string
}
