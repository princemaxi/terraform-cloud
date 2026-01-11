#!/bin/bash
set -e

sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo yum install -y dnf-utils http://rpms.remirepo.net/enterprise/remi-release-8.rpm

sudo yum install -y \
  nginx \
  mysql \
  wget \
  vim \
  telnet \
  htop \
  git \
  python3 \
  net-tools

systemctl enable chronyd
systemctl start chronyd

# SELinux settings
setsebool -P httpd_can_network_connect=1
setsebool -P httpd_can_network_connect_db=1
setsebool -P httpd_execmem=1
setsebool -P httpd_use_nfs=1

# SSL directories
mkdir -p /etc/ssl/private
chmod 700 /etc/ssl/private

# Self-signed cert
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout /etc/ssl/private/ACS.key \
  -out /etc/ssl/certs/ACS.crt \
  -subj "/C=UK/ST=London/L=London/O=steghub.com/OU=devops/CN=$(curl -s http://169.254.169.254/latest/meta-data/local-hostname)"

# DH params
openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

systemctl enable nginx
