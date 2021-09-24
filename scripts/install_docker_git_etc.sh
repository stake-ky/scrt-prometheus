#!/bin/bash

# Variables
# Linux Distribution Version
linuxDist="20.04"
# Linux Distribution Name. 16.04 xenial, 18.04 bionic, 20.04 focal
linuxDistName="focal"
# Docker version https://docs.docker.com/engine/release-notes/
dockerVersion="20.10.6"
# Docker Compose version https://docs.docker.com/compose/release-notes/
dockerComposeVersion="1.29.1"

# Prerequisite packages
echo "~ Update your existing list of packages"
sudo apt update
echo "~ Install prerequisite packages"
sudo apt install -y \
    apache2-utils \
    apt-transport-https \
    ca-certificates \
    curl \
    unzip \
    software-properties-common \
    wget

# Docker
echo "~ Add the GPG key for the official Docker repository"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
echo "~ Add the Docker repository to APT sources"
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu ${linuxDistName} stable"
echo "~ Update the package database"
sudo apt update
echo "~ Confirm install from the Docker repo not default Ubuntu repo"
apt-cache policy docker-ce
echo "~ Install docker-ce"
sudo apt install -y docker-ce=5:${dockerVersion}~3-0~ubuntu-${linuxDistName}

# Docker-compose
echo "~ Install docker-compose version ${dockerComposeVersion}"
sudo curl -L https://github.com/docker/compose/releases/download/${dockerComposeVersion}/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
echo "~ Allow docker-compose to execute"
sudo chmod +x /usr/local/bin/docker-compose

echo "~ List current user groups"
groups
echo "~ Create docker group"
sudo groupadd docker
echo "~ Add user to docker group"
sudo usermod -aG docker $USER

# Git
echo "~ Install git"
sudo apt-get install -y git
echo "~ Install git lfs"
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
sudo apt-get install -y git-lfs
git lfs install

echo "~ Update and upgrade before proceeding"
sudo apt-get update && sudo apt-get upgrade -y

# Confirm
echo "~ Confirm docker version"
docker --version
echo "~ Confirm docker-compose version"
docker-compose --version
echo "~ Confirm git version"
git --version