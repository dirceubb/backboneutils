### Instalar Nginx Proxy Manager
#Paso 1 es instalar docker y docker-compose

## Crear proyecto y archivo docker-compse.yml
mkdir nginx-proxy-manager
cd nginx-proxy-manager
sudo nano docker-compose.yml
### configurar el archivo con el siguiente contenido

version: '3'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    environment:
      DB_MYSQL_HOST: "db"
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: "npm"
      DB_MYSQL_PASSWORD: "npm"
      DB_MYSQL_NAME: "npm"
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
  db:
    image: 'jc21/mariadb-aria:latest'
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: 'npm'
      MYSQL_DATABASE: 'npm'
      MYSQL_USER: 'npm'
      MYSQL_PASSWORD: 'npm'
    volumes:
      - ./data/mysql:/var/lib/mysql


### Bring up your stack
docker-compose up -d

## Log in to the Admin UI
http://127.0.0.1:81


## Default Admin User:

## Email:    admin@example.com
## Password: changeme