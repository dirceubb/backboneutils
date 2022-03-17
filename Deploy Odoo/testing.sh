#!/bin/bash

# Configurar server block para que funcione con Odoo
# Nota se utilizan muchos "\" para que el archivo contenta las cadenas que comienzan con "$" y no lo tome como variable
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

# Habilitar el proxy en la configuración de odoo asi como configurar los workers y filtrar las bases de datos mediante dbfilter y list_db
# Nota: se esta usando la ruta de escape "\" para escribir el signo "$" literalmente y no tomarlo como valor de variable
sudo cat << EOT > /etc/odoo14.conf
[options]
; This is the password that allows database operations:
admin_passwd = ChangeMe
db_host = False
db_port = False
db_user = odoo14
db_password = False
addons_path = /opt/odoo14/odoo/addons,/opt/odoo14/odoo-custom-addons

proxy_mode = True

limit_memory_hard = 2147483648
limit_memory_soft = 1020054732
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200
max_cron_threads = 1
workers = 2

; Filtrar bases de datos por el comienzo de la url y quitar la lista de bases de datos
dbfilter = ^%h\$
list_db = False
EOT

# Reiniciar Odoo
sudo systemctl restart odoo14

echo "¡Felicidades!, has terminado de instalar Odoo 14 y se ha configurado para trabajar correctamente en modo proxy con nginx"
echo "También se creó un certificado válido de letsencrypt mediante certbot"
echo "Solo accede a https://$dominio y comienza concluye el proceso de creación de tu base de datos de Odoo"
echo "Una vez hecho esto, se recomienda desabilitar el acceso al manejador de base de datos mediante el archivo odoo14.conf"
