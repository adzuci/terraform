resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block

  enable_dns_hostnames = true

  tags = {
    Name        = var.vpc_name
    environment = var.environment
    deployment  = var.deployment
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "${var.vpc_name}-gateway"
    environment = var.environment
    deployment  = var.deployment
  }
}

# Make new main route table because the default is open.
# https://github.com/hashicorp/terraform/issues/748
resource "aws_route_table" "default_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "${var.vpc_name}-default-route-table"
    environment = var.environment
    deployment  = var.deployment
  }
}

resource "aws_main_route_table_association" "default_route_table_association" {
  vpc_id         = aws_vpc.vpc.id
  route_table_id = aws_route_table.default_route_table.id
}

# -------------------------------------------------------

# Items returned by this module
# -----------------------------

output "id" {
  value = aws_vpc.vpc.id
}

output "public_acl_id" {
  value = aws_network_acl.public.id
}
