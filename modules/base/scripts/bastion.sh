#! /bin/bash

apt update
apt install -y awscli

hostnamectl set-hostname ${HOSTNAME}
sed -i 's/127.0.0.1.*/127.0.0.1 ${HOSTNAME}/' /etc/hosts
