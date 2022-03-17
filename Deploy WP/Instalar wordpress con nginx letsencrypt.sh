#!/bin/bash

### Install nginx
sudo apt update
sudo apt install nginx -y

### Check status
sudo systemctl status nginx

### Installing Certbot
sudo apt update
sudo apt install certbot -y

### Generating Strong Dh (Diffie-Hellman) Group
sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

### Obtein lets encrypt certificate ###
### Map all HTTP requests for .well-known/acme-challenge to a single directory, /var/lib/letsencrypt.
sudo mkdir -p /var/lib/letsencrypt/.well-known
sudo chgrp www-data /var/lib/letsencrypt
sudo chmod g+s /var/lib/letsencrypt

### To avoid duplicating code, we’ll create two snippets and include them in all Nginx server block files.
### Fist Snippet letsencrypt.conf
sudo cat <<EOT > /etc/nginx/snippets/letsencrypt.conf
location ^~ /.well-known/acme-challenge/ {
  allow all;
  root /var/lib/letsencrypt/;
  default_type "text/plain";
  try_files $uri =404;
}
EOT

### Second snippet ssl.conf
sudo cat <<EOT > /etc/nginx/snippets/ssl.conf
ssl_dhparam /etc/ssl/certs/dhparam.pem;

ssl_session_timeout 1d;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;

ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers on;

ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 30s;

add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Frame-Options SAMEORIGIN;
add_header X-Content-Type-Options nosniff;
EOT

### Esta parte se puede usar para el primer dominio o para agregar dominio ###
### Declare Variables ###
echo -n "FQDN (sin www): ";
read dominio;
echo -n "Correo electrónico: ";
read correo;

### open the domain server block file and include the letsencrypt.conf snippet ###
sudo cat <<EOT > /etc/nginx/sites-available/$dominio.conf
server {
  listen 80;
  server_name $dominio www.$dominio;

  include snippets/letsencrypt.conf;
}
EOT

### create a symbolic link from the file to the sites-enabled directory:
sudo ln -s /etc/nginx/sites-available/$dominio.conf /etc/nginx/sites-enabled/

### Restart the Nginx service for the changes to take effect:
sudo systemctl restart nginx

### run Certbot with the webroot plugin and obtain the SSL certificate files
sudo certbot certonly --agree-tos --email $correo --webroot -w /var/lib/letsencrypt/ -d $dominio -d www.$dominio


#####################################
### Prepare Wordpress and Mariadb ###
#####################################

### Install MariaDB ###
sudo apt update
sudo apt install mariadb-server -y

### verify that the database server is running
sudo systemctl status mariadb

### Login to the MySQL shell by typing the following command and enter the password when prompted
sudo mysql
### From within the MySQL shell, run the following SQL statements to create a database named wordpress, user named wordpressuser
CREATE DATABASE wp1 CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
GRANT ALL ON wp1.* TO 'wpdbuser1'@'localhost' IDENTIFIED BY 'change-with-strong-password';
FLUSH PRIVILEGES;
EXIT;

### Instalar PHP para nginx ###
sudo apt install php-fpm php-cli php-mysql php-json php-opcache php-mbstring php-xml php-gd php-curl php-imagick php-zip -
y
### Create a directory which will hold our WordPress files:
sudo mkdir -p /var/www/$dominio

### Download the latest version of WordPress from the WordPress download page using the following wget command
wget https://wordpress.org/latest.tar.gz

### extract the WordPress archive and move the extracted files into the domain’s document root directory:
tar xf latest.tar.gz
sudo mv wordpress/* /var/www/$dominio/

### set the correct permissions so that the web server can have full access to the site’s files and directories
sudo chown -R www-data: /var/www/$dominio

### Configure the Server Block for the wordpress site
sudo cat <<EOT > /etc/nginx/sites-available/$dominio.conf
# Redirect HTTP -> HTTPS
server {
    listen 80;
    server_name $dominio www.$dominio;

    include snippets/letsencrypt.conf;
    return 301 https://$dominio$request_uri;
}

# Redirect WWW -> NON WWW
server {
    listen 443 ssl http2;
    server_name www.$dominio;
    ssl_certificate /etc/letsencrypt/live/$dominio/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$dominio/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/$dominio/chain.pem;
    include snippets/ssl.conf;

    return 301 https://$dominio$request_uri;
}



server {
    listen 443 ssl http2;
    server_name $dominio;

    root /var/www/$dominio;
    index index.php;

    # SSL parameters
    ssl_certificate /etc/letsencrypt/live/$dominio/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$dominio/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/$dominio/chain.pem;
    include snippets/ssl.conf;
    include snippets/letsencrypt.conf;

    # log files
    access_log /var/log/nginx/$dominio.access.log;
    error_log /var/log/nginx/$dominio.error.log;

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires max;
        log_not_found off;
    }

}
EOT

### Before restarting the Nginx service make a test to be sure that there are no syntax errors:
sudo nginx -t

### Restart the Nginx service for changes to take effect:
sudo systemctl restart nginx

### Auto-renewing Let’s Encrypt SSL certificate
sudo cat <<EOT >> /etc/letsencrypt/cli.ini
deploy-hook = systemctl reload nginx
EOT


# Because we are using logrotate for greater flexibility, disable the
# internal certbot logrotation.
max-log-backups = 0