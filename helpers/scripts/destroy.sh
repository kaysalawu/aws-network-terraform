#!/bin/bash

terraform_destroy() {
  terraform init
  terraform destroy -auto-approve -lock=false
}

terraform_destroy
# rm -rf .terraform
# rm .terraform.*
# rm terraform.*
