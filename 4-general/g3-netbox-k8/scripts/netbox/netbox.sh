#!/bin/bash
dir_base=$(pwd)
dir_netbox=${NETBOX_APP_DIR}
log_netbox=$dir_netbox/log_netbox.txt
deploy() {
  echo "git clone -b release ${NETBOX_REPO}"
  git clone -b release ${NETBOX_REPO} || true
  tee $dir_netbox/netbox-docker/docker-compose.override.yml <<EOF
services:
  netbox:
    ports:
      - ${NETBOX_PORT}:8080
    environment:
      - no_proxy=localhost,
EOF
  cd "$dir_netbox/netbox-docker"
  echo "docker compose up -d"
  docker compose up -d
  cd "$dir_base"
}

start=$(date +%s)
deploy | tee -a $log_netbox
end=$(date +%s)
elapsed=$(($end-$start))
echo "Completed in $(($elapsed/60))m $(($elapsed%60))s!" | tee -a $log_netbox
