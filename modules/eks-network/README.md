This module spins up the networking infrastructure required to create an eks cluster in an existing vpc.

This will create N public subnets for external load balancers managed by K8s
N private subnets for internal routing
N subnets for the controller nodes to live in
and N subnets for the worker nodes to live in with correct routing tables so they can reach the internet

N should probably be 3 for HA

It does not create a VPC for you.
It does not tag that VPC for you.
