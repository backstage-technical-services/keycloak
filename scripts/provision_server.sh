#!/usr/bin/env bash
set -eo pipefail

# Update
apt-get update && apt-get upgrade -y

# Install docker
apt install -y docker.io
systemctl enable --now docker

# Set up certbot
apt install software-properties-common
add-apt-repository universe
apt update
apt install -y certbot
#certbot certonly --standalone

# Clone repository
mkdir -p /opt/keycloak
cd /opt/keycloak
git clone https://github.com/backstage-technical-services/keycloak.git .

# Move config
mv /opt/provision/.env /opt/keycloak/.env
mv /opt/provision/.db-init.sql /opt/keycloak/.db-init.d/sql.sql

# Start
docker-compose up -d
