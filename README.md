# Immich on Azure

This project is a practical DevOps exercise built around deploying a real application. I chose Immich – a self-hosted photo and video backup platform – mainly because it’s interesting to me. It could be any other app - the focus here is on deployment, not the application itself.

Repository: https://github.com/immich-app/immich

The focus is on managing the full lifecycle: provisioning infrastructure, deploying services, and automating the process end-to-end.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Scope](#scope)
- [Infrastructure Components](#infrastructure-components)
- [Tech Stack](#tech-stack)
- [Goal](#goal)
- [Project Structure](#project-structure)
- [Architecture Evolution: Why I Dropped Bash for Ansible](#architecture-evolution-why-i-dropped-bash-for-ansible)
- [Workflow](#workflow)
- [Project Progress](#project-progress)

## Prerequisites

Before running the deployment, ensure you have the following tools installed on your local machine:

* **Terraform**: Required for infrastructure provisioning. [Official Installation Guide](https://developer.hashicorp.com/terraform/downloads)
* **Ansible**: Required for server configuration and application deployment. [Official Installation Guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
* **Azure CLI**: Needed to authenticate with your Azure account and manage resources. [Official Installation Guide](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

## Quick Start

Follow these steps to clone the repository and deploy the entire stack:

1. **Clone the Repository**:
   Navigate to the directory where you want to keep the project and run:
   ```bash
   git clone https://github.com/filipdbr/azure-container-setup.git
   cd azure-container-setup
   ```

2. **Authenticate with Azure:**
    Ensure you are logged into your Azure account:
    ```bash
    az login
    ```

3. **Deploy:**
    Grant execution permissions to the orchestration script and run it:
    ```bash
    chmod +x deploy.sh
    ./deploy.sh
    ```

4. **Access Immich:**
    The script will display the server's Public IP upon completion. Open your browser and go to:
    `http://<YOUR_VM_IP>`

## IMPORANT: Cleanup

Infrastructure in Azure incurs costs as long as the resources exist. **To avoid unexpected charges**, ensure you destroy the environment once you are finished testing.

Navigate to the Terraform directory and destroy all resources:
```bash
cd terraform
terraform destroy --auto-approve
```

**Important: This command will permanently remove all provisioned resources**, including the Virtual Machine, Key Vault, and Azure Container Registry. Make sure you have backed up any important data (e.g., photos uploaded to Immich) before running this. 

## Scope

1. Define and provision infrastructure in Azure using Terraform.
2. Build and store custom container images using Azure Container Registry (ACR).
3. Deploy and manage a multi-service application (Immich + Nginx Proxy) with Docker.
4. Automate OS configuration and application deployment using Ansible.

## Infrastructure Components

The infrastructure is built on **Microsoft Azure**.

| Component | Resource | Description |
| :--- | :--- | :--- |
| **Identity** | Managed Service Identity (MSI) | Passwordless authentication allowing the VM to securely fetch secrets from Azure. |
| **Networking** | Virtual Network & Subnet | Isolated cloud environment providing a private space for the server. |
| **Security** | Network Security Group | Layer 4 firewall strictly allowing traffic on ports 22 (SSH) and 2283 (Immich). |
| **Connectivity** | Public IP | Dynamic entry point that enables external access to the web interface. |
| **Storage** | Azure Container Registry | Private registry to store custom images (e.g., Nginx Reverse Proxy). |
| **Secrets** | Azure Key Vault | Secure storage for database passwords and sensitive environment variables. |

## Tech stack

- **Cloud:** Microsoft Azure  
- **IaC:** Terraform  
- **Configuration Management:** Ansible
- **Containers:** Docker  
- **Reverse Proxy:** Nginx
- **Application:** Immich (microservices + AI components)  

## Goal

Build a reproducible environment that can be deployed from scratch without manual steps and runs reliably in the cloud.

## Project Structure

```text
.
├── ansible/
│   ├── azure-provision.yml    # Main playbook for OS config, secrets & Docker
│   ├── inventory.example.ini  # Template for connection details
│   └── README.md              # Ansible-specific documentation
├── app/
│   └── docker-compose.yml     # Immich microservices stack definition
├── docker-proxy/
│   ├── Dockerfile             # Custom Nginx image with proxy config
│   └── nginx.conf             # Routing rules (Port 80 -> Immich)
├── logs/                      # Auto-generated logs for Terraform, Ansible & Deploy
├── terraform/
│   ├── main.tf                # Providers and Resource Group
│   ├── network.tf             # VNet, Subnet, IP, and NSG (Port 80/22)
│   ├── compute.tf             # VM, Managed Identity and NIC
│   ├── security.tf            # Key Vault, RBAC/Access Policies & Secrets
│   ├── containers.tf          # Azure Container Registry (ACR) configuration
│   ├── variables.tf           # Infrastructure variables
│   └── output.tf              # IPs, Names and URLs for Ansible/User
├── .gitignore                 # Rules to exclude secrets and terraform state
├── deploy.sh                  # Main bash script to run the entire pipeline
└── README.md                  # Project overview and documentation
```

## Architecture Evolution: Switch from Bash to Ansible

When I started this project, I tried to do everything in Terraform. I used the `custom_data` block to pass a massive `provision.sh` script to the VM on startup. At first, it seemed fine — just a quick way to install a few packages.

However, as the Docker setup grew, things got out of hand. I found myself trying to inject entire YAML files into Bash scripts, encoding them in Base64 just to force them through Terraform's HCL. It quickly turned into unreadable, hard-to-debug spaghetti code. Worse, if the script failed halfway through (e.g., due to a network hiccup), my VM was left in a broken state because my Bash script wasn't naturally idempotent. 

To fix solve the problem I decided to step back, wipe the slate clean, and introduce Ansible.

The workflow is now much cleaner and strictly divided into two stages:
1. **Terraform** does what it does best: it provisions the "hardware" (IaaS). It creates the VM, virtual networks, Key Vault, and ACR.
2. **Ansible** handles the software. Once the VM is up and running, Ansible connects natively via SSH. It installs Docker, securely fetches secrets, seamlessly copies my `docker-compose.yml` directly from the local repository to the server, and orchestrates the containers.

## Workflow

With the new architecture and the orchestration script, the deployment is now a fully automated process. The `deploy.sh` script coordinates the handoff between tools:

1. **Infrastructure Orchestration (Terraform)**:
   The process starts by provisioning the Azure foundation. Terraform creates the VM, Network, Key Vault (with a randomly generated DB password), and ACR. It also assigns a **Managed Service Identity (MSI)** to the VM, allowing it to communicate with Azure services without hardcoded credentials.

2. **Configuration & Security (Ansible)**:
   Once the VM is ready, Ansible takes over via SSH. It performs a **secure secret handshake**: using the VM's Managed Identity, it fetches the database password directly from Azure Key Vault via REST API. It then generates a secure `.env` file with `0600` permissions directly on the server.

3. **Application Deployment (Docker)**:
   In the final stage, Ansible copies the `docker-compose.yml` and builds the custom Nginx Proxy image directly on the target machine. It then spins up the Immich stack within a private Docker network, ensuring that only the Proxy is exposed to the internet on port 80.

## Project Progress

### Completed
- [x] **Infrastructure as Code**: Terraform successfully deploys the Virtual Machine, ACR, Key Vault, and all required network components.
- [x] **Identity & Security**: Implemented **Managed Service Identity (MSI)** for passwordless authentication and moved to a secure **RBAC/Access Policy** model in Key Vault.
- [x] **Configuration Management**: Developed Ansible playbooks to automate OS hardening, Docker installation, and secret retrieval via REST API.
- [x] **Orchestration**: Created a master `deploy.sh` script with integrated logging to coordinate Terraform and Ansible runs.
- [x] **Reverse Proxy**: Built a custom Nginx image to handle routing and hide Immich microservices behind port 80.
- [x] **Documentation**: Fully updated the README with Prerequisites, Quick Start guide, and detailed Workflow descriptions.

### To Do
- [ ] **Persistent Storage**: Attach dedicated Azure storage (e.g., Azure Managed Disks or Azure Files) to ensure photo backups persist even if the VM is recreated.
- [ ] **Automated Backups**: Implement a strategy for backing up the Immich PostgreSQL database to Azure Blob Storage.
- [ ] **CI/CD Pipeline**: Integrate GitHub Actions to automate the testing of Terraform plans and Docker image builds on every push.
- [ ] **Optimize Registry Usage**: Shift from local Docker builds on the VM to pulling pre-built images from Azure Container Registry (ACR).