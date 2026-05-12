#!/bin/bash

# the script deploy and configure infrastructure using terraform and ansible (respectively)

# log script execuition

# define the timestamp variable
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "Deployment in progress..."

# create logs directory
mkdir -p logs/{terraform,ansible}

# define variable containing logs dir absolute path
LOG_DIR="$(pwd)/logs"

# configure main log
MAIN_LOG="$LOG_DIR/deploy_$TIMESTAMP.log"
exec > >(tee -a "$MAIN_LOG") 2>&1

echo "--- Deployment started at $(date) ---"

### Deploy infrastructure using Terraform ###

# navigate to the terraform directory, exit immediately if the directory is missing
cd terraform || exit

# configure logs for terraform
export TF_LOG="INFO"
export TF_LOG_PATH="$LOG_DIR/terraform/terraform_$TIMESTAMP.log"

echo "Initializing Terraform..."
terraform init

echo "Applying Terraform configuration..."
# run Terraform apply and catch any potential errors
if ! terraform apply -auto-approve; then
    echo "Error: Terraform apply failed. You can check terraform logs here: $TF_LOG_PATH"
    exit 1
fi

# assign a variable: IP of the newly created VM
VM_IP=$(terraform output -raw public_ip_address)

# check if the IP variable is empty 
if [[ -z "$VM_IP" ]]; then
    echo "Error: The VM IP hasn't been assigned or retrieved properly."
    exit 1
else
    echo "Infrastructure deployed successfully. Server IP: $VM_IP"
fi

# get key vault name
KV_NAME=$(terraform output -raw keyvault_name)

### Provision the server using Ansible ###

# SSH daemon need time to boot up - wait 30 s
echo "Waiting 30 seconds for SSH to be ready on the VM..."
sleep 30

# configure logs for ansible
export ANSIBLE_LOG_PATH="$LOG_DIR/ansible/ansible$TIMESTAMP.log"

echo "Server configuration in progress..."
cd ../ansible || exit

# run the Ansible playbook and catch any potential errors
if ! ansible-playbook -i inventory.ini azure-provision.yml --extra-vars "keyvault_name=$KV_NAME"; then
    echo "Error: Ansible provisioning failed. You can check the playbook logs here: $ANSIBLE_LOG_PATH"
    exit 1
else
    echo "Deployment completed successfully!"
fi

# inform the end user of Immich URL
echo "Immich URL: http://$VM_IP"