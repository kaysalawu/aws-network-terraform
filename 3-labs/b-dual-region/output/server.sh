#! /bin/bash

export CLOUD_ENV=aws
exec > /var/log/$CLOUD_ENV-startup.log 2>&1
export DEBIAN_FRONTEND=noninteractive

apt update
apt install -y python3-pip python3-dev python3-venv unzip jq tcpdump dnsutils net-tools nmap apache2-utils iperf3
apt install -y python3-flask python3-requests
apt install -y awscli
apt install -y ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
docker version
docker compose version

mkdir -p /var/flaskapp/flaskapp/{static,templates}

cat <<EOF >/var/flaskapp/flaskapp/__init__.py
import socket
from flask import Flask, request
app = Flask(__name__)

@app.route("/")
def default():
    hostname = socket.gethostname()
    address = socket.gethostbyname(hostname)
    data_dict = {}
    data_dict['Hostname'] = hostname
    data_dict['server-ipv4'] = address
    data_dict['Remote-IP'] = request.remote_addr
    data_dict['Headers'] = dict(request.headers)
    return data_dict

@app.route("/path1")
def path1():
    hostname = socket.gethostname()
    address = socket.gethostbyname(hostname)
    data_dict = {}
    data_dict['app'] = 'PATH1-APP'
    data_dict['Hostname'] = hostname
    data_dict['server-ipv4'] = address
    data_dict['Remote-IP'] = request.remote_addr
    data_dict['Headers'] = dict(request.headers)
    return data_dict

@app.route("/path2")
def path2():
    hostname = socket.gethostname()
    address = socket.gethostbyname(hostname)
    data_dict = {}
    data_dict['app'] = 'PATH2-APP'
    data_dict['Hostname'] = hostname
    data_dict['server-ipv4'] = address
    data_dict['Remote-IP'] = request.remote_addr
    data_dict['Headers'] = dict(request.headers)
    return data_dict

if __name__ == "__main__":
    app.run(host= '0.0.0.0', port=80, debug = True)
EOF

cat <<EOF >/etc/systemd/system/flaskapp.service
[Unit]
Description=Script for flaskapp service

[Service]
Type=simple
ExecStart=/usr/bin/python3 /var/flaskapp/flaskapp/__init__.py
ExecStop=/usr/bin/pkill -f /var/flaskapp/flaskapp/__init__.py
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable flaskapp.service
systemctl restart flaskapp.service


# test scripts (ipv4)
#---------------------------

# ping-ipv4
cat <<'EOF' >/usr/local/bin/ping-ipv4
echo -e "\n ping ipv4 ...\n"
EOF
chmod a+x /usr/local/bin/ping-ipv4

# ping-dns4
cat <<'EOF' >/usr/local/bin/ping-dns4
echo -e "\n ping dns ipv4 ...\n"
EOF
chmod a+x /usr/local/bin/ping-dns4

# curl-ipv4
cat <<'EOF' >/usr/local/bin/curl-ipv4
echo -e "\n curl ipv4 ...\n"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.10.0.5) - branch1 [10.10.0.5]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.11.0.5) - hub1    [10.11.0.5]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.1.0.5) - spoke1  [10.1.0.5]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.2.0.5) - spoke2  [10.2.0.5]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.30.0.5) - branch3 [10.30.0.5]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.22.0.5) - hub2    [10.22.0.5]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.4.0.5) - spoke4  [10.4.0.5]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.5.0.5) - spoke5  [10.5.0.5]"
EOF
chmod a+x /usr/local/bin/curl-ipv4

# curl-dns4
cat <<'EOF' >/usr/local/bin/curl-dns4
echo -e "\n curl dns ipv4 ...\n"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null branch1Vm.cloudtuple.org) - branch1Vm.cloudtuple.org"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null hub1Vm.eu.c.cloudtuple.org) - hub1Vm.eu.c.cloudtuple.org"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke3pls.eu.c.cloudtuple.org) - spoke3pls.eu.c.cloudtuple.org"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke1Vm.eu.c.cloudtuple.org) - spoke1Vm.eu.c.cloudtuple.org"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke2Vm.eu.c.cloudtuple.org) - spoke2Vm.eu.c.cloudtuple.org"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null branch3Vm.cloudtuple.org) - branch3Vm.cloudtuple.org"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null hub2Vm.us.c.cloudtuple.org) - hub2Vm.us.c.cloudtuple.org"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke6pls.us.c.cloudtuple.org) - spoke6pls.us.c.cloudtuple.org"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke4Vm.us.c.cloudtuple.org) - spoke4Vm.us.c.cloudtuple.org"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke5Vm.us.c.cloudtuple.org) - spoke5Vm.us.c.cloudtuple.org"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null icanhazip.com) - icanhazip.com"
EOF
chmod a+x /usr/local/bin/curl-dns4

# trace-ipv4
cat <<'EOF' >/usr/local/bin/trace-ipv4
echo -e "\n trace ipv4 ...\n"
EOF
chmod a+x /usr/local/bin/trace-ipv4

# ptr-ipv4
cat <<'EOF' >/usr/local/bin/ptr-ipv4
echo -e "\n PTR ipv4 ...\n"
EOF
chmod a+x /usr/local/bin/ptr-ipv4

# test scripts (ipv6)
#---------------------------

# ping-dns6
cat <<'EOF' >/usr/local/bin/ping-dns6
echo -e\n " ping dns ipv6 ...\n"
EOF
chmod a+x /usr/local/bin/ping-dns6

# curl-dns6
cat <<'EOF' >/usr/local/bin/curl-dns6
echo -e "\n curl dns ipv6 ...\n"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null branch1Vm.cloudtuple.org) - branch1Vm.cloudtuple.org"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null hub1Vm.eu.c.cloudtuple.org) - hub1Vm.eu.c.cloudtuple.org"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke3pls.eu.c.cloudtuple.org) - spoke3pls.eu.c.cloudtuple.org"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke1Vm.eu.c.cloudtuple.org) - spoke1Vm.eu.c.cloudtuple.org"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke2Vm.eu.c.cloudtuple.org) - spoke2Vm.eu.c.cloudtuple.org"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null branch3Vm.cloudtuple.org) - branch3Vm.cloudtuple.org"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null hub2Vm.us.c.cloudtuple.org) - hub2Vm.us.c.cloudtuple.org"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke6pls.us.c.cloudtuple.org) - spoke6pls.us.c.cloudtuple.org"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke4Vm.us.c.cloudtuple.org) - spoke4Vm.us.c.cloudtuple.org"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke5Vm.us.c.cloudtuple.org) - spoke5Vm.us.c.cloudtuple.org"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null icanhazip.com) - icanhazip.com"
EOF
chmod a+x /usr/local/bin/curl-dns6

# trace-dns6
cat <<'EOF' >/usr/local/bin/trace-dns6
echo -e "\n trace ipv6 ...\n"
EOF
chmod a+x /usr/local/bin/trace-dns6

# other scripts
#---------------------------

# dns-info
cat <<'EOF' >/usr/local/bin/dns-info
echo -e "\n resolvectl ...\n"
resolvectl status
EOF
chmod a+x /usr/local/bin/dns-info

# traffic generators (ipv4)
#---------------------------

# light-traffic generator

# heavy-traffic generator

# traffic generators (ipv6)
#---------------------------

# light-traffic generator

# systemctl services
#---------------------------

cat <<EOF > /etc/systemd/system/flaskapp.service
[Unit]
Description=Manage Docker Compose services for FastAPI
After=docker.service
Requires=docker.service

[Service]
Type=simple
Environment="HOSTNAME=$(hostname)"
ExecStart=/usr/bin/docker compose -f /var/lib/$CLOUD_ENV/fastapi/docker-compose-http-80.yml up -d && \
          /usr/bin/docker compose -f /var/lib/$CLOUD_ENV/fastapi/docker-compose-http-8080.yml up -d
ExecStop=/usr/bin/docker compose -f /var/lib/$CLOUD_ENV/fastapi/docker-compose-http-80.yml down && \
         /usr/bin/docker compose -f /var/lib/$CLOUD_ENV/fastapi/docker-compose-http-8080.yml down
Restart=always
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable flaskapp.service
systemctl restart flaskapp.service

# crontabs
#---------------------------

cat <<'EOF' >/etc/cron.d/traffic-gen
EOF

crontab /etc/cron.d/traffic-gen
