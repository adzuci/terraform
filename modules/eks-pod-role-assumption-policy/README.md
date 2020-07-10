This trust policy will allow a cluster to delegate the role to a pod with a service account that has an appropriate annotation.
This will only work if the EKS service account has the name and namespace specified in this trust policy.

eg:
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::AWS_ACCOUNT_ID:role/IAM_ROLE_NAME


