#!/bin/bash
yum update -y
yum install -y httpd mod_ssl openssl
openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout /etc/pki/tls/private/server.key -out /etc/pki/tls/certs/server.crt -subj "/CN=localhost"
sed -i 's/Listen 80/Listen 443/' /etc/httpd/conf/httpd.conf  # Change to 443 (or add to ssl.conf)
sed -i 's/#SSLEngine on/SSLEngine on/' /etc/httpd/conf.d/ssl.conf
sed -i 's/#SSLCertificateFile/SSLCertificateFile/' /etc/httpd/conf.d/ssl.conf
sed -i 's/#SSLCertificateKeyFile/SSLCertificateKeyFile/' /etc/httpd/conf.d/ssl.conf
systemctl start httpd
systemctl enable httpd