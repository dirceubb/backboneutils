#!/bin/bash

# Instalar y configurar nginx y crearle un certificado válido a al dominio que usará la bd de Odoo mediante letsencrypt.
# También configura al modo proxy del odoo y se dejan configurados los workers para trabajar en sistema operativo pequeño (1 core y 2 gb ram)

# 1.- Crear Variables necesarias para el script
# Solicitar nombre de dominio al administrador
echo -n "FQDN (sin www): ";
read dominio;
# Solicitar correo electrónico al administrador. Este correo es importante ya que ahí se enviaran alertas sobre el estado del certificado en la nube de letsencrypt
echo -n "Correo electrónico: ";
read correo;

# Instalar nginx
sudo apt update
sudo apt -y install nginx
sudo systemctl status nginx
# Instalar certbot
sudo apt -y install certbot
sudo systemctl status certbot

# 2.- Preconfigurar certbot y el serverblock de nginx para poder solicitar el certificado de letsencrypt
# Crear claves de Diffie–Hellman (DH). Se usan claves de 2048 bits
sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
# Mapear las peticiones para .well-known/acme-challenge a un solo directorio, /var/lib/letsencrypt
sudo mkdir -p /var/lib/letsencrypt/.well-known;
sudo chgrp www-data /var/lib/letsencrypt;
sudo chmod g+s /var/lib/letsencrypt;
# Crear snippets "letsencrypt.conf" y ssl.conf, que se incluirán en todos los bloques de nginx. Esto para optimizar y reutilizar código
# Nota: en esta cadena se usa el caracter de escape "\" para que escriba literalmente $uri y no lo tome como variable
sudo cat << EOT > /etc/nginx/snippets/letsencrypt.conf
location ^~ /.well-known/acme-challenge/ {
    allow all;
    root /var/lib/letsencrypt/;
    default_type "text/plain";
    try_files \$uri =404;
}
EOT
sudo cat << EOT > /etc/nginx/snippets/ssl.conf
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
# Borrar Server Block "default"
sudo rm /etc/nginx/sites-enabled/default
sudo rm /etc/nginx/sites-available/default
# Crear Server Block para el dominio y www
sudo cat <<EOT > /etc/nginx/sites-available/$dominio.conf
server {
  listen 80;
  server_name $dominio www.$dominio;

  include snippets/letsencrypt.conf;
}
EOT
# Crear liga simbólica del Server Block para habilitar el dicho bloque
sudo ln -s /etc/nginx/sites-available/$dominio.conf /etc/nginx/sites-enabled/
# Reinicar el servicio de nginx
sudo systemctl restart nginx
sudo systemctl status nginx

# 3.- Obtener certificado de letsencrypt y configurar server block para que funcione con dicho certificado
# Ejecutar el Certbot con el plugin webroot para obtener el certificado
sudo certbot certonly --agree-tos --noninteractive --email $correo  --webroot -w /var/lib/letsencrypt/ -d $dominio -d www.$dominio
# Configurar server block para que funcione con Odoo
# Nota se utilizan muchos "\" para que el archivo contenga las cadenas que comienzan con "$" y no lo tome como variable
sudo cat << EOT > /etc/nginx/sites-enabled/$dominio.conf

# Odoo servers
upstream odoo {
 server 127.0.0.1:8069;
}

upstream odoochat {
 server 127.0.0.1:8072;
}

# HTTP -> HTTPS
server {
    listen 80;
    server_name $dominio www.$dominio;

    include snippets/letsencrypt.conf;
    return 301 https://$dominio\$request_uri;
}

# WWW -> NON WWW
server {
    listen 443 ssl http2;
    server_name www.$dominio;

    ssl_certificate /etc/letsencrypt/live/$dominio/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$dominio/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/$dominio/chain.pem;
    include snippets/ssl.conf;
    include snippets/letsencrypt.conf;

    return 301 https://$dominio\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $dominio;

    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;

    # Proxy headers
    proxy_set_header X-Forwarded-Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Real-IP \$remote_addr;

    # SSL parameters
    ssl_certificate /etc/letsencrypt/live/$dominio/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$dominio/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/$dominio/chain.pem;
    include snippets/ssl.conf;
    include snippets/letsencrypt.conf;

    # log files
    access_log /var/log/nginx/odoo.access.log;
    error_log /var/log/nginx/odoo.error.log;

    # Handle longpoll requests
    location /longpolling {
        proxy_pass http://odoochat;
    }

    # Handle / requests
    location / {
       proxy_redirect off;
       proxy_pass http://odoo;
    }

    # Cache static files
    location ~* /web/static/ {
        proxy_cache_valid 200 90m;
        proxy_buffering on;
        expires 864000;
        proxy_pass http://odoo;
    }

    # Gzip
    gzip_types text/css text/less text/plain text/xml application/xml application/json application/javascript;
    gzip on;
}
EOT
# Reiniciar nginx una vez más
sudo systemctl restart nginx

# 4.- Habilitar el proxy en la configuración de odoo asi como configurar los workers
sudo cat << EOT > /etc/odoo15.conf
[options]
; This is the password that allows database operations:
admin_passwd = ChangeMe
db_host = False
db_port = False
db_user = odoo15
db_password = False
addons_path = /opt/odoo15/odoo/addons,/opt/odoo15/odoo-custom-addons

proxy_mode = True

limit_memory_hard = 2147483648
limit_memory_soft = 1020054732
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200
max_cron_threads = 1
workers = 2

; Filtrar bases de datos por el comienzo de la url y quitar la lista de bases de datos
;dbfilter = ^%h$
;list_db = False
EOT
# Reiniciar Odoo
sudo systemctl restart odoo15
# Fin del script
echo "¡Felicidades!, has terminado de instalar Odoo 15 y se ha configurado para trabajar correctamente en modo proxy con nginx"
echo "También se creó un certificado válido de letsencrypt mediante certbot"
echo "Solo accede a https://$dominio y comienza concluye el proceso de creación de tu base de datos de Odoo"
echo "Una vez hecho esto, se recomienda desabilitar el acceso al manejador de base de datos mediante el archivo odoo15.conf"
