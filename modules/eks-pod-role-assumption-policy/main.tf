### REQUIRED VARS ###
variable "aws_account_id" {
  type = string
}
variable "cluster_oidc_issuer_url" {
  type = string
}
variable "service_account_namespace" {
  type = string
}
variable "service_account_name" {
  type = string
}

data "template_file" "assume_role_policy" {
  template = "${file("${path.module}/k8s-assume-role.tpl")}"

  vars = {
    aws_account_id = var.aws_account_id
    cluster_oidc_issuer_url = var.cluster_oidc_issuer_url
    service_account_namespace = var.service_account_namespace
    service_account_name = var.service_account_name
  }
}

output "assume_role_policy" {
  value = data.template_file.assume_role_policy.rendered
}
