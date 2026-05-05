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
| **Compute** | Linux VM (Ubuntu 22.04) | `Standard_B2s` instance optimized for Immich's AI workloads and media indexing. |

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
    └── outputs.tf             # Deployment results (IP & URL)
```