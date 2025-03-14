# Development Container Configuration

This directory contains configuration files for Visual Studio Code's Development Containers feature. Using Dev Containers provides a consistent development environment for working with this project.

## Getting Started

1. Prerequisites:
   - [Visual Studio Code](https://code.visualstudio.com/)
   - [Docker](https://www.docker.com/)
   - [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

2. Setup:
   - Copy `.env.example` to `.env` and fill in your Azure credentials
   - Open this folder in VS Code
   - When prompted, click "Reopen in Container" or run the "Dev Containers: Reopen in Container" command

## What's Included

This Dev Container provides:

- Azure CLI with extensions
- Terraform
- Ansible
- Python 3.10
- Fish shell with Oh My Fish
- Common development tools (git, jq, etc.)
- VS Code extensions for Azure/Terraform development

## Customization

- Modify `devcontainer.json` to add/remove VS Code extensions or container features
- Edit `Dockerfile` to install additional packages or customize the environment
- Update `.env.example` if you need additional environment variables

## Troubleshooting

If you encounter issues:
1. Try rebuilding the container (Dev Containers: Rebuild Container)
2. Check Docker logs
3. Ensure your `.env` file has the correct credentials 