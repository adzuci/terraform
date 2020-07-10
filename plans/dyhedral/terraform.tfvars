# VPC
vpc_name                = "prod-blackwell"
vpc_id                  = "vpc-<redacted>"
environment             = "prod"
deployment              = "blackwell"
vpc_cidr_block          = "10.0.0.0/16"
public_cidrs            = "10.0.1.0/24"
aws_region              = "us-east-1"
azs                     = ["us-east-1b", "us-east-1d", "us-east-1e"]
aws_account_id          = "<redacted>"

# EKS
eks_cluster_name                = "prod-blackwell-eks"
eks_worker_cidrs                = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"]
eks_controller_cidrs            = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
eks_public_loadbalancer_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
eks_azs                         = ["us-east-1a", "us-east-1b", "us-east-1c"]
eks_internet_gateway            = "igw-1234567"