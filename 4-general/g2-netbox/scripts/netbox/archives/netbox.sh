#!/bin/bash

dir_base=$(pwd)
dir_netbox=${NETBOX_APP_DIR}
log_netbox=$dir_netbox/log_netbox.txt
export DEBIAN_FRONTEND=noninteractive

echo "${USERNAME}:${PASSWORD}" | chpasswd
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

HOST_NAME=$(curl -s http://169.254.169.254/latest/meta-data/tags/instance/Name)
hostnamectl set-hostname $HOST_NAME
sed -i "s/127.0.0.1.*/127.0.0.1 $HOST_NAME/" /etc/hosts

echo 'PS1="\\h:\\w\\$ "' >> /etc/bash.bashrc
echo 'PS1="\\h:\\w\\$ "' >> /root/.bashrc
echo 'PS1="\\h:\\w\\$ "' >> /home/ubuntu/.bashrc

apt update
apt install -y unzip jq tcpdump dnsutils net-tools nmap apache2-utils iperf3
apt install -y awscli

install_docker(){
  apt install -y ca-certificates curl gnupg lsb-release
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  docker version
  docker compose version
}

deploy() {
  echo "git clone -b release ${NETBOX_REPO}"
  git clone -b release ${NETBOX_REPO} || true
  tee $dir_netbox/netbox-docker/docker-compose.override.yml <<EOF
services:
  netbox:
    ports:
      - 8000:8080
    environment:
      - no_proxy=localhost,
EOF
  cd "$dir_netbox/netbox-docker"
  echo "docker compose up -d"
  docker compose up -d
  cd "$dir_base"
}

start=$(date +%s)
install_docker | tee -a $log_netbox
deploy | tee -a $log_netbox
end=$(date +%s)
elapsed=$(($end-$start))
echo "Completed in $(($elapsed/60))m $(($elapsed%60))s!" | tee -a $log_netbox
