FROM mcr.microsoft.com/devcontainers/base:debian-12

# Install fish shell
RUN apt-get update && apt-get install -y fish && \
    chsh -s /usr/bin/fish vscode && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install additional tools
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    jq \
    make \
    gnupg \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    lsb-release \
    openssh-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI extensions
RUN echo "Installing Azure CLI extensions..." && \
    az extension add --name azure-devops && \
    az extension add --name ssh

# Set up oh-my-fish
RUN curl -L https://get.oh-my.fish > /tmp/install && \
    fish /tmp/install --noninteractive && \
    rm /tmp/install

# Create shared environment file
RUN echo "# Generated environment variables" > /etc/profile.d/devcontainer-env.sh && \
    echo "export AZURE_CONFIG_DIR=/home/vscode/.azure" >> /etc/profile.d/devcontainer-env.sh && \
    echo "export EDITOR=code" >> /etc/profile.d/devcontainer-env.sh && \
    chmod +x /etc/profile.d/devcontainer-env.sh

# Set up alias
RUN echo "alias tf='terraform'" >> /home/vscode/.bashrc && \
    mkdir -p /home/vscode/.config/fish && \
    echo "alias tf='terraform'" >> /home/vscode/.config/fish/config.fish

# Set up working directory
WORKDIR /workspace

# Switch back to the default user (vscode)
USER vscode
