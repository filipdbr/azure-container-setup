#!/bin/bash

sudo apt update && sudo apt upgrade -y

# official docker installation script (available at https://docs.docker.com/engine/install/ubuntu/)
# Add Docker's official GPG key:
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update

# additional docker components
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# start the docker and make it start automatically with each reboot
sudo systemctl enable --now docker

# adding the user defined in Terraform to the docker grooup
sudo usermod -aG docker immich_admin

# Verification
docker_status=$(systemctl is-active docker)
if [ "$docker_status" = "active" ]; then
    echo "Docker service is active"
else
    echo "Docker service doesn't work"
    exit 1
fi