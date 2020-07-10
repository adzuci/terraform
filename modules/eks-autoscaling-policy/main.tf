module "eks_autoscaler_assume_role_policy" {
  source      = "../eks-pod-role-assumption-policy"
  cluster_oidc_issuer_url = var.cluster_oidc_issuer_url
  aws_account_id = var.aws_account_id
  service_account_namespace = var.service_account_namespace
  service_account_name = var.service_account_name
}

resource "aws_iam_role" "eks_autoscaler" {
  name = "${var.cluster_name}-autoscaler"
  assume_role_policy = module.eks_autoscaler_assume_role_policy.assume_role_policy
}

resource "aws_iam_role_policy" "eks_autoscaler" {
  name   = "${var.cluster_name}-autoscaler"
  role   = aws_iam_role.eks_autoscaler.id
  policy = data.template_file.autoscaler_iam_policy.rendered
}

data "template_file" "autoscaler_iam_policy" {
  template = file("${path.module}/autoscaling-policy.tpl")
  vars = {}
}

output "rendered" {
  value = data.template_file.autoscaler_iam_policy.rendered
}

output "autoscaler_role_arn" {
  value = aws_iam_role.eks_autoscaler.arn
}

output "autoscaler_role_id" {
  value = aws_iam_role.eks_autoscaler.id
}
