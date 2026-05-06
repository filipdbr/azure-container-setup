#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

 apt update &&  apt upgrade -y

# official docker installation script (available at https://docs.docker.com/engine/install/ubuntu/)
# Add Docker's official GPG key:
 apt update
 apt install -y ca-certificates curl
 install -m 0755 -d /etc/apt/keyrings
 curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
 chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
 tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt update

# additional docker components
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# start the docker and make it start automatically with each reboot
systemctl enable --now docker

# adding the user defined in Terraform to the docker grooup
usermod -aG docker immich_admin

# Verification
docker_status=$(systemctl is-active docker)
if [ "$docker_status" = "active" ]; then
    echo "Docker service is active"
else
    echo "Docker service doesn't work"
    exit 1
fi