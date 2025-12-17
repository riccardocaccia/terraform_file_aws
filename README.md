# AWS Terraform – Bastion + Private Galaxy VM

This repository provisions an AWS infrastructure using **Terraform** with:
- A **public bastion host (Ubuntu 22.04)** configured via cloud-init and Ansible
- A **private Rocky Linux 9 VM** running Galaxy/Nebula automation via Ansible
- A custom **VPC with public and private subnets**
- **NAT Gateway** for outbound internet access from the private subnet

---

## Architecture Overview

- **VPC**: `10.10.0.0/16`
- **Public Subnet**: `10.10.1.0/24`
- **Private Subnet**: `10.10.2.0/24`
- **Internet Gateway**: attached to public subnet
- **NAT Gateway**: allows private VM outbound internet access
- **Bastion Host**:
  - Ubuntu 22.04
  - Public IP
  - SSH restricted to admin IP
  - Runs Ansible to configure VPN/Bastion services
- **Galaxy VM**:
  - Rocky Linux 9
  - Private subnet only
  - SSH access only from bastion
  - Runs Ansible playbook for Galaxy/Nebula deployment

---

## Repository Structure

├── main.tf # Terraform infrastructure definition
├── variables.tf # Input variables
├── terraform.tfvars # Variable values (NOT for public repos)
├── cloudinit-bastion.sh # Bastion cloud-init + Ansible bootstrap
├── cloudinit.sh # Galaxy VM cloud-init + Ansible bootstrap
├── terraform.tfstate # Local Terraform state
└── terraform.tfstate.backup

---

## Cloud-Init Behavior

### Bastion (`cloudinit-bastion.sh`)
- Updates system packages
- Installs Ansible and Git
- Enables IPv4/IPv6 forwarding
- Clones:
  - `ansible-role-vpn-bastion`
- Installs Ansible role dependencies (if any)
- Executes `site.yml` using the provided inventory

### Galaxy VM (`cloudinit.sh`)
- Installs Ansible and Git (Rocky Linux / DNF)
- Clones:
  - `laniakea-nebula`
- Installs Ansible Galaxy roles
- Executes `deploy-galaxy.yml` with predefined variables

---

## Requirements

- Terraform ≥ 1.5
- AWS account
- Valid AWS credentials
- SSH key pair (public key provided via variables)

---

## Variables

Defined in `variables.tf` and populated in `terraform.tfvars`.

Minimum required:
- `aws_region`
- `aws_access_key`
- `aws_secret_key`
- `public_ssh_key`
- `bastion_ip` (CIDR, e.g. `x.x.x.x/32`)
- `galaxy_instance_type`

 **Do NOT commit `terraform.tfvars` to a public repository.**

---

## Usage

```bash
terraform init
terraform plan
terraform apply
```

to destroy:
```bash
terraform destroy
```

