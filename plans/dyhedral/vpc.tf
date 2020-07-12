variable "vpc_name" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "aws_account_id" {
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

variable "public_cidrs" {
  type        = string
  description = "subnet cidrs for public loadbalancers"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}

module "vpc" {
  source               = "../../modules/vpc"
  vpc_name             = var.vpc_name
  environment          = var.environment
  deployment           = var.deployment
  vpc_cidr_block       = var.vpc_cidr_block
  azs                  = var.azs
  public_cidrs         = var.public_cidrs
}