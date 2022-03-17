### Se usaron estas dos guías ###
### https://linuxize.com/post/how-to-install-and-use-docker-on-ubuntu-20-04/ ###
### https://linuxize.com/post/how-to-install-and-use-docker-compose-on-ubuntu-20-04/ ###

### Install Dependencies ###
sudo apt update && sudo apt upgrade -y
sudo apt install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y

### Import the repository’s GPG key using the following curl command: ###
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
### Add the Docker APT repository to your system: ###
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

### To install the latest version of Docker ###
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io

### Verify Status ###

sudo systemctl status docker

### Executing Docker Commands as a Non-Root User ###
sudo usermod -aG docker $USER
### Note: $USER is an environment variable that holds your username.###

echo "Docker Successfully installed"
echo "If need to update just run:"
echo "sudo apt update && sudo apt upgrade -y"
echo ""
echo "if want to prevent update run:"
echo "sudo apt-mark hold docker-ce"
echo ""

### Verifying the Installation ###

echo "To verify that Docker has been successfully installed and that you can execute the docker command without prepending sudo, logout and run the following test container"

echo "docker container run hello-world"