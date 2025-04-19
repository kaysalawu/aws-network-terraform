#!bin/bash/

export REGION=eu-west-1
export CLUSTER_NAME=ex-fargate-profile

aws eks --region $REGION update-kubeconfig --name $CLUSTER_NAME
