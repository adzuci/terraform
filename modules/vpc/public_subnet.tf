###############################################################################
# These are the resources related to the public subnets. The subnets serve two
# main purposes.  They are where the NAT gateways reside and they are also
# where we expect to put any ELBs that are meant to be public facing.
###############################################################################

# A comma seperated list of
# public_subnet_cidrs
variable "public_cidrs" {
  type = string
}

# Public Network ACLs
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = aws_subnet.public.*.id

  tags = {
    Name        = "${var.vpc_name}-public-acl"
    environment = var.environment
    deployment  = var.deployment
  }
}

# The NTP acls are redundant with the ACL rules that open up the
# ACLs fully.  However since we've had some issues with NTP in the
# past, leaving them explicit makes more sense so we don't
# accidentally turn them off when trying to make other types
# of restrictions.
resource "aws_network_acl_rule" "ntp_acl_rule" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = "100"
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = "123"
  to_port        = "123"
}

resource "aws_network_acl_rule" "outbound_ntp_acl_rule" {
  network_acl_id = aws_network_acl.public.id
  egress         = true
  rule_number    = "100"
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = "123"
  to_port        = "123"
}

resource "aws_network_acl_rule" "public_ingress_rule" {
  network_acl_id = aws_network_acl.public.id
  egress         = false
  rule_number    = "110"
  protocol       = "all"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "public_egress_rule" {
  network_acl_id = aws_network_acl.public.id
  egress         = true
  rule_number    = "110"
  protocol       = "all"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = element(split(",", var.public_cidrs), count.index)
  availability_zone       = element(split(",", var.azs), count.index)
  map_public_ip_on_launch = true

  count = length(split(",", var.azs))

  tags = {
    Name        = "${var.vpc_name}-public-subnet-${element(split(",", var.azs), count.index)}"
    environment = var.environment
    deployment  = var.deployment
  }
}

resource "aws_route_table_association" "public_route_association" {
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public_route_table.id
  count          = length(split(",", var.azs))
}

# Public Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id           = aws_vpc.vpc.id
  propagating_vgws = [aws_vpn_gateway.vpn_gw.id]

  tags = {
    Name        = "${var.vpc_name}-public-route-table"
    environment = var.environment
    deployment  = var.deployment
  }
}

resource "aws_route" "route_via_internet_gateway" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

# -------------------------------------------------------

output "public_subnet_ids" {
  value = join(",", aws_subnet.public.*.id)
}

output "public_route_table_id" {
  value = aws_route_table.public_route_table.id
}
