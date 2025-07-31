#!/bin/bash
# AWS EC2 Server Setup Script for Rails 8 + Kamal Deployment
# Run this script on your EC2 instance after initial launch

set -e

echo "🚀 Setting up EC2 instance for Rails 8 + Kamal deployment..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
echo "🔧 Installing essential packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Docker
echo "🐳 Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh

# Add ubuntu user to docker group
echo "👤 Adding ubuntu user to docker group..."
sudo usermod -aG docker ubuntu

# Install Docker Compose Plugin
echo "🔧 Installing Docker Compose Plugin..."
sudo apt install -y docker-compose-plugin

# Start and enable Docker service
echo "🔄 Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Create necessary directories
echo "📁 Creating application directories..."
sudo mkdir -p /var/log/kamal
sudo chown ubuntu:ubuntu /var/log/kamal

# Configure firewall (UFW)
echo "🔥 Configuring firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Install AWS CLI (optional but useful)
echo "☁️ Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Set up log rotation for Docker
echo "📝 Setting up Docker log rotation..."
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

# Restart Docker to apply log rotation settings
sudo systemctl restart docker

# Display system information
echo "ℹ️ System Information:"
echo "Docker version: $(docker --version)"
echo "Docker Compose version: $(docker compose version)"
echo "Available memory: $(free -h | grep Mem | awk '{print $2}')"
echo "Available disk space: $(df -h / | tail -1 | awk '{print $4}')"

echo "✅ EC2 instance setup complete!"
echo ""
echo "Next steps:"
echo "1. Logout and login again to apply docker group membership"
echo "2. Test Docker: docker run hello-world"
echo "3. Configure your local Kamal deployment settings"
echo "4. Run: kamal setup (from your local machine)"
echo ""
echo "🎉 Your EC2 instance is ready for Kamal deployment!"