# AWS EC2 Setup Guide for Rails 8 + Kamal Deployment

## Prerequisites Checklist
- [ ] AWS Account with Free Tier access
- [ ] Docker Hub account (or AWS ECR)
- [ ] Domain name (optional, can use IP initially)
- [ ] SSH key pair for AWS access

## Step 1: AWS EC2 Instance Setup

### 1.1 Launch EC2 Instance
1. **Go to AWS Console** → EC2 → Launch Instance
2. **Name**: `rails-weather-app`
3. **AMI**: Ubuntu Server 22.04 LTS (Free tier eligible)
4. **Instance Type**: t2.micro (Free tier eligible)
5. **Key Pair**: Create new or select existing
6. **Security Group**: Create new with these rules:

```
Type        Protocol    Port Range    Source          Description
SSH         TCP         22           Your IP         SSH access
HTTP        TCP         80           0.0.0.0/0       Web traffic
HTTPS       TCP         443          0.0.0.0/0       Secure web traffic
```

7. **Storage**: 8GB gp3 (Free tier: up to 30GB)
8. **Launch Instance**

### 1.2 Allocate Elastic IP (Recommended)
1. **EC2 Console** → Elastic IPs → Allocate Elastic IP address
2. **Associate** with your instance
3. **Note the IP** for Kamal configuration

### 1.3 Connect to Instance
```bash
# Replace with your key file and IP
ssh -i your-key.pem ubuntu@YOUR_ELASTIC_IP
```

### 1.4 Run Setup Script
```bash
# Copy the setup script to your instance
scp -i your-key.pem scripts/aws-ec2-setup.sh ubuntu@YOUR_ELASTIC_IP:~/

# Run the setup script
ssh -i your-key.pem ubuntu@YOUR_ELASTIC_IP
chmod +x aws-ec2-setup.sh
./aws-ec2-setup.sh

# Logout and login again for docker group changes
exit
ssh -i your-key.pem ubuntu@YOUR_ELASTIC_IP

# Test Docker installation
docker run hello-world
```

## Step 2: Docker Registry Setup

### Option A: Docker Hub (Recommended for beginners)
1. **Create account** at hub.docker.com
2. **Create repository**: `your-username/weather-app`
3. **Generate access token**:
   - Account Settings → Security → New Access Token
   - Name: `kamal-deployment`
   - Permissions: Read, Write, Delete
   - **Save the token** for secrets configuration

### Option B: AWS ECR (Free tier: 500MB storage)
```bash
# Create ECR repository
aws ecr create-repository --repository-name weather-app --region us-east-1

# Get login token
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

## Step 3: Domain Setup (Optional)

### Option A: Use Existing Domain
1. **Create A record**: `weather.yourdomain.com` → `YOUR_ELASTIC_IP`
2. **Wait for DNS propagation** (up to 48 hours)

### Option B: AWS Route 53 Subdomain
1. **Create hosted zone** ($0.50/month)
2. **Create A record** pointing to Elastic IP

### Option C: Testing Without Domain
- Temporarily disable SSL in deploy configuration
- Access via IP address only

## Step 4: Local Configuration

### 4.1 Update Kamal Configuration
```bash
# Copy production template
cp config/deploy.production.yml config/deploy.yml

# Edit with your details
# - Replace YOUR_DOCKERHUB_USERNAME
# - Replace YOUR_EC2_ELASTIC_IP  
# - Replace YOUR_DOMAIN.com
```

### 4.2 Configure Secrets
```bash
# Copy secrets template
cp .kamal/secrets.example .kamal/secrets

# Edit .kamal/secrets with your actual values:
# - RAILS_MASTER_KEY (from config/master.key)
# - KAMAL_REGISTRY_PASSWORD (Docker Hub access token)
# - WEATHER_API_KEY (from WeatherAPI.com)
```

### 4.3 Add to .gitignore
```bash
echo ".kamal/secrets" >> .gitignore
```

## Step 5: Initial Deployment

### 5.1 Setup Kamal on Server
```bash
# This installs Kamal's proxy and prepares the server
bin/kamal setup
```

### 5.2 Deploy Application
```bash
# Build and deploy the application
bin/kamal deploy
```

### 5.3 Verify Deployment
```bash
# Check application logs
bin/kamal app logs

# Check application status
bin/kamal app details

# Test the application
curl -I http://YOUR_DOMAIN_OR_IP
```

## Step 6: SSL Certificate (Let's Encrypt)

If you configured a domain with `ssl: true`, Kamal automatically:
1. **Requests SSL certificate** from Let's Encrypt
2. **Configures HTTPS redirect**
3. **Auto-renews certificates**

**Troubleshooting SSL**:
- Ensure domain points to your IP
- Check ports 80 and 443 are open
- Verify Let's Encrypt rate limits

## Cost Breakdown (AWS Free Tier)

| Resource | Free Tier Limit | Monthly Cost |
|----------|----------------|--------------|
| EC2 t2.micro | 750 hours | $0 |
| EBS Storage | 30GB | $0 |
| Data Transfer | 15GB out | $0 |
| Elastic IP | 1 IP (when associated) | $0 |
| **Total** | | **$0** |

## Useful Commands

```bash
# View application logs
bin/kamal app logs -f

# Execute Rails console
bin/kamal app exec "bin/rails console"

# Restart application
bin/kamal app restart

# Deploy new version
bin/kamal deploy

# Rollback deployment
bin/kamal rollback

# Check server status
bin/kamal server status

# SSH into server
bin/kamal app exec --interactive --reuse "bash"
```

## Troubleshooting

### Common Issues

**Docker permission denied**:
```bash
# On EC2 instance
sudo usermod -aG docker ubuntu
# Logout and login again
```

**SSL certificate issues**:
- Verify domain DNS settings
- Check security group allows ports 80/443
- Ensure Let's Encrypt rate limits not exceeded

**Deployment failures**:
```bash
# Check detailed logs
bin/kamal app logs --lines 100

# Verify server connectivity
bin/kamal server status

# Check Docker on server
ssh ubuntu@YOUR_IP "docker ps"
```

**Out of memory (t2.micro)**:
- Monitor with `htop` on server
- Consider adding swap space
- Optimize Rails memory usage

## Security Best Practices

1. **Restrict SSH access** to your IP only
2. **Use strong SSH keys** (RSA 4096 or Ed25519)
3. **Keep system updated** regularly
4. **Monitor logs** for suspicious activity
5. **Use secrets management** for sensitive data
6. **Enable CloudTrail** for AWS API logging

## Next Steps

- [ ] Set up monitoring with CloudWatch
- [ ] Configure automated backups
- [ ] Implement CI/CD pipeline
- [ ] Add health checks and alerts
- [ ] Scale horizontally with load balancer

## Resources

- [Kamal Documentation](https://kamal-deploy.org/)
- [AWS Free Tier Details](https://aws.amazon.com/free/)
- [Docker Hub Documentation](https://docs.docker.com/docker-hub/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)