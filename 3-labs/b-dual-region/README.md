<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_access_key"></a> [aws\_access\_key](#input\_aws\_access\_key) | account access key | `any` | n/a | yes |
| <a name="input_aws_secret_access_key"></a> [aws\_secret\_access\_key](#input\_aws\_secret\_access\_key) | account secret key | `any` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | prefix used for all resources | `string` | `"a"` | no |
| <a name="input_private_key_path"></a> [private\_key\_path](#input\_private\_key\_path) | path to private key for ec2 SSH | `any` | n/a | yes |
| <a name="input_public_key_path"></a> [public\_key\_path](#input\_public\_key\_path) | path to public key for ec2 SSH | `any` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->