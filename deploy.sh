#!/bin/bash

# the script deploy and configure infrastructure using terraform and ansible (respectively)

echo "Deployment in progress..."

# create logs directory
mkdir -p logs

# define variable containing logs dir absolute path
LOG_DIR="$(pwd)/logs"

### Deploy infrastructure using Terraform ###

# navigate to the terraform directory, exit immediately if the directory is missing
cd terraform || exit

# configure logs for terraform
export TF_LOG="INFO"
export TF_LOG_PATH="$LOG_DIR/terraform.log"

echo "Initializing Terraform..."
terraform init

echo "Applying Terraform configuration..."
# run Terraform apply and catch any potential errors
if ! terraform apply -auto-approve; then
    echo "Error: Terraform apply failed. You can check terraform logs here: $TF_LOG_PATH"
    exit 1
fi

# assign a variable: IP of the newly created VM
VM_IP=$(terraform output -raw vm_public_ip)

# check if the IP variable is empty 
if [[ -z "$VM_IP" ]]; then
    echo "Error: The VM IP hasn't been assigned or retrieved properly."
    exit 1
else
    echo "Infrastructure deployed successfully. Server IP: $VM_IP"
fi

### Provision the server using Ansible ###

# SSH daemon need time to boot up - wait 30 s
echo "Waiting 30 seconds for SSH to be ready on the VM..."
sleep 30

# configure logs for ansible
export ANSIBLE_LOG_PATH="$LOG_DIR/ansible.log"

echo "Server configuration in progress..."
cd ../ansible || exit

# run the Ansible playbook and catch any potential errors
if ! ansible-playbook -i inventory.ini setup.yml; then
    echo "Error: Ansible provisioning failed. You can check the playbook logs here: $ANSIBLE_LOG_PATH"
    exit 1
else
    echo "Deployment completed successfully!"
fi