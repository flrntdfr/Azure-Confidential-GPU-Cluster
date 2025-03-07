# Confidential Computing with GPU for Medical AI Workloads

This repository contains Infrastructure as Code (IaC) for deploying a virtualized Slurm cluster with GPU support on Azure for confidential computing in medical AI workloads.

## Project Overview

The infrastructure is designed to support confidential computing with GPU acceleration for medical AI workloads, providing a secure environment for sensitive data processing while leveraging the computational power of GPUs.

## Technologies Used

- **Terraform**: For infrastructure provisioning in Azure
- **Ansible**: For configuration management of the deployed resources
- **Azure**: Cloud provider with confidential computing capabilities
- **Slurm**: Workload manager for the compute cluster

## Repository Structure

```
.
├── .azure-pipelines/          # Azure DevOps pipeline definitions
├── .github/                   # GitHub Actions workflows
├── terraform/                 # Terraform configurations
│   ├── environments/          # Environment-specific configurations
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   ├── modules/               # Reusable Terraform modules
│   │   ├── network/
│   │   ├── compute/
│   │   ├── storage/
│   │   ├── security/
│   │   └── slurm-cluster/
│   └── scripts/               # Helper scripts for Terraform
├── ansible/                   # Ansible playbooks and roles
│   ├── inventories/           # Inventory files for different environments
│   ├── group_vars/            # Group variables
│   ├── host_vars/             # Host-specific variables
│   ├── roles/                 # Ansible roles
│   ├── playbooks/             # Ansible playbooks
│   └── scripts/               # Helper scripts for Ansible
├── scripts/                   # Utility scripts
├── docs/                      # Documentation
└── .cursorrules               # Cursor editor rules
```

## Getting Started

### Prerequisites

- Azure CLI
- Terraform >= 1.0.0
- Ansible >= 2.9.0
- Python >= 3.8
- Azure subscription with appropriate permissions

### Setup

1. **Clone the repository**

```bash
git clone <repository-url>
cd <repository-name>
```

2. **Configure Azure Authentication**

```bash
az login
az account set --subscription <subscription-id>
```

3. **Initialize Terraform**

```bash
cd terraform/environments/dev
terraform init
```

4. **Deploy Infrastructure**

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

5. **Configure with Ansible**

```bash
cd ../../../ansible
ansible-playbook -i inventories/dev playbooks/site.yml
```

## Usage

Detailed usage instructions can be found in the [docs/usage.md](docs/usage.md) file.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the [LICENSE](LICENSE) file in the repository. 