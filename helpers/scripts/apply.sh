#!/bin/bash

terraform_plan() {
  terraform fmt
  terraform init
  terraform plan -out=tfplan -lock=false
}

terraform_apply() {
  terraform apply -auto-approve "tfplan"
  rm -f tfplan
}

terraform_plan
terraform_apply
