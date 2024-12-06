#! /bin/bash

export CLOUD_ENV=aws
exec > /var/log/$CLOUD_ENV-startup.log 2>&1
export DEBIAN_FRONTEND=noninteractive

echo "${USERNAME}:${PASSWORD}" | chpasswd
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

METADATA_HOSTNAME=$(curl -s http://169.254.169.254/latest/meta-data/tags/instance/Name)
hostnamectl set-hostname $METADATA_HOSTNAME
sed -i "s/127.0.0.1.*/127.0.0.1 $HOSTNAME/" /etc/hosts

echo 'PS1="\\h:\\w\\$ "' >> /etc/bash.bashrc
echo 'PS1="\\h:\\w\\$ "' >> /root/.bashrc
echo 'PS1="\\h:\\w\\$ "' >> /home/ubuntu/.bashrc

apt update
apt install -y awscli
