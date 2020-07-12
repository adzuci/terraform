###############################################################################
# Kubernetes creates public load balancers in these subnets
# any NATs should also reside here.
###############################################################################

# A comma seperated list of
# public_subnet_cidrs
variable "public_loadbalancer_subnet_cidrs" {
  type = list(string)
}

# Public Network ACLs
resource "aws_network_acl" "public" {
  vpc_id     = var.vpc_id
  subnet_ids = aws_subnet.public_loadbalancer_subnets.*.id

  tags = {
    Name        = "${var.cluster_name}-public-acl"
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
# The kubernetes tags are required for kubernetes to know which subnets it can use, and which subnet
# to put internal elbs in, read more here:
# https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html#vpc-subnet-tagging
resource "aws_subnet" "public_loadbalancer_subnets" {
  vpc_id                  = var.vpc_id
  cidr_block              = element(var.public_loadbalancer_subnet_cidrs, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  count = length(var.availability_zones)

  # A mapping is used so we can interpolate in the key of the tag
  tags = {
    "Name"                                      = "${var.cluster_name}-public-subnet-${element(var.availability_zones, count.index)}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"           = 1
  }
}

resource "aws_route_table_association" "public_loadbalancer_route_table_association" {
  subnet_id      = element(aws_subnet.public_loadbalancer_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.public_load_balancer_subnet_routing_tables, count.index).id
  count          = length(var.availability_zones)
}

resource "aws_route_table" "public_load_balancer_subnet_routing_tables" {
  vpc_id           = var.vpc_id

  tags = {
    Name        = "${var.cluster_name}-public-route-table"
  }
  count                  = length(var.availability_zones)
}

resource "aws_route" "route_via_internet_gateway" {
  route_table_id         = element(aws_route_table.public_load_balancer_subnet_routing_tables, count.index).id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.internet_gateway_id
  count                  = length(var.availability_zones)
}


output "public_load_balancer_subnet_ids" {
  value = aws_subnet.public_loadbalancer_subnets.*.id
}

output "public_load_balancer_subnet_network_acl_id" {
  value = aws_network_acl.public.id
}

output "public_load_balancer_subnet_routing_table_ids" {
  value = aws_route_table.public_load_balancer_subnet_routing_tables.*.id
}
