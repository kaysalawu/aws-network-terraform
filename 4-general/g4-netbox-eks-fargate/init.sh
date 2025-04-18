#!bin/bash

export REGION=eu-central-1
export CLUSTER_NAME=g3-hub1-eks-fargate

aws eks --region $REGION update-kubeconfig --name $CLUSTER_NAME
