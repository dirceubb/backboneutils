#!/bin/bash

# Agregar un dominio en nginx y letsencrypt a una instancia existente de odoo
# Este Script se ejecuta solamente si se ejecutó previamente el odoo14nginxdeploy.sh

# 1.- Crear Variables necesarias para el script
# Solicitar nombre de dominio al administrador
echo -n "FQDN (sin www): ";
read dominio;
# Solicitar correo electrónico al administrador. Este correo es importante ya que ahí se enviaran alertas sobre el estado del certificado en la nube de letsencrypt
echo -n "Correo electrónico: ";
read correo;

# 2.- Crear Server Block
# Crear Server Block para el dominio
sudo cat <<EOT > /etc/nginx/sites-available/$dominio.conf
server {
  listen 80;
  server_name $dominio;

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
sudo certbot certonly --agree-tos --noninteractive --email $correo  --webroot -w /var/lib/letsencrypt/ -d $dominio
# Configurar server block para que funcione con Odoo
# Nota se utilizan muchos "\" para que el archivo contenga las cadenas que comienzan con "$" y no lo tome como variable
sudo cat << EOT > /etc/nginx/sites-enabled/$dominio.conf

# Odoo servers
upstream odoo_$dominio {
 server 127.0.0.1:8069;
}

upstream odoochat_$dominio {
 server 127.0.0.1:8072;
}

# HTTP -> HTTPS
server {
    listen 80;
    server_name $dominio;

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
        proxy_pass http://odoochat_$dominio;
    }

    # Handle / requests
    location / {
       proxy_redirect off;
       proxy_pass http://odoo_$dominio;
    }

    # Cache static files
    location ~* /web/static/ {
        proxy_cache_valid 200 90m;
        proxy_buffering on;
        expires 864000;
        proxy_pass http://odoo_$dominio;
    }

    # Gzip
    gzip_types text/css text/less text/plain text/xml application/xml application/json application/javascript;
    gzip on;
}
EOT

# Reiniciar nginx una vez más
sudo systemctl restart nginx

# Reiniciar Odoo
sudo systemctl restart odoo14
# Fin del script
echo "¡Felicidades!, has terminado de instalar Odoo 14 y se ha configurado para trabajar correctamente en modo proxy con nginx"
echo "También se creó un certificado válido de letsencrypt mediante certbot"
echo "Solo accede a https://$dominio y comienza concluye el proceso de creación de tu base de datos de Odoo"
echo "Una vez hecho esto, se recomienda desabilitar el acceso al manejador de base de datos mediante el archivo odoo14.conf"