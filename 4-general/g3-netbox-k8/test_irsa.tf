# This is to create the test role for s3 echoer
# Delete whwn done
resource "aws_iam_role" "s3-echoer" {
  name               = "s3-echoer"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${aws_iam_openid_connect_provider.irsa.arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${data.aws_s3_bucket.k8_oidc_bucket.bucket_domain_name}:sub": "system:serviceaccount:default:s3-echoer"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "s3-echoer" {
  role       = aws_iam_role.s3-echoer.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
