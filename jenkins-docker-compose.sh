## Install and run persistant jenkins image with docker-compose ##

## Create docker-compose.yaml file on a dedicated directory (example ./jenkins-docker-compose)

version: '3.8'

services:
  jenkins:
    image: jenkins/jenkins:lts
    privileged: true
    user: root
    ports:
      - 8080:8080
      - 50000:50000
    container_name: jenkins
    restart: unless-stopped
    volumes:
      - ./jenkins_configuration:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock

## Start docker-compose service unatended ##
docker-compose up -d

## obtener password de inicio ##
docker logs jenkins | less