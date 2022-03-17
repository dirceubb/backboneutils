### Instalar Docker ###
### Se usa la guia https://linuxize.com/post/how-to-install-and-use-docker-on-ubuntu-20-04/

### update the packages index and install the dependencies necessary to add a new HTTPS repository
sudo apt update
sudo apt install apt-transport-https ca-certificates curl gnupg-agent software-properties-common

## Import the repository’s GPG key using the following curl command:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

### Add the Docker APT repository to your system:
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

### To install the latest version of Docker, run the commands below. If you want to install a specific Docker version, skip this step and go to the next one.
    sudo apt update
    sudo apt install docker-ce docker-ce-cli containerd.io

### Docker service will start automatically. You can verify it by typing:
sudo systemctl status docker

### When a new version of Docker is released, you can update the packages using the standard:
sudo apt update && sudo apt upgrade

###To execute Docker commands as non-root user you’ll need to add your user to the docker group that is created during the installation of the Docker CE package
sudo usermod -aG docker $USER
newgrp docker

### To verify that Docker has been successfully installed and that you can execute the docker command without prepending sudo
docker container run hello-world

##############################################
###  Instalar Docker-Compose
###  se usa esta guia https://linuxize.com/post/how-to-install-and-use-docker-compose-on-ubuntu-20-04/

###Use curl to download the Compose file into the /usr/local/bin directory
### Editar la versión a lo más actual de acuerdo a esta liga de github https://github.com/docker/compose/releases. Al momento de escribir la guia la versión mas reciente es 1.29.2
##############################################

sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

### Once the download is complete, apply executable permissions to the file:
sudo chmod +x /usr/local/bin/docker-compose

### Verify that the installation was successful
docker-compose --version

### Se debe crear un directorio donde ira el archivo .yml
mkdir my_app
cd my_app
nano docker-compose.yml

### Start the Compose in a detached mode by passing the -d option
docker-compose up -d

### To check the running services use the ps option:
docker-compose ps

### When Compose is running in detached mode to stop the services, run:
docker-compose stop

### To stop and remove the application containers and networks, use the down option:
docker-compose down