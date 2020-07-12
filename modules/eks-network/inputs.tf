# External inputs
variable "cluster_name" { type = string }
variable "availability_zones" { type = list(string) }
variable "vpc_id" { type = string }
variable "internet_gateway_id"  { type = string }
variable "peering_routes" {
  type = map(string)
  default = {}
}
