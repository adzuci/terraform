variable "vpc_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "deployment" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

# A comma separate list of AZs
# this VPC has traffic in.
variable "azs" {
  type = string
}