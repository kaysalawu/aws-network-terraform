data "aws_iam_policy_document" "allows_eks_pods_to_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      identifiers = [var.oidc_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.allows_eks_pods_to_assume_role.json
}

resource "aws_iam_role_policy" "this" {
  name   = "pi-k8-pod"
  role   = aws_iam_role.this.name
  policy = var.policy_document_json
}