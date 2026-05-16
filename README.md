# Immich on Azure

This project is a practical DevOps exercise built around deploying a real application. I chose Immich – a self-hosted photo and video backup platform – mainly because it’s interesting to me. It could be any other app - the focus here is on deployment, not the application itself.

Repository: https://github.com/immich-app/immich

The focus is on managing the full lifecycle: provisioning infrastructure, deploying services, and automating the process end-to-end.

## Goal

Build a reproducible environment that can be deployed from scratch without manual steps and runs reliably in the cloud.

## Table of Contents
- [Goal](#goal)
- [Architecture Overview](#architecture-overview)
- [Tech Stack](#tech-stack)
- [Repository Structure](#repository-structure)
- [Infrastructure Components](#infrastructure-components)
- [Workflow](#workflow)
- [Architecture Evolution](#architecture-evolution)
- [Customization & Variables](#customization--variables)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [IMPORTANT: Cleanup](#imporant-cleanup)
- [Project Progress](#project-progress)

## Architecture Overview

The project is built on a stateless, secure, and fully automated cloud architecture:
* **Infrastructure as Code:** Terraform provisions the core Azure resources, including an automated Resource Group, Virtual Machine, Azure Container Registry (ACR), and Key Vault.
* **Orchestrated CI/CD:** A custom Bash script utilizes the GitHub CLI (`gh`) to trigger GitHub Actions asynchronously, building the Docker proxy image and pushing it to ACR before configuration begins.
* **Configuration Management:** Ansible configures the remote server, installs the Docker engine, securely fetches secrets from Key Vault via REST API using Managed Identity, and deploys the application stack.
* **Persistent Cloud Storage:** Photos and media are stored externally using an Azure File Share, mounted directly into the Docker container via a named CIFS volume to keep the application server stateless.

## Tech stack

- **Cloud:** Microsoft Azure  
- **CI/CD Pipeline:** GitHub Actions & GitHub CLI
- **IaC:** Terraform  
- **Configuration Management:** Ansible
- **Containers:** Docker  
- **Reverse Proxy:** Nginx
- **Application:** Immich (microservices + AI components)  

## Repository Structure

```text
.
├── .github/
│   └── workflows/
│       └── docker-build.yml   # CI/CD pipeline for building and pushing the proxy image
├── ansible/
│   ├── azure-provision.yml    # Main playbook for OS config, secrets & Docker setup
│   ├── inventory.example.ini  # Template for VM connection details
│   └── README.md              # Ansible-specific documentation
├── app/
│   └── docker-compose.yml     # Immich microservices stack with persistent CIFS volume
├── docker-proxy/
│   ├── Dockerfile             # Custom Nginx image setup
│   └── nginx.conf             # Reverse proxy routing rules (Port 80 -> Immich)
├── logs/                      # Auto-generated logs for Terraform, Ansible & Deploy scripts
├── terraform/
│   ├── main.tf                # Azure providers and Resource Group definition
│   ├── network.tf             # VNet, Subnet, Public IP, and NSG rules (80/22)
│   ├── compute.tf             # VM instance, Managed Identity, and Network Interface
│   ├── security.tf            # Key Vault, Access Policies, and secret definitions
│   ├── containers.tf          # Azure Container Registry (ACR) configuration
│   ├── storage.tf             # Azure Storage Account and File Share for persistence
│   ├── variables.tf           # Infrastructure input variables
│   └── output.tf              # Exposed IPs, resource names, and keys for Ansible
├── .gitignore                 # Rules to exclude local secrets and terraform state files
├── deploy.sh                  # Main orchestrator script running the entire pipeline
└── README.md                  # Main project overview and documentation
```

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

## Workflow

With the new cloud-native architecture and the orchestrator script, the deployment is now a fully synchronous, automated process. The `deploy.sh` script coordinates the handoff between tools:

1. **Infrastructure Provisioning (Terraform):**
   The process starts by provisioning the Azure foundation. Terraform creates the VM, Network, Key Vault, and ACR. It also provisions an Azure Storage Account and File Share for persistent media storage, and assigns a **Managed Identity** to the VM so it can pull images and access secrets without hardcoded credentials.

2. **CI/CD Synchronization (GitHub Actions & GitHub CLI):**
   Once the infrastructure layer is live, the script extracts the resource names, pushes the code to GitHub, and triggers the Docker build workflow using the GitHub CLI. By utilizing `gh run watch`, the local script physically pauses, monitors the cloud build in real-time, and moves forward only after the custom Nginx Proxy image is successfully baked and pushed to the Azure Container Registry (ACR).

3. **Secure Configuration Management (Ansible):**
   Ansible takes over via SSH once the cloud image is ready. It prepares the server environment by installing system dependencies like `cifs-utils` and Docker. It then executes a **secure secret handshake**: leveraging the VM's Managed Identity, it queries the Azure Key Vault via REST API to fetch both the database password and the Storage Account access key, writing them directly into a secured `.env` file (`0600` permissions) on the server.

4. **Application Orchestration (Docker & Azure File Share):**
   In the final stage, Ansible deploys the configuration. Docker Compose spins up the Immich microservices stack within a private network. Instead of local storage, Docker dynamically connects to the Azure File Share using a named CIFS/SMB volume—complete with proper mount options (`vers=3.0`, `uid/gid=1000`) to guarantee permanent, stateless data storage for your photos.

## Architecture Evolution

When I started this project, I tried to do everything in Terraform. I used the `custom_data` block to pass a massive `provision.sh` script to the VM on startup. At first, it seemed fine — just a quick way to install a few packages.

However, as the Docker setup grew, things got out of hand. I found myself trying to inject entire YAML files into Bash scripts, encoding them in Base64 just to force them through Terraform's HCL. It quickly turned into unreadable, hard-to-debug spaghetti code. Worse, if the script failed halfway through (e.g., due to a network hiccup), my VM was left in a broken state because my Bash script wasn't naturally idempotent. 

To fix solve the problem I decided to step back, wipe the slate clean, and introduce Ansible.

The workflow is now much cleaner and strictly divided into two stages:
1. **Terraform** does what it does best: it provisions the "hardware" (IaaS). It creates the VM, virtual networks, Key Vault, and ACR.
2. **Ansible** handles the software. Once the VM is up and running, Ansible connects natively via SSH. It installs Docker, securely fetches secrets, seamlessly copies my `docker-compose.yml` directly from the local repository to the server, and orchestrates the containers.

## Customization & Variables

The entire infrastructure layer is fully parameterized. You don't need to touch main.tf, network.tf, or compute.tf to alter the deployment. Simply adjust the default values in the `./terraform/variables.tf` file before running the script:

* `location` (Default: polandcentral) – The Azure region where all resources will be provisioned.
* `rg_name` (Default: immich-prod) – The name of the dedicated Resource Group.
* `admin_username` (Default: immich_admin) – The default admin user created on the Ubuntu VM for SSH connections.
* `disk_type` (Default: Standard_LRS) – The storage type for the OS disk. Standard LRS is selected as the most cost-effective option for this lab.
* `vm_sku` (Default: 22_04-lts) – The OS image version (Ubuntu 22.04 LTS).
* `vm_size` (Default: Standard_D2s_v4) – The compute size of the VM (2 vCPUs, 8 GB RAM), providing plenty of horsepower for Immich's microservices and AI components.
* `immich_port` (Default: 2283) – The default internal port used by the Immich application stack, which is safely hidden behind the Nginx Reverse Proxy (Port 80).

## Prerequisites

Before running the deployment, ensure you have the following tools installed on your local machine:

* **Terraform**: Required for infrastructure provisioning. [Official Installation Guide](https://developer.hashicorp.com/terraform/downloads)
* **Ansible**: Required for server configuration and application deployment. [Official Installation Guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
* **Azure CLI**: Needed to authenticate with your Azure account and manage resources. [Official Installation Guide](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
* **GitHub CLI:** Required by the deployment script to automate secret management and trigger GitHub Actions workflows from your terminal. [Official Installation Guide](https://cli.github.com/)
* **SSH Public Key**: A local public key (`~/.ssh/id_rsa.pub`) must exist on your machine. Terraform uses it to provision the Azure VM, enabling passwordless SSH access for Ansible.

## Quick Start

> **Important GitHub Setup**: Before running the deployment, ensure your repository has Actions enabled and the **Workflow permissions** are set to *Read and write permissions* (Go to your repo Settings -> Actions -> General -> Workflow permissions). This allows the GitHub CLI to automatically configure secrets and trigger pipelines.

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

## Project Progress

### Completed
- [x] **Infrastructure as Code:** Terraform successfully deploys the Virtual Machine, ACR, Key Vault, and all required network components.
- [x] **Identity & Security:** Implemented **Managed Identity** for passwordless authentication and moved to a secure **RBAC/Access Policy** model in Key Vault.
- [x] **Configuration Management:** Developed Ansible playbooks to automate OS hardening, Docker installation, and secret retrieval via REST API.
- [x] **Orchestration:** Created a master `deploy.sh` script with integrated logging to coordinate Terraform and Ansible runs.
- [x] **Reverse Proxy:** Built a custom Nginx image to handle routing and hide Immich microservices behind port 80.
- [x] **Persistent Storage:** Integrated **Azure File Share** mounted directly via Docker named volumes with CIFS/SMB driver, ensuring photos persist independently of the VM lifetime.
- [x] **CI/CD Pipeline & Sync:** Automated Docker image builds via **GitHub Actions** and synchronized the local deployment using the GitHub CLI (`gh run watch`).
- [x] **Optimize Registry Usage:** Shifted from building images locally on the VM to pulling pre-built, secure images directly from **Azure Container Registry (ACR)**.
- [x] **Documentation:** Fully updated the README with Architecture details, Prerequisites, Tech Stack, and detailed Workflow descriptions.