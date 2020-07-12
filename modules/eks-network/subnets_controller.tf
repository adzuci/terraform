###############################################################################
# These subnets are where the K8s control plane nodes should reside.
###############################################################################

# A comma seperated list of
# controller_subnet_cidrs
variable "controller_cidrs" {
  type = list(string)
}

# Private Network ACLs
resource "aws_network_acl" "controller" {
  vpc_id     = var.vpc_id
  subnet_ids = aws_subnet.controller.*.id

  tags = {
    Name        = "${var.cluster_name}-controller-acl"
  }
}

# The NTP acls are redundant with the ACL rules that open up the
# ACLs fully.  However since we've had some issues with NTP in the
# past, leaving them explicit makes more sense so we don't
# accidentally turn them off when trying to make other types
# of restrictions.
resource "aws_network_acl_rule" "ntp_controller_acl_rule" {
  network_acl_id = aws_network_acl.controller.id
  rule_number    = "100"
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = "123"
  to_port        = "123"
}

resource "aws_network_acl_rule" "outbound_ntp_controller_acl_rule" {
  network_acl_id = aws_network_acl.controller.id
  egress         = true
  rule_number    = "100"
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = "123"
  to_port        = "123"
}

resource "aws_network_acl_rule" "controller_ingress_rule" {
  network_acl_id = aws_network_acl.controller.id
  egress         = false
  rule_number    = "110"
  protocol       = "all"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "controller_egress_rule" {
  network_acl_id = aws_network_acl.controller.id
  egress         = true
  rule_number    = "110"
  protocol       = "all"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

# Controller Subnets
# The kubernetes tags are required for kubernetes to know which subnets it can use, and which subnet
# to put internal elbs in, read more here:
# https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html#vpc-subnet-tagging
resource "aws_subnet" "controller" {
  vpc_id                  = var.vpc_id
  cidr_block              = element(var.controller_cidrs, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false

  count = length(var.availability_zones)

  # A mapping is used so we can interpolate in the key of the tag
  tags = {
    "Name"                                      = "${var.cluster_name}-controller-subnet-${element(var.availability_zones, count.index)}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table_association" "controller_route_association" {
  subnet_id      = element(aws_subnet.controller.*.id, count.index)
  route_table_id = element(aws_route_table.controller_route_tables.*.id, count.index)
  count          = length(var.availability_zones)
}

resource "aws_route_table" "controller_route_tables" {
  vpc_id           = var.vpc_id
  count            = length(var.availability_zones)

  tags = {
    Name        = "${var.cluster_name}-controller-route-table-${element(var.availability_zones, count.index)}"
  }
}

resource "aws_route" "controller_route_via_nat_gateway" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = element(aws_route_table.controller_route_tables.*.id, count.index)
  nat_gateway_id         = element(aws_nat_gateway.nat_gateways.*.id, count.index)
  count                  = length(var.availability_zones)
}

output "controller_subnet_ids" {
  value = aws_subnet.controller.*.id
}

output "controller_network_acl_id" {
  value = aws_network_acl.controller.id
}

output "controller_route_table_ids" {
  value = aws_route_table.controller_route_tables.*.id
}
