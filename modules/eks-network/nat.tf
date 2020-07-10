# Nat for Private Traffic
resource "aws_eip" "nat" {
  vpc   = true
  count = length(var.availability_zones)
}

resource "aws_nat_gateway" "nat_gateways" {
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public_loadbalancer_subnets.*.id, count.index)
  count         = length(var.availability_zones)
}
