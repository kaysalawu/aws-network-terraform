
output "bucket" {
  value = aws_s3_bucket.bucket
}

output "iam_instance_profile" {
  value = aws_iam_instance_profile.ec2_instance_profile
}

output "ipam_id" {
  value = aws_vpc_ipam.this.id
}

output "ipv4_ipam_pool_id" {
  value = { for k, v in aws_vpc_ipam_pool.ipam_scope_id_ipv4 : k => v.id }
}

output "ipv6_ipam_pool_id" {
  value = { for k, v in aws_vpc_ipam_pool.ipam_scope_id_ipv6 : k => v.id }
}

output "key_pair_name" {
  value = { for k, v in aws_key_pair.this : k => v.key_name }
}

