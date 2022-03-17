### Install docker compose latest stable version ###
### Verify latest version on this link: https://github.com/docker/compose/releases ###

### Use curl to download docker compose ###
sudo curl -L "sudo curl -L "https://github.com/docker/compose/releases/download/v2.2.2/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose" -o /usr/local/bin/docker-compose

### Add excutable permissions ###
sudo chmod +x /usr/local/bin/docker-compose

### Verificar la instalación de Docker Compose ###
docker-compose --version