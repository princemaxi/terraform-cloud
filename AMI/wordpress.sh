#!/bin/bash
set -e

# Update OS
sudo yum update -y

# Enable repos for PHP
sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo yum install -y dnf-utils http://rpms.remirepo.net/enterprise/remi-release-8.rpm
sudo yum module reset php -y
sudo yum module enable php:remi-7.4 -y

# Install Apache + PHP + MySQL client
sudo yum install -y httpd php php-mysqlnd php-fpm php-cli mariadb105-client wget

# Enable Apache at boot
sudo systemctl enable httpd
sudo systemctl start httpd

# SELinux config
sudo setsebool -P httpd_can_network_connect=1
sudo setsebool -P httpd_can_network_connect_db=1
sudo setsebool -P httpd_execmem=1
sudo setsebool -P httpd_use_nfs=1

# Optional: self-signed certificate
sudo yum install -y mod_ssl
sudo mkdir -p /etc/pki/tls/private
sudo chmod 700 /etc/pki/tls/private
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/pki/tls/private/WORDPRESS.key \
  -out /etc/pki/tls/certs/WORDPRESS.crt \
  -subj "/C=UK/ST=London/L=London/O=steghub.com/OU=wordpress/CN=$(curl -s http://169.254.169.254/latest/meta-data/local-hostname)"
sudo sed -i 's/localhost.crt/WORDPRESS.crt/g' /etc/httpd/conf.d/ssl.conf
sudo sed -i 's/localhost.key/WORDPRESS.key/g' /etc/httpd/conf.d/ssl.conf

# Download WordPress
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz -C /var/www/html --strip-components=1

# Set ownership and permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Restart Apache
systemctl restart httpd
