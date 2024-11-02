#!/bin/bash

ssh-keygen -t rsa -b 2048 -m PEM -f "$TF_VAR_private_key_path"
ssh-keygen -y -f "$TF_VAR_private_key_path" > "$TF_VAR_public_key_path"


