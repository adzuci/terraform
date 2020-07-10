###############################################################################
# Kubernetes creates internal ELBs in these subnets
###############################################################################

# A comma seperated list of
# internal_subnet_cidrs
variable "internal_load_balancer_subnet_cidrs" {
  type = list(string)
}

# Private Network ACLs
resource "aws_network_acl" "internal" {
  vpc_id     = var.vpc_id
  subnet_ids = aws_subnet.internal.*.id

  tags = {
    Name        = "${var.cluster_name}-internal-acl"
  }
}

# The NTP acls are redundant with the ACL rules that open up the
# ACLs fully.  However since we've had some issues with NTP in the
# past, leaving them explicit makes more sense so we don't
# accidentally turn them off when trying to make other types
# of restrictions.
resource "aws_network_acl_rule" "ntp_internal_acl_rule" {
  network_acl_id = aws_network_acl.internal.id
  rule_number    = "100"
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = "123"
  to_port        = "123"
}

resource "aws_network_acl_rule" "outbound_ntp_internal_acl_rule" {
  network_acl_id = aws_network_acl.internal.id
  egress         = true
  rule_number    = "100"
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = "123"
  to_port        = "123"
}

resource "aws_network_acl_rule" "internal_ingress_rule" {
  network_acl_id = aws_network_acl.internal.id
  egress         = false
  rule_number    = "110"
  protocol       = "all"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "internal_egress_rule" {
  network_acl_id = aws_network_acl.internal.id
  egress         = true
  rule_number    = "110"
  protocol       = "all"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

# Private Subnet
# The kubernetes tags are required for kubernetes to know which subnets it can use, and which subnet
# to put internal elbs in, read more here:
# https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html#vpc-subnet-tagging
resource "aws_subnet" "internal" {
  vpc_id                  = var.vpc_id
  cidr_block              = element(var.internal_load_balancer_subnet_cidrs, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false

  count = length(var.availability_zones)

  # A mapping is used so we can interpolate in the key of the tag
  tags = {
    "Name"                                      = "${var.cluster_name}-internal-subnet-${element(var.availability_zones, count.index)}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = 1
  }
}

resource "aws_route_table_association" "internal_route_association" {
  subnet_id      = element(aws_subnet.internal.*.id, count.index)
  route_table_id = element(aws_route_table.internal_route_tables.*.id, count.index)
  count          = length(var.availability_zones)
}

resource "aws_route" "routes_via_nat_gateway" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = element(aws_route_table.internal_route_tables.*.id, count.index)
  nat_gateway_id         = element(aws_nat_gateway.nat_gateways.*.id, count.index)
  count                  = length(var.availability_zones)
}

resource "aws_route_table" "internal_route_tables" {
  vpc_id           = var.vpc_id
  count            = length(var.availability_zones)
  propagating_vgws = var.vpn_gateway_ids

  tags = {
    Name        = "${var.cluster_name}-internal-route-table-${element(var.availability_zones, count.index)}"
  }
}

output "internal_load_balancer_subnet_ids" {
  value = aws_subnet.internal.*.id
}

output "internal_load_balancer_subnet_network_acl_id" {
  value = aws_network_acl.internal.id
}

output "internal_route_table_ids" {
  value = aws_route_table.internal_route_tables.*.id
}
