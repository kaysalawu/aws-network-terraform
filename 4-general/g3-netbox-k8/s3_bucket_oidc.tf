
resource "random_id" "oidc_random" {
  byte_length = 2
}

resource "aws_s3_bucket" "oidc" {
  bucket = "${local.service}-oidc-${random_id.oidc_random.hex}"
  tags = {
    Name    = "${local.service}-oidc"
    Service = local.service
    Owner   = local.owner
  }
}

resource "aws_s3_bucket_public_access_block" "oidc_access_block" {
  bucket = aws_s3_bucket.oidc.bucket

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "oidc_ownership" {
  bucket = aws_s3_bucket.oidc.bucket
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "oidc_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.oidc_ownership,
    aws_s3_bucket_public_access_block.oidc_access_block,
  ]

  bucket = aws_s3_bucket.oidc.id
  acl    = "public-read"
}

data "aws_s3_bucket" "k8_oidc_bucket" {
  bucket = aws_s3_bucket.oidc.bucket
}

resource "aws_s3_object" "oidc_discovery" {
  bucket = aws_s3_bucket.oidc.bucket
  key    = "/.well-known/openid-configuration"
  source = "./irsa/discovery.json"
  acl    = "public-read"
}

resource "aws_s3_object" "oidc_jwks" {
  bucket = aws_s3_bucket.oidc.bucket
  key    = "/keys.json"
  source = "./irsa/keys.json"
  acl    = "public-read"
}
