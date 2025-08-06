# Rails 8 + Kamal + AWS EC2 Deployment Tutorial

## Overview
This tutorial demonstrates how to deploy a Rails 8 application to AWS EC2 using Kamal, Rails 8's built-in zero-downtime deployment tool. We'll use AWS Free Tier resources and follow best practices throughout.

## Prerequisites
- Rails 8 application (this weather app)
- AWS Account with Free Tier access
- Docker installed locally
- SSH key pair for AWS EC2

## What You'll Learn
- Setting up AWS EC2 instance for Rails deployment
- Configuring Kamal for production deployment
- Managing secrets and environment variables
- Zero-downtime deployments with Kamal
- Best practices for production Rails deployment
- HTTP deployment with optional SSL upgrade path

## AWS Free Tier Resources We'll Use
- **EC2 t2.micro instance** (750 hours/month free)
- **Elastic IP** (1 free when associated with running instance)
- **Security Groups** (free)
- **Route 53** (not needed for this tutorial - we'll use IP address)

## Step 1: Prepare the Rails Application

### Current Kamal Configuration
Our Rails 8 app already includes Kamal configuration files:
- `config/deploy.yml` - Main deployment configuration
- `Dockerfile` - Production container definition
- `bin/kamal` - Kamal CLI tool

### Review Current Configuration
```yaml
# config/deploy.yml (current state)
service: weather
image: your-user/weather
servers:
  web:
    - 192.168.0.1  # We'll replace this with our EC2 IP
```

## Step 2: AWS EC2 Setup

### 2.1 Launch EC2 Instance
1. **Instance Type**: t2.micro (Free Tier eligible)
2. **AMI**: Ubuntu Server 22.04 LTS
3. **Storage**: 8GB gp2 (Free Tier includes 30GB)
4. **Security Group**: Configure ports 22 (SSH), 80 (HTTP)

### 2.2 Security Group Configuration
```
Type        Protocol    Port Range    Source
SSH         TCP         22           Your IP
HTTP        TCP         80           0.0.0.0/0
```

### 2.3 Elastic IP (Optional but Recommended)
- Allocate and associate an Elastic IP to avoid IP changes on restart

## Step 3: Server Preparation

### 3.1 Connect to EC2 Instance
```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```
*Replace with your actual key file and EC2 IP address*

### 3.2 Install Docker on Ubuntu
```bash
sudo apt update && sudo apt upgrade -y
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
sudo systemctl start docker
sudo systemctl enable docker
docker --version
```
*These commands update the system, install Docker, add user to docker group, start Docker, and verify installation*

### 3.3 Install Docker Compose (if needed)
```bash
sudo apt install docker-compose-plugin
```

## Step 4: Configure Kamal for AWS EC2

### 4.1 Update deploy.yml
We'll modify the configuration for our EC2 deployment:

```yaml
# config/deploy.yml (updated for EC2)
service: weather
image: your-dockerhub-username/weather

servers:
  web:
    - YOUR_EC2_ELASTIC_IP

# HTTP deployment - no SSL configuration needed
# For SSL later: add domain name and enable proxy configuration

registry:
  username: your-dockerhub-username
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  secret:
    - RAILS_MASTER_KEY
    - WEATHER_API_KEY
  clear:
    SOLID_QUEUE_IN_PUMA: true
```

### 4.2 Set Up Secrets
```bash
mkdir -p .kamal
touch .kamal/secrets
```
*Creates the secrets directory and file*

## Step 5: Docker Registry Setup

### 5.1 Docker Hub (Free Option)
1. Create Docker Hub account
2. Create repository: `your-username/rails-weather-app`
3. Generate access token for Kamal

### 5.2 Alternative: AWS ECR (Free Tier: 500MB storage)
```bash
aws ecr create-repository --repository-name rails-weather-app --region YOUR_AWS_REGION
```
*Replace YOUR_AWS_REGION with your AWS region (e.g., us-east-1, us-west-2, eu-west-1)*

## Step 6: Deployment Process

### 6.1 Initial Setup
```bash
bin/kamal setup
```
*Sets up Kamal on the server*

### 6.2 Deploy Application
```bash
bin/kamal deploy
```
*Deploys the application*

### 6.3 Verify Deployment
```bash
bin/kamal app logs
bin/kamal app exec "bin/rails runner 'puts Rails.env'"
```
*Check application logs and verify Rails environment*

## Step 7: Access Your Application

Access your application at:
```
http://YOUR_EC2_ELASTIC_IP
```

### Adding SSL Later (Optional)
For production SSL setup:
1. Purchase a domain name
2. Point it to your Elastic IP
3. Update security group to allow HTTPS (port 443)
4. Update `config/deploy.yml` with SSL configuration
5. Redeploy with `bin/kamal deploy`

## Step 8: Monitoring and Maintenance

### 8.1 Useful Kamal Commands
```bash
bin/kamal app logs -f
bin/kamal app exec "bin/rails console"
bin/kamal rollback
bin/kamal server status
```

### 8.2 Health Checks
Kamal includes built-in health checks at `/up` endpoint.

## Best Practices Implemented

1. **Security**: Proper security group configuration
2. **Secrets Management**: Environment variables stored securely
3. **Zero Downtime**: Kamal's rolling deployment strategy
4. **HTTP Deployment**: Production-ready setup
5. **Monitoring**: Built-in health checks and logging
6. **Cost Optimization**: Using AWS Free Tier resources

## Troubleshooting Common Issues

### Docker Permission Issues
```bash
sudo usermod -aG docker ubuntu
```
*Run on EC2 instance, then logout and login again*

### Connection Issues
- Verify security group allows port 80 (HTTP) from 0.0.0.0/0
- Check Elastic IP is correctly associated
- Ensure application is running with `bin/kamal app logs`

### Deployment Failures
```bash
bin/kamal app logs
bin/kamal server status
```

## Cost Breakdown (AWS Free Tier)
- **EC2 t2.micro**: Free (750 hours/month)
- **Storage**: Free (up to 30GB)
- **Data Transfer**: Free (up to 15GB/month)
- **Elastic IP**: Free (1 IP when associated with running instance)

**Estimated Monthly Cost**: $0 (within Free Tier limits)

## Next Steps
- Set up monitoring with CloudWatch (Free Tier: 10 metrics)
- Implement automated backups
- Configure CI/CD pipeline
- Scale horizontally with load balancer

## Conclusion
This tutorial demonstrates a production-ready Rails 8 deployment using Kamal and AWS Free Tier resources, providing zero-downtime deployments with minimal cost and maximum learning value.