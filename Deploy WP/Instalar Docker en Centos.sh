## Instalar Docker en Centos ##

# Update Centos #

sudo yum check-update
sudo yum update

# Uninstall Old Versions #

sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

# Set up the repository #
sudo yum install -y yum-utils
sudo yum-config-manager \
   --add-repo \
   https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker Engine #
sudo yum install docker-ce docker-ce-cli containerd.io

# Start Docker #
sudo systemctl start docker
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

# Execute docker without sudo #
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker

# Test Installation #
docker run hello-world


## Docker Compose ##

sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# If the command docker-compose fails after installation, check your path. You can also create a symbolic link to /usr/bin or any other directory in your path. #

sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
