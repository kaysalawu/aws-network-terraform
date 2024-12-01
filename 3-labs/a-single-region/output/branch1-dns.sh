#! /bin/bash

# !!! DO NOT USE THIS MACHINE FOR PRODUCTION !!!

export CLOUD_ENV=aws
exec > /var/log/$CLOUD_ENV-startup.log 2>&1
export DEBIAN_FRONTEND=noninteractive

echo "ubuntu:Password123" | chpasswd
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

HOST_NAME=$(curl -s http://169.254.169.254/latest/meta-data/tags/instance/Name)
hostnamectl set-hostname $HOST_NAME
sed -i "s/127.0.0.1.*/127.0.0.1 $HOST_NAME/" /etc/hosts

echo 'PS1="\\h:\\w\\$ "' >> /etc/bash.bashrc
echo 'PS1="\\h:\\w\\$ "' >> /root/.bashrc
echo 'PS1="\\h:\\w\\$ "' >> /home/ubuntu/.bashrc

# disable systemd-resolved as it conflicts with dnsmasq on port 53
systemctl stop systemd-resolved
systemctl disable systemd-resolved
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "$(hostname -I | cut -d' ' -f1) $(hostname)" >> /etc/hosts

apt update
apt install -y tcpdump dnsutils net-tools
apt install -y unbound

touch /etc/unbound/unbound.log
chmod a+x /etc/unbound/unbound.log

cat <<EOF > /etc/unbound/unbound.conf
server:
        port: 53
        do-ip4: yes
        do-ip6: yes
        do-udp: yes
        do-tcp: yes

        interface: 0.0.0.0
        interface: ::0

        access-control: 0.0.0.0 deny
        access-control: ::0 deny
        access-control: 10.0.0.0/8 allow
        access-control: 127.0.0.0/8 allow
        access-control: 35.199.192.0/19 allow
        access-control: fd00::/8 allow

        # local data records
        local-data: "branch1vm.cloudtuple.org 300 IN A 10.10.0.5"
        local-data: "branch2vm.cloudtuple.org 300 IN A 10.20.0.5"
        local-data: "branch3vm.cloudtuple.org 300 IN A 10.30.0.5"
        local-data: "branch1vm.cloudtuple.org 300 IN AAAA 2000:abc:10::5"
        local-data: "branch2vm.cloudtuple.org 300 IN AAAA 2000:abc:20::5"
        local-data: "branch3vm.cloudtuple.org 300 IN AAAA 2000:abc:30::5"

        # hosts redirected to PrivateLink


forward-zone:
        name: "eu.c.cloudtuple.org."
        forward-addr: 10.11.10.4

forward-zone:
        name: "us.c.cloudtuple.org."
        forward-addr: 10.22.10.4

forward-zone:
        name: "."
        forward-addr: 169.254.169.253
EOF

systemctl enable unbound
systemctl restart unbound
apt install resolvconf
resolvconf -u
