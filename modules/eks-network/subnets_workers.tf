###############################################################################
# Kubernetes workers that run the pods go in these subnets
###############################################################################

# A comma seperated list of
# worker_subnet_cidrs
variable "worker_subnet_cidrs" {
  type = list(string)
}

# Private Network ACLs
resource "aws_network_acl" "worker" {
  vpc_id     = var.vpc_id
  subnet_ids = aws_subnet.worker.*.id

  tags = {
    Name        = "${var.cluster_name}-worker-acl"
  }
}

# The NTP acls are redundant with the ACL rules that open up the
# ACLs fully.  However since we've had some issues with NTP in the
# past, leaving them explicit makes more sense so we don't
# accidentally turn them off when trying to make other types
# of restrictions.
resource "aws_network_acl_rule" "ntp_worker_acl_rule" {
  network_acl_id = aws_network_acl.worker.id
  rule_number    = "100"
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = "123"
  to_port        = "123"
}

resource "aws_network_acl_rule" "outbound_ntp_worker_acl_rule" {
  network_acl_id = aws_network_acl.worker.id
  egress         = true
  rule_number    = "100"
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = "123"
  to_port        = "123"
}

resource "aws_network_acl_rule" "worker_ingress_rule" {
  network_acl_id = aws_network_acl.worker.id
  egress         = false
  rule_number    = "110"
  protocol       = "all"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "worker_egress_rule" {
  network_acl_id = aws_network_acl.worker.id
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
resource "aws_subnet" "worker" {
  vpc_id                  = var.vpc_id
  cidr_block              = element(var.worker_subnet_cidrs, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false

  count = length(var.availability_zones)

  # A mapping is used so we can interpolate in the key of the tag
  tags = {
    "Name"                                      = "${var.cluster_name}-worker-subnet-${element(var.availability_zones, count.index)}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table_association" "worker_route_association" {
  subnet_id      = element(aws_subnet.worker.*.id, count.index)
  route_table_id = element(aws_route_table.worker_route_tables.*.id, count.index)
  count          = length(var.availability_zones)
}

resource "aws_route_table" "worker_route_tables" {
  vpc_id           = var.vpc_id
  count            = length(var.availability_zones)

  tags = {
    Name        = "${var.cluster_name}-worker-route-table-${element(var.availability_zones, count.index)}"
  }
}

resource "aws_route" "worker_route_via_nat_gateway" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = element(aws_route_table.worker_route_tables.*.id, count.index)
  nat_gateway_id         = element(aws_nat_gateway.nat_gateways.*.id, count.index)
  count                  = length(var.availability_zones)
}

locals {
  peering_routes_flat = flatten([
    for route_table in aws_route_table.worker_route_tables: [
      for cidr, pcx_id in var.peering_routes: {
        route_table_id = route_table.id
        cidr = cidr
        pcx_id = pcx_id
      }
    ]
  ])
}

resource "aws_route" "worker_route_via_peering_connection" {
  destination_cidr_block    = local.peering_routes_flat[count.index].cidr
  route_table_id            = local.peering_routes_flat[count.index].route_table_id
  vpc_peering_connection_id = local.peering_routes_flat[count.index].pcx_id
  count                     = length(local.peering_routes_flat)
}

output "worker_subnet_ids" {
  value = aws_subnet.worker.*.id
}

output "worker_network_acl_id" {
  value = aws_network_acl.worker.id
}

output "worker_route_table_ids" {
  value = aws_route_table.worker_route_tables.*.id
}
