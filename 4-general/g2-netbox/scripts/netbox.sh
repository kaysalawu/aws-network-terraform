#!/bin/bash

export CLOUD_ENV=aws
exec > /var/log/$CLOUD_ENV-startup.log 2>&1
export DEBIAN_FRONTEND=noninteractive

echo "${USERNAME}:${PASSWORD}" | chpasswd
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

HOST_NAME=$(curl -s http://169.254.169.254/latest/meta-data/tags/instance/Name)
hostnamectl set-hostname $HOST_NAME
sed -i "s/127.0.0.1.*/127.0.0.1 $HOST_NAME/" /etc/hosts

USER="netbox"
PASSWORD=${PASSWORD}

echo ###############################################################
echo Install System Packages
echo ###############################################################

python_version=$(python3 -V 2>&1 | awk '{print $2}')
required_python_version="3.10"
if [ "$(printf '%s\n' "$required_python_version" "$python_version" | sort -V | head -n1)" != "$required_python_version" ]; then
    echo "Installing Python 3.10 ..."
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt update
    sudo apt install -y python3.10 python3.10-venv python3.10-dev
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
    echo "Python 3.10 installed successfully."
else
    echo "Python version is $python_version. Continuing with the script..."
fi

sudo apt install -y python3-pip python3-venv python3-dev build-essential libxml2-dev libxslt1-dev libffi-dev libpq-dev libssl-dev zlib1g-dev
sudo apt remove -y --purge python3-apt
sudo apt install --reinstall python3-apt

echo ###############################################################
echo PostgreSQL
echo ###############################################################

# Installation

sudo apt update
sudo apt install -y wget gnupg2

wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list

sudo apt update
sudo apt install -y postgresql-13

# Check PostgreSQL version is 13
postgresql_version=$(psql --version | awk '{print $3}' | cut -d '.' -f1)
required_version="13"

if [ "$postgresql_version" != "$required_version" ]; then
    echo "Error: PostgreSQL version 13 is required. Installed version: $postgresql_version"
    exit 1
fi
echo "PostgreSQL version $postgresql_version is installed. Continuing with the script..."

# Database Creation

sudo -u postgres psql <<EOF
CREATE DATABASE netbox;
CREATE USER netbox WITH PASSWORD 'Password123';
ALTER DATABASE netbox OWNER TO netbox;
-- The next two commands are needed on PostgreSQL 15 and later
\connect netbox;
GRANT CREATE ON SCHEMA public TO netbox;
EOF
echo "PostgreSQL setup completed successfully."

# Verify Service Status

PGPASSWORD="$PASSWORD" psql --username $USER --host localhost --dbname netbox <<EOF
\conninfo
\q
EOF
if [ $? -eq 0 ]; then
    echo "PostgreSQL authentication test passed."
else
    echo "Error: PostgreSQL authentication test failed."
    exit 1
fi
echo "All checks and setups completed successfully."

echo ###############################################################
echo Redis
echo ###############################################################

# Install Redis

sudo apt install -y redis-server

# Verify that your installed version of Redis is at least v4.0

redis_version=$(redis-server -v | awk '{print $3}' | sed 's/v//')
required_version="4.0"
if [ "$(printf '%s\n' "$required_version" "$redis_version" | sort -V | head -n1)" != "$required_version" ]; then
    echo "Error: Redis version must be at least v$required_version. Installed version: v$redis_version"
    exit 1
fi
echo "Redis version is v$redis_version. Continuing with the script..."


# Check if redis-cli is installed
if ! command -v redis-cli &> /dev/null; then
    echo "Error: redis-cli is not installed. Please install Redis CLI before proceeding."
    exit 1
fi
echo "redis-cli is installed. Continuing with the script..."

# Verify Service Status

if ! redis-cli ping | grep -q "PONG"; then
    echo "Error: Redis service is not functional. Please check the Redis installation."
    exit 1
fi
echo "Redis service is functional. Continuing with the script..."

echo ###############################################################
echo Netbox
echo ###############################################################

# Download NetBox

sudo wget https://github.com/netbox-community/netbox/archive/refs/tags/v4.2.6.tar.gz
sudo tar -xzf v4.2.6.tar.gz -C /opt
sudo ln -s /opt/netbox-4.2.6/ /opt/netbox
sudo rm -f v4.2.6.tar.gz

# Create the NetBox System User

sudo adduser --system --group netbox
sudo chown --recursive netbox /opt/netbox/netbox/media/
sudo chown --recursive netbox /opt/netbox/netbox/reports/
sudo chown --recursive netbox /opt/netbox/netbox/scripts/

# Configuration

cd /opt/netbox/netbox/netbox/
sudo cp configuration_example.py configuration.py
sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \['*'\]/" configuration.py
sed -i "/DATABASE = {/,/}/c\DATABASE = {\n    'ENGINE': 'django.db.backends.postgresql',\n    'NAME': 'netbox',\n    'USER': '$USER',\n    'PASSWORD': '$PASSWORD',\n    'HOST': 'localhost',\n    'PORT': '',\n    'CONN_MAX_AGE': 300,\n}" configuration.py
SECRET_KEY=$(python3 ../generate_secret_key.py)
sed -i "s/SECRET_KEY = ''/SECRET_KEY = '$SECRET_KEY'/" configuration.py
sudo sh -c "echo 'boto3' >> /opt/netbox/local_requirements.txt"
sudo sh -c "echo 'sentry-sdk' >> /opt/netbox/local_requirements.txt"

# Run the Upgrade Script

sudo /opt/netbox/upgrade.sh

# Create a Super User

source /opt/netbox/venv/bin/activate
cd /opt/netbox/netbox
# python3 manage.py createsuperuser

python3 manage.py shell <<EOF
from django.contrib.auth import get_user_model
User = get_user_model()
username = "admin"
password = "Password123"
email = "admin@example.com"
if not User.objects.filter(username=username).exists():
    User.objects.create_superuser(username=username, password=password, email=email)
    print("Superuser created successfully.")
else:
    print("Superuser already exists.")
EOF

# Schedule the Housekeeping Task

sudo ln -s /opt/netbox/contrib/netbox-housekeeping.sh /etc/cron.daily/netbox-housekeeping

# Test the Application

cat <<EOF | sudo tee /etc/systemd/system/netbox.service
[Unit]
Description=NetBox Development Server
After=network.target

[Service]
User=netbox
Group=netbox
WorkingDirectory=/opt/netbox/netbox
Environment="PATH=/opt/netbox/venv/bin"
ExecStart=/opt/netbox/venv/bin/python3 manage.py runserver 0.0.0.0:8000 --insecure
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable netbox.service
sudo systemctl start netbox.service
sudo systemctl status netbox.service
