###################################################################################
### Build and Run Docker Images for nodejs app ###
### I used this guide https://blog.knoldus.com/deployment-with-docker-in-ionic/ ###
###################################################################################

### Build a docker image for ionic on Ubuntu Server LTS-20.04 ###
## Install nodejs from nodesource repository ##
curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs
node --version
npm --version

## Install ionic as a global dependency ##
sudo npm cache clean --force
sudo npm install -g ionic
ionic start ionic-app blank --type=angular
# seleccionar el framework de Angular #

## Create Dockerfile ##
cd ionic-app
touch Dockerfile
vi Dockerfile
#Introducir esto en el Dockerfile
FROM node:14-alpine as build
WORKDIR /app
COPY package*.json /app/
RUN npm install -g ionic
RUN npm install
COPY ./ /app/
RUN npm run-script build
FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /app/www/ /usr/share/nginx/html/

## Build and Deploy using Dockerfile ##
## build a Docker Image##
docker build -t ionic-app:v1 .
## Run the docker image ##
docker run -d --name ionic-appContainer --network host ionic-app:v1

# Open an interactive terminal to test the image #
docker ps
docker exec -it <image-id> sh

