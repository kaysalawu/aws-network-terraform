resource "aws_iam_openid_connect_provider" "irsa" {
  url             = "https://${data.aws_s3_bucket.k8_oidc_bucket.bucket_domain_name}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.oidc_ca_sha1]
}

data "aws_region" "current" {}

output "irsa_oidc_issuer" {
  description = "Issuer of OIDC provider for IRSA"
  value       = data.aws_s3_bucket.k8_oidc_bucket.bucket_domain_name
}
