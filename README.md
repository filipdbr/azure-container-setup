# Immich on Azure - DevOps Project

This project is a practical DevOps exercise built around deploying a real application. I chose Immich – a self-hosted photo and video backup platform – mainly because it’s interesting to me. It could be any other app - the focus here is on deployment, not the application itself.

Repository: https://github.com/immich-app/immich

The focus is on managing the full lifecycle: provisioning infrastructure, deploying services, and automating the process end-to-end.

## Scope

- define and provision infrastructure in Azure using Terraform  
- deploy and manage a multi-service application with Docker  
- automate setup and deployment using Bash scripts  

## Tech stack

- **Cloud:** Microsoft Azure  
- **IaC:** Terraform  
- **Containers:** Docker  
- **Automation:** Bash  
- **Application:** Immich (microservices + AI components)  

## Goal

Build a reproducible environment that can be deployed from scratch without manual steps and runs reliably in the cloud.