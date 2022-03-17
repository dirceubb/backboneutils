# crear virtual host
server {
  listen 80;
  server_name subdomain.example.com;

  include snippets/letsencrypt.conf;
}

# liga a sitios habilitados
sudo ln -s /etc/nginx/sites-available/subdomain.example.com.conf /etc/nginx/sites-enabled/

# crear certificado
sudo certbot certonly --agree-tos --email myemail@example.com --webroot -w /var/lib/letsencrypt/ -d subdomain.example.com

## Agregar Virtual host con redireccionamiento http a https. Para un sitio con php

# Redirect HTTP -> HTTPS
server {
    listen 80;
    server_name subdomain.example.com subdomain2.example.com;

    include snippets/letsencrypt.conf;
    return 301 https://subdomain.example.com$request_uri;
}

# Redirect WWW -> NON WWW
server {
    listen 443 ssl http2;
    server_name subdomain.example.com;
    ssl_certificate /etc/letsencrypt/live/subdomain.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/subdomain.example.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/subdomain.example.com/chain.pem;
    include snippets/ssl.conf;

    return 301 https://subdomain.example.com$request_uri;
}

server {
    listen 443 ssl http2;
    server_name subdomain.example.com;

    root /var/www/subdomain.example.com;
    index index.php;

    # SSL parameters
    ssl_certificate /etc/letsencrypt/live/subdomain.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/subdomain.example.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/subdomain.example.com/chain.pem;
    include snippets/ssl.conf;
    include snippets/letsencrypt.conf;

    # log files
    access_log /var/log/nginx/subdomain.example.com.access.log;
    error_log /var/log/nginx/subdomain.example.com.error.log;

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
