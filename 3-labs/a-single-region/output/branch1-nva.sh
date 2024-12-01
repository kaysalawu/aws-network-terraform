#!/bin/bash

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

sudo rm /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

apt update
apt install -y unzip jq tcpdump dnsutils net-tools nmap
apt install -y awscli

#########################################################
# ip forwarding
#########################################################

# Enable IPv4 forwarding
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.eth0.disable_xfrm=1
sysctl -w net.ipv4.conf.eth0.disable_policy=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# Enable IPv6 forwarding
sysctl -w net.ipv6.conf.all.forwarding=1
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf

sysctl -p

Disable ICMP redirects
sysctl -w net.ipv4.conf.all.send_redirects=0
sysctl -w net.ipv4.conf.all.accept_redirects=0
sysctl -w net.ipv4.conf.eth0.send_redirects=0
sysctl -w net.ipv4.conf.eth0.accept_redirects=0
echo "net.ipv4.conf.all.send_redirects=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_redirects=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.eth0.send_redirects=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.eth0.accept_redirects=0" >> /etc/sysctl.conf
sysctl -p

#########################################################
# route table for eth1 (trust interface)
#########################################################

ETH1_SUBNET=$(ip -o -f inet addr show eth1 | awk '{print $4}')
ETH1_DGW=$(echo $ETH1_SUBNET | awk -F. '{print $1"."$2"."$3".1"}')
ETH1_MASK=$(echo $ETH1_SUBNET | cut -d'/' -f2)

# eth1 routing
echo "2 rt1" | tee -a /etc/iproute2/rt_tables

# ip rules
#-----------------------------------------------------
# ip rules tell the kernel which routing table to use.
# all traffic from/to eth1 subnet should use rt1 for lookup;
# an example is traffic to/from eth1 floating IP (load balcner VIP)
# the subnet mask expands the default GW IP to the entire subnet
ip rule add from $ETH1_DGW/$ETH1_MASK table rt1
ip rule add to $ETH1_DGW/$ETH1_MASK table rt1

# the aws static routes will direct all vnet inbound traffic to eth1 (trust)
# if destination is internal (RFC1918 and RFC6598), ip rule directs kernel to use rt1 for lookup; and then use the ip routes in rt1
# if destination is internet (not RFC1918 and RFC6598), use the main routing table for lookup and exit via eth0 default gateway
# ip rule add to 10.0.0.0/8 table rt1
# ip rule add to 172.16.0.0/12 table rt1
# ip rule add to 192.168.0.0/16 table rt1
# ip rule add to 100.64.0.0/10 table rt1

# ip routes
#--------------------------------------------------
# kernel is directed to rt1 for RFC1918 and RFC6598 destinations
# the following default route is used for traffic forwarding via eth1
# ip route add 10.0.0.0/8 via $ETH1_DGW dev eth1 table rt1
# ip route add 172.16.0.0/12 via $ETH1_DGW dev eth1 table rt1
# ip route add 192.168.0.0/16 via $ETH1_DGW dev eth1 table rt1
# ip route add 100.64.0.0/10 via $ETH1_DGW dev eth1 table rt1

# for traffic originating from aws platform to eth1 ...
# rule "ip rule add to $ETH1_DGW/$ETH1_MASK table rt1" is used
# this rule directs that rt1 should be used for lookup
# the return traffic will use the following rt1 routes
ip route add 168.63.129.16/32 via $ETH1_DGW dev eth1 table rt1
# ip route add 169.254.169.254/32 via $ETH1_DGW dev eth1 table rt1

# alternatively, all the static routes can be replaced by a single default route
# ip route add default via $ETH1_DGW dev eth1 table rt1

#########################################################
# iptables
#########################################################

echo iptables-persistent iptables-persistent/autosave_v4 boolean false | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean false | debconf-set-selections
apt-get -y install iptables-persistent

# Permit flows on all chains (for testing only and not for production)
iptables -F
iptables -t nat -F
iptables -P FORWARD ACCEPT
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT

# Iptables rules
iptables -t nat -A POSTROUTING -d 10.0.0.0/8 -j ACCEPT
iptables -t nat -A POSTROUTING -d 172.16.0.0/12 -j ACCEPT
iptables -t nat -A POSTROUTING -d 192.168.0.0/16 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Save to IPTables file for persistence on reboot
iptables-save > /etc/iptables/rules.v4

#########################################################
# packages
#########################################################

apt-get update
apt-get install -y strongswan frr

##  run the updates and ensure the packages are up to date and there is no new version available for the packages
#apt-get -y update --fix-missing
apt-get -y install tcpdump dnsutils traceroute tcptraceroute net-tools

sed -i 's/bgpd=no/bgpd=yes/' /etc/frr/daemons
systemctl restart frr

#########################################################
# strongswan config
#########################################################

tee /etc/ipsec.conf <<'EOF'
config setup
    charondebug="ike 2, knl 2, cfg 2, net 2, esp 2, dmn 2,  mgr 2"

conn %default
    type=tunnel
    ikelifetime=60m
    keylife=20m
    rekeymargin=3m
    keyingtries=1
    authby=secret
    keyexchange=ikev2
    installpolicy=yes
    compress=no
    mobike=no
    #left=%defaultroute
    leftsubnet=0.0.0.0/0
    rightsubnet=0.0.0.0/0
    ike=aes256-sha1-modp1024!
    esp=aes256-sha1!

conn tun1
    left=10.10.2.9
    leftid=52.214.47.174
    right=18.200.32.120
    rightid=18.200.32.120
    auto=start
    mark=100
    leftupdown="/etc/ipsec.d/ipsec-vti.sh"
conn tun2
    left=10.10.2.9
    leftid=52.214.47.174
    right=52.209.2.198
    rightid=52.209.2.198
    auto=start
    mark=101
    leftupdown="/etc/ipsec.d/ipsec-vti.sh"

# https://gist.github.com/heri16/2f59d22d1d5980796bfb

EOF

tee /etc/ipsec.secrets <<'EOF'
10.10.2.9 18.200.32.120 : PSK "changeme"
10.10.2.9 52.209.2.198 : PSK "changeme"

EOF

tee /etc/ipsec.d/ipsec-vti.sh <<'EOF'
#!/bin/bash

LOG_FILE="/var/log/ipsec-vti.log"

IP=$(which ip)
IPTABLES=$(which iptables)

PLUTO_MARK_OUT_ARR=(${PLUTO_MARK_OUT//// })
PLUTO_MARK_IN_ARR=(${PLUTO_MARK_IN//// })

case "$PLUTO_CONNECTION" in
  tun1)
    VTI_INTERFACE=tun1
    VTI_LOCALADDR=169.254.76.74
    VTI_REMOTEADDR=169.254.76.73
    ;;
  tun2)
    VTI_INTERFACE=tun2
    VTI_LOCALADDR=169.254.209.190
    VTI_REMOTEADDR=169.254.209.189
    ;;
esac

echo "$(date): Trigger - CONN=${PLUTO_CONNECTION}, VERB=${PLUTO_VERB}, ME=${PLUTO_ME}, PEER=${PLUTO_PEER}], PEER_CLIENT=${PLUTO_PEER_CLIENT}, MARK_OUT=${PLUTO_MARK_OUT_ARR}, MARK_IN=${PLUTO_MARK_IN_ARR}" >> $LOG_FILE

case "$PLUTO_VERB" in
  up-client)
    $IP link add ${VTI_INTERFACE} type vti local ${PLUTO_ME} remote ${PLUTO_PEER} okey ${PLUTO_MARK_OUT_ARR[0]} ikey ${PLUTO_MARK_IN_ARR[0]}
    sysctl -w net.ipv4.conf.${VTI_INTERFACE}.disable_policy=1
    sysctl -w net.ipv4.conf.${VTI_INTERFACE}.rp_filter=2 || sysctl -w net.ipv4.conf.${VTI_INTERFACE}.rp_filter=0
    $IP addr add ${VTI_LOCALADDR} remote ${VTI_REMOTEADDR} dev ${VTI_INTERFACE}
    $IP link set ${VTI_INTERFACE} up mtu 1436
    $IPTABLES -t mangle -I FORWARD -o ${VTI_INTERFACE} -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    $IPTABLES -t mangle -I INPUT -p esp -s ${PLUTO_PEER} -d ${PLUTO_ME} -j MARK --set-xmark ${PLUTO_MARK_IN}
    $IP route flush table 220
    #/etc/init.d/bgpd reload || /etc/init.d/quagga force-reload bgpd
    ;;
  down-client)
    $IP link del ${VTI_INTERFACE}
    $IPTABLES -t mangle -D FORWARD -o ${VTI_INTERFACE} -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    $IPTABLES -t mangle -D INPUT -p esp -s ${PLUTO_PEER} -d ${PLUTO_ME} -j MARK --set-xmark ${PLUTO_MARK_IN}
    ;;
esac

# github source used
# https://gist.github.com/heri16/2f59d22d1d5980796bfb

EOF
chmod a+x /etc/ipsec.d/ipsec-vti.sh

tee /usr/local/bin/ipsec-auto-restart.sh <<'EOF'
#!/bin/bash

LOG_FILE="/var/log/ipsec-auto-restart.log"

echo "$(date): Restarting IPsec service..." >> "$LOG_FILE"
systemctl restart ipsec
echo "$(date): IPsec service restarted." >> "$LOG_FILE"

EOF
chmod a+x /usr/local/bin/ipsec-auto-restart.sh

touch /var/log/ipsec-vti.log
systemctl enable ipsec
systemctl restart ipsec

#########################################################
# frr  config
#########################################################

tee /etc/frr/frr.conf <<'EOF'
!
!-----------------------------------------
! Global
!-----------------------------------------
frr version 7.2
frr defaults traditional
hostname $(hostname)
log syslog informational
service integrated-vtysh-config
!
!-----------------------------------------
! Prefix Lists
!-----------------------------------------
ip prefix-list BLOCK_AWS_PREFIXES deny 1.2.3.4/32
ip prefix-list BLOCK_AWS_PREFIXES permit 0.0.0.0/0 le 32
!
!-----------------------------------------
! Interface
!-----------------------------------------
interface lo
  ip address 192.168.10.10/32
!
!-----------------------------------------
! Static Routes
!-----------------------------------------
ip route 0.0.0.0/0 10.10.2.1
ip route 169.254.76.74/32 tun1
ip route 169.254.209.190/32 tun2
ip route 10.10.0.0/24 10.10.2.1
!
!-----------------------------------------
! Route Maps
!-----------------------------------------
  route-map AWS permit 110
  match ip address prefix-list all
!
!-----------------------------------------
! BGP
!-----------------------------------------
router bgp 65001
bgp router-id 192.168.10.10
neighbor 169.254.76.73 remote-as 65011
neighbor 169.254.209.189 remote-as 65011
!
address-family ipv4 unicast
  network 10.10.0.0/24
  neighbor 169.254.76.73 soft-reconfiguration inbound
  neighbor 169.254.209.189 soft-reconfiguration inbound
exit-address-family
!
line vty
!

EOF

systemctl enable frr
systemctl restart frr

#########################################################
# test scripts
#########################################################

# dns-info

cat <<EOF > /usr/local/bin/dns-info
echo -e "\n resolvectl ...\n"
resolvectl status
EOF
chmod a+x /usr/local/bin/dns-info

# ipsec debug

cat <<EOF > /usr/local/bin/ipsec-debug
echo -e "\n ============ ipsec statusall ============ \n"
ipsec statusall
echo -e "\n ============ ipsec status ============ \n"
ipsec status
echo -e "\n ============ ipsec-vti.log ============ \n"
cat /var/log/ipsec-vti.log
echo -e "\n ============ link vti ============ \n"
ip link show type vti
echo
EOF
chmod a+x /usr/local/bin/ipsec-debug

# crontabs
#-----------------------------------

cat <<EOF > /etc/cron.d/ipsec-auto-restart
*/15 * * * * /bin/bash /usr/local/bin/ipsec-auto-restart.sh 2>&1 > /dev/null
EOF

crontab /etc/cron.d/ipsec-auto-restart
