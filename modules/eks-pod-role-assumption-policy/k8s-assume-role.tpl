{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowEKS",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${aws_account_id}:oidc-provider/${replace(cluster_oidc_issuer_url, "https://", "")}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${replace(cluster_oidc_issuer_url, "https://", "")}:sub": "system:serviceaccount:${service_account_namespace}:${service_account_name}"
        }
      }
    },
    {
      "Sid": "AllowEC2",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
}

