  
module "vpc" {
  source               = "../../modules/vpc"
  vpc_name             = var.vpc_name
  environment          = var.environment
  deployment           = var.deployment
  vpc_cidr_block       = var.vpc_cidr_block
  azs                  = var.azs
  public_cidrs         = var.public_cidrs
  private_cidrs        = var.private_cidrs
  aws_vpn_gateway_name = "DYHEDRAL-${upper(var.vpc_name)}"
}