#!/bin/bash

USER="netbox"
PASSWORD="Password123"

###############################################
# PostgreSQL
###############################################

# Installation

sudo apt update
sudo apt install -y postgresql

# Checks

if ! command -v psql &> /dev/null; then
    echo "Error: psql is not installed. Please install PostgreSQL before proceeding."
    exit 1
fi

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

###############################################
# Redis
###############################################

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

################################################
# Netbox
################################################

# Install System Packages

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

# Download NetBox

sudo wget https://github.com/netbox-community/netbox/archive/refs/tags/v4.2.6.tar.gz
sudo tar -xzf v4.2.6.tar.gz -C /opt
sudo ln -s /opt/netbox-4.2.6/ /opt/netbox

sudo mkdir -p /opt/netbox/
cd /opt/netbox/

# Create the NetBox System User

sudo adduser --system --group netbox
sudo chown --recursive netbox /opt/netbox/netbox/media/
sudo chown --recursive netbox /opt/netbox/netbox/reports/
sudo chown --recursive netbox /opt/netbox/netbox/scripts/

# Configuration

cd /opt/netbox/netbox/netbox/
sudo cp configuration_example.py configuration.py
sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \['*'\]/" configuration.py
sed -i "/DATABASE = {/,/}/c\DATABASE = {\n    'ENGINE': 'django.db.backends.postgresql',\n    'NAME': 'netbox',\n    'USER': '$USER',\n    'PASSWORD': '$PASSWORD',\n    'HOST': 'localhost',\n    'PORT': '',\n    'CONN_MAX_AGE': 300,\n}" /path/to/file
SECRET_KEY=$(python3 ../generate_secret_key.py)
