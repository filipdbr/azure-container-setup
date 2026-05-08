# Immich on Azure - DevOps Project

This project is a practical DevOps exercise built around deploying a real application. I chose Immich – a self-hosted photo and video backup platform – mainly because it’s interesting to me. It could be any other app - the focus here is on deployment, not the application itself.

Repository: https://github.com/immich-app/immich

The focus is on managing the full lifecycle: provisioning infrastructure, deploying services, and automating the process end-to-end.

## Scope

1. define and provision infrastructure in Azure using Terraform  
2. deploy and manage a multi-service application with Docker  
3. automate setup and deployment using Bash scripts  

## Infrastructure Components

The infrastructure is built on **Microsoft Azure**.

| Component | Resource | Description |
| :--- | :--- | :--- |
| **Networking** | Virtual Network & Subnet | Isolated cloud environment providing a private space for the server. |
| **Security** | Network Security Group | Layer 4 firewall strictly allowing traffic on ports 22 (SSH) and 2283 (Immich). |
| **Connectivity** | Public IP | Dynamic entry point that enables external access to the web interface. |
| **Compute** | Linux VM (Ubuntu 22.04) | `Standard_D2s_v4` |

## Tech stack

- **Cloud:** Microsoft Azure  
- **IaC:** Terraform  
- **Containers:** Docker  
- **Automation:** Bash  
- **Application:** Immich (microservices + AI components)  

## Goal

Build a reproducible environment that can be deployed from scratch without manual steps and runs reliably in the cloud.

## Project Structure

```text
.
├── app/
│   ├── docker-compose.yml     # Official Immich stack
│   └── .env.example           # Environment template (secrets ignored by Git)
└── terraform/
    ├── main.tf                # Providers and Resource Group
    ├── network.tf             # VNet, Subnet, IP, and NSG
    ├── compute.tf             # Virtual Machine and NIC
    ├── variables.tf           # Configuration Center (User-defined variables)
    ├── security.tf            # Azure Key Vault
    └── outputs.tf             # Deployment results (IP & URL)
```

## Provisioning & Configuration

The deployment process separates infrastructure provisioning from system configuration. While Terraform builds the foundation on Azure, a shell script prepares the environment for the application.

### Workflow

1. **Infrastructure as Code:** Terraform creates the Virtual Machine, Network Interface, and associated Azure resources.
2. **Cloud-Init Execution:** During the initial boot sequence, the `user_data` argument in the VM resource automatically injects and executes the `scripts/provision.sh` file.
3. **Docker Setup:** The script runs in the background (using `DEBIAN_FRONTEND=noninteractive` to prevent hanging prompts) to install the latest Docker Engine and Docker Compose directly from the official repositories.
4. **User Management:** The script automatically appends the `immich_admin` user to the `docker` group. This enables seamless, passwordless container management without requiring `sudo` privileges for every command.

# Project Progress

## Completed
- [x] **Infrastructure as Code**: Terraform deploys the Virtual Machine and all required network components.
- [x] **Security**: Azure Key Vault is provisioned and configured for secret management.
- [x] **Automation**: The `provision.sh` script successfully initializes on the VM via User Data.

## To Do
- [ ] **Persistent Storage**: Attach Azure storage resources (e.g., Azure Files or Managed Disks) to store application photos.
- [ ] **Container Management**: 
    - [ ] Set up an Azure Container Registry (ACR).
    - [ ] Build a custom image for the application.
    - [ ] Implement a workflow to pull and deploy the custom image from ACR to the VM.