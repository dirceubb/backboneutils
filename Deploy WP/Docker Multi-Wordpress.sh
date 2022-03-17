#!/bin/bash
## Declarar Variables ##
$dominio

mkdir multi-wp

cd multi-wp

printf "file_uploads = On\nmemory_limit = 512M\nupload_max_filesize = 512M\npost_max_size = 512M\nmax_execution_time = 600" > uploads.ini

printf "client_max_body_size 1G;" > client_max_upload_size.conf

### Declarar variables ###
echo -n "FQDN (sin www): ";
read dominio;
echo -n "Correo electrónico: ";
read correo;

### Redireccionar www a sin-www ###
cat <<EOT > $dominio
rewrite ^/(.*)$ https://$dominio/$1 permanent;
EOT

### Create an external Docker network ###
docker network create net

### Archivo dockercompose.yml
## Nota: estoy omitiendo la línea para la redirección porque no crea los certificados correctamente
## - ./www.$dominio:/etc/nginx/vhost.d/www.$dominio:ro

cat <<EOT > docker-compose.yml
version: '2.2.2'
services:
  nginx-proxy:
    image: jwilder/nginx-proxy
    container_name: nginx-proxy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - html:/usr/share/nginx/html
      - dhparam:/etc/nginx/dhparam
      - vhost:/etc/nginx/vhost.d
      - certs:/etc/nginx/certs:ro
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - ./client_max_upload_size.conf:/etc/nginx/conf.d/client_max_upload_size.conf:ro
      - ./$dominio:/etc/nginx/vhost.d/$dominio:ro
    labels:
      - "com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy"
    restart: always
    networks:
      - net

  letsencrypt:
    image: jrcs/letsencrypt-nginx-proxy-companion
    container_name: lets-encrypt-proxy-companion
    depends_on:
      - "nginx-proxy"
    volumes:
      - certs:/etc/nginx/certs:rw
      - vhost:/etc/nginx/vhost.d
      - html:/usr/share/nginx/html
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      DEFAULT_EMAIL: $correo
    restart: always
    networks:
      - net

  mysqldb0:
    image: mysql:5.7
    environment:
      MYSQL_DATABASE: db0
      MYSQL_USER: db0user
      MYSQL_PASSWORD: secret
      MYSQL_RANDOM_ROOT_PASSWORD: '1'
    volumes:
      - 'mysqldb0:/var/lib/mysql'
    restart: always
    networks:
      - mysqldb0


  wordpress0:
    image: wordpress:5.8.0-php8.0-apache
    environment:
      WORDPRESS_DB_HOST: mysqldb0
      WORDPRESS_DB_USER: db0user
      WORDPRESS_DB_PASSWORD: secret
      WORDPRESS_DB_NAME: db0
      WORDPRESS_CONFIG_EXTRA: |
        define('AUTOMATIC_UPDATER_DISABLED', true);
      VIRTUAL_HOST: $dominio
      LETSENCRYPT_HOST: $dominio
    volumes:
      - 'wordpress0:/var/www/html/wp-content'
      - './uploads.ini:/usr/local/etc/php/conf.d/uploads.ini'
    restart: always
    depends_on:
      - mysqldb0
    networks:
      - mysqldb0
      - net

volumes:
  certs:
  html:
  vhost:
  dhparam:
  mysqldb0:
  wordpress0:

networks:
  mysqldb0:
    internal: true
  net:
    external: true
EOT

### deploy the setup with the following docker-compose command from the same multi-wordpress directory ###
docker-compose up -d