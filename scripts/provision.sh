#!/bin/bash

# loggin sciprt execution to the file
exec >> /var/log/user_data.log 2>&1

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

# install azure CLI in order to get access to key vault
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

az login --identity

# try to retrieve the pass for 120 seconds
end=$((SECONDS+120))
start=$SECONDS
while [ $SECONDS -lt $end ]; do
    DB_PASS=$(az keyvault secret show --name "${pass_name}" --vault-name "${vault_name}" --query value -o tsv 2>/dev/null)
    
    # if DB_PASS var isn't empty break the loop
    if [ -n "$DB_PASS" ]; then
        echo "Successfully retrieved password from Key Vault"
        break
    fi
    echo "Waiting for Key Vault permissions to propagate. Time passed: $(( SECONDS - $start))"
    sleep 10
done

# Zabezpieczenie: Jeśli po 2 minutach hasło nadal jest puste, przerwij skrypt
if [ -z "$DB_PASS" ]; then
    echo "Failed to retrieve database password. Exiting."
    exit 1
fi

# additional docker components
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# start the docker and make it start automatically with each reboot
systemctl enable --now docker

# adding the user defined in Terraform to the docker grooup
usermod -aG docker immich_admin

mkdir immich-app && cd immich-app

wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml

touch .env

cat > .env <<EOF
# You can find documentation for all the supported env variables at https://docs.immich.app/install/environment-variables

# The location where your uploaded files are stored
UPLOAD_LOCATION=./library

# The location where your database files are stored. Network shares are not supported for the database
DB_DATA_LOCATION=./postgres

# To set a timezone, uncomment the next line and change Etc/UTC to a TZ identifier from this list: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List
# TZ=Etc/UTC

# The Immich version to use. You can pin this to a specific version like "v2.1.0"
IMMICH_VERSION=v2

# Connection secret for postgres. You should change it to a random password
# Please use only the characters `A-Za-z0-9`, without special characters or spaces
DB_PASSWORD=$DB_PASS

# The values below this line do not need to be changed
###################################################################################
DB_USERNAME=$DB_USERNAME
DB_DATABASE_NAME=immich
EOF

chown -R ${admin_name}:${admin_name} /home/${admin_name}/immich-app
sudo -u ${admin_name} docker compose up -d