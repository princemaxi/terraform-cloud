#!/bin/bash
set -e

# Update OS
sudo yum update -y

# Enable repositories
sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo yum install -y dnf-utils http://rpms.remirepo.net/enterprise/remi-release-8.rpm

# Install Apache + PHP
sudo yum module reset php -y
sudo yum module enable php:remi-7.4 -y
sudo yum install -y httpd php

# Enable Apache at boot
sudo systemctl enable httpd
sudo systemctl start httpd

# Add basic homepage
echo "Tooling Website" > /var/www/html/index.html

# SELinux config for HTTP
sudo setsebool -P httpd_can_network_connect=1
sudo setsebool -P httpd_can_network_connect_db=1
sudo setsebool -P httpd_execmem=1
sudo setsebool -P httpd_use_nfs=1

# Optional: self-signed certificate
yum install -y mod_ssl
mkdir -p /etc/pki/tls/private
chmod 700 /etc/pki/tls/private
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/pki/tls/private/TOOLING.key \
  -out /etc/pki/tls/certs/TOOLING.crt \
  -subj "/C=UK/ST=London/L=London/O=steghub.com/OU=tooling/CN=$(curl -s http://169.254.169.254/latest/meta-data/local-hostname)"
sed -i 's/localhost.crt/TOOLING.crt/g' /etc/httpd/conf.d/ssl.conf
sed -i 's/localhost.key/TOOLING.key/g' /etc/httpd/conf.d/ssl.conf
