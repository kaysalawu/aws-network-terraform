#!bin/bash

# https://github.com/int128/terraform-aws-kubernetes-irsa

mkdir -p irsa
cd irsa

ssh-keygen -t rsa -b 2048 -f sa-signer.key -m pem
ssh-keygen -e -m PKCS8 -f sa-signer.key.pub > sa-signer-pkcs8.pub

git clone https://github.com/aws/amazon-eks-pod-identity-webhook.git
rm -rf amazon-eks-pod-identity-webhook/.git

cd amazon-eks-pod-identity-webhook
go mod init github.com/aws/amazon-eks-pod-identity-webhook
go run hack/self-hosted/main.go -key ../sa-signer-pkcs8.pub | jq '.keys += [.keys[0]] | .keys[1].kid = ""' > ../keys.json
cd ..

bucket_name="g3-k8-oidc"
region="eu-west-1"

# aws s3api create-bucket \
# --bucket "$bucket_name" \
# --region "$region" \
# --create-bucket-configuration LocationConstraint="$region"

cat > ./irsa/discovery.json <<EOF
{
    "issuer": "https://${bucket_name}.s3.${region}.amazonaws.com",
    "jwks_uri": "https://${bucket_name}.s3.${region}.amazonaws.com/keys.json",
    "authorization_endpoint": "urn:kubernetes:programmatic_authorization",
    "response_types_supported": [
        "id_token"
    ],
    "subject_types_supported": [
        "public"
    ],
    "id_token_signing_alg_values_supported": [
        "RS256"
    ],
    "claims_supported": [
        "sub",
        "iss"
    ]
}
EOF
