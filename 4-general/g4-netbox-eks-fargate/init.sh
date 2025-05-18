#!bin/bash/

export REGION=eu-west-1

echo "Please select an EKS cluster:"
aws eks list-clusters --region "$REGION" --query "clusters" --output json | jq -r '.[]' | nl
read -p "Enter the number of the cluster you wish to use: " cluster_number
CLUSTER_NAME=$(aws eks list-clusters --region "$REGION" --query "clusters" --output json | jq -r ".[$((cluster_number-1))]")
echo "You selected cluster: $CLUSTER_NAME"

# aws eks describe-cluster --name g4-hub1-netbox --region $REGION
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION
CLUSTER_ENDPOINT=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query "cluster.endpoint" --output text)
CLUSTER_ROLE=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query "cluster.roleArn" --output text)
echo "CLUSTER_ENDPOINT=$CLUSTER_ENDPOINT"
echo "CLUSTER_ROLE=$CLUSTER_ROLE"

aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION --role-arn $CLUSTER_ROLE --profile default
