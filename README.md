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

## Scope

1. Define and provision infrastructure in Azure using Terraform.
2. Build and store custom container images using Azure Container Registry (ACR).
3. Deploy and manage a multi-service application (Immich + Nginx Proxy) with Docker.
4. Automate OS configuration and application deployment using Ansible.

## Infrastructure Components

The infrastructure is built on **Microsoft Azure**.

| Component | Resource | Description |
| :--- | :--- | :--- |
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
├── app/
│   ├── docker-compose.yml     # Application stack (Immich + Proxy)
│   └── .env.example           # Environment template
├── ansible/
│   ├── inventory.ini          # Target VM connection details
│   └── setup.yml              # Playbook for OS config & Docker deployment
├── docker-proxy/
│   ├── Dockerfile             # Instructions for custom Nginx image
│   └── nginx.conf             # Reverse proxy routing rules
└── terraform/
    ├── main.tf                # Providers and Resource Group
    ├── network.tf             # VNet, Subnet, IP, and NSG
    ├── compute.tf             # Virtual Machine and NIC
    ├── variables.tf           # User-defined variables
    ├── security.tf            # Azure Key Vault & ACR
    └── outputs.tf             # Deployment results (IP & URLs)
```

## Architecture Evolution: Why I Dropped Bash for Ansible

When I started this project, I tried to do everything in Terraform. I used the `custom_data` block to pass a massive `provision.sh` script to the VM on startup. At first, it seemed fine — just a quick way to install a few packages.

However, as the Docker setup grew, things got out of hand. I found myself trying to inject entire YAML files into Bash scripts, encoding them in Base64 just to force them through Terraform's HCL. It quickly turned into unreadable, hard-to-debug spaghetti code. Worse, if the script failed halfway through (e.g., due to a network hiccup), my VM was left in a broken state because my Bash script wasn't naturally idempotent. 

To fix solve the problem I decided to step back, wipe the slate clean, and introduce Ansible.

The workflow is now much cleaner and strictly divided into two stages:
1. **Terraform** does what it does best: it provisions the "hardware" (IaaS). It creates the VM, virtual networks, Key Vault, and ACR.
2. **Ansible** handles the software. Once the VM is up and running, Ansible connects natively via SSH. It installs Docker, securely fetches secrets, seamlessly copies my `docker-compose.yml` directly from the local repository to the server, and orchestrates the containers.

## Workflow

With the new architecture in place, deploying the environment from scratch is a smooth, three-step process:

1. **Building the Foundation (Terraform):** I run `terraform apply`. This sets up the Azure Virtual Machine, configures the network security, provisions the Key Vault, and sets up the Container Registry (ACR). It hands me back the VM's new public IP.
2. **Prepping the Proxy (Docker):** I build my custom Nginx reverse proxy image locally and push it directly to my new ACR. 
3. **Connecting the Dots (Ansible):** I run my Ansible playbook against the VM's IP. Ansible logs in via SSH, sets up the Ubuntu OS, installs Docker, authenticates with ACR, safely copies my local `docker-compose.yml`, and spins up the entire Immich stack. No more praying that a startup script didn't fail silently in the background!

## Project Progress

### Completed
- [x] **Infrastructure as Code**: Terraform successfully deploys the Virtual Machine, ACR, Key Vault, and all required network components.
- [x] **Security Configuration**: Network Security Group restricts traffic strictly to required ports, and secrets are managed via Azure Key Vault.
- [x] **Reverse Proxy**: Built a custom Nginx image to hide Immich behind a single entry point on port 80.
- [x] **Architecture Refactor**: Completely ripped out legacy Bash scripts and `custom_data` from Terraform to enforce a clean Separation of Concerns.

### To Do
- [x] **Configuration Management**: Write the actual Ansible playbooks (`setup.yml`) to automate the Docker installation and container deployment.
- [ ] **Documentation**: Update documentation, describe Ansible playbooks, updates in Key Vault and updates in the shell script.
- [ ] **Persistent Storage**: Attach dedicated Azure storage (like Azure Files or Managed Disks) so photo backups aren't lost if the VM dies.
- [ ] **CI/CD Pipeline**: Automate the Docker image build and push process to ACR using GitHub Actions.