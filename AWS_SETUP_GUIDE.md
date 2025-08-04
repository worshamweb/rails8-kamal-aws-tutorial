# AWS EC2 Setup Guide for Rails 8 + Kamal Deployment

## Prerequisites Checklist
- [ ] AWS Account with Free Tier access
- [ ] AWS CLI installed and configured with your credentials - [Setup guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html)
- [ ] AWS Elastic Container Registry (or Docker Hub account as alternative)
- [ ] SSH key pair for AWS access

## Step 1: AWS EC2 Instance Setup

### 1.1 Launch EC2 Instance
1. **Go to AWS Console** → EC2 → Launch Instance
2. **Name**: `rails-weather-app`
3. **AMI**: Ubuntu Server 22.04 LTS (Free tier eligible)
   - *Note: While Amazon Linux 2023 is the default, we use Ubuntu because it's more familiar to most Rails developers and widely used in the Rails community*
4. **Instance Type**: t2.micro (Free tier eligible)
5. **Key Pair**: Create new or select existing
   - **If creating new:**
     - Name: `rails-weather-app-key`
     - Type: **ED25519** (more secure than RSA)
     - Format: **.pem** (for Mac/Linux/WSL)
     - **Important**: Download and save the .pem file securely - you cannot download it again
     - **Secure the key file (run on your local machine):**
       ```bash
       mkdir -p ~/.ssh
       mv ~/Downloads/rails-weather-app-key.pem ~/.ssh/
       chmod 400 ~/.ssh/rails-weather-app-key.pem
       ```
       *These commands create the .ssh directory, move the key file, and set secure permissions*
     - **Note**: On Windows, use WSL (Windows Subsystem for Linux) or Git Bash for these commands
6. **Security Group**: Configure network access rules:
   - **"Allow SSH traffic from"**: Keep checked (default), change dropdown from "Anywhere" to **"My IP"** for better security
   - **"Allow HTTP traffic from the internet"**: **Check this box** (needed for web traffic)
   - *Note: You'll see a warning about 0.0.0.0/0 access for HTTP - this is expected for a public web server.*

7. **Storage**: 8GB gp3 (Free tier: up to 30GB)
8. **Launch Instance**

### 1.2 Allocate Elastic IP (Recommended)

By default, EC2 instances get a new public IP address every time they restart, which would break your deployment and require updating DNS records. An Elastic IP provides a static IP address that stays with your instance.

1. **Navigate back to EC2 Console** (click "EC2" link in upper left if not already there)
2. **Click "Elastic IPs"** in the Resources section
3. **Click "Allocate Elastic IP address"** (yellow button in upper right)
4. **Click "Allocate"** to create the IP address
5. **Select the new Elastic IP** by checking its box
6. **Click "Actions"** menu → **"Associate Elastic IP address"**
7. **Verify settings on Associate page:**
   - Resource type: **Instance** (should be default)
   - Instance: Select **rails-weather-app** from dropdown
8. **Click "Associate"**
9. **Note the Elastic IP address** for Kamal configuration (found under "Allocated IPv4 address" column in the Elastic IP addresses console)

*Note: Elastic IPs are free when associated with a running instance (within your EC2 Free Tier hours), but cost $0.005/hour if unassociated or if your Free Tier expires.*

### 1.3 Connect to Instance
**Run on your local machine:**
```bash
ssh -i ~/.ssh/rails-weather-app-key.pem ubuntu@YOUR_ELASTIC_EC2_IP
```
*Replace YOUR_ELASTIC_EC2_IP with your actual Elastic IP address*

### 1.4 Run Setup Script
**Copy the setup script to your instance (run on your local machine):**
```bash
scp -i ~/.ssh/rails-weather-app-key.pem scripts/aws-ec2-setup.sh ubuntu@YOUR_ELASTIC_EC2_IP:~/
```

**Connect to EC2 and run the setup script (run on your local machine to connect, then commands execute on EC2):**
```bash
ssh -i ~/.ssh/rails-weather-app-key.pem ubuntu@YOUR_ELASTIC_EC2_IP
chmod +x aws-ec2-setup.sh
./aws-ec2-setup.sh
exit
```

**What the setup script does (this will take 3-5 minutes):**
- Updates the Ubuntu system packages
- Installs Docker and Docker Compose
- Adds the ubuntu user to the docker group
- Starts and enables the Docker service
- Downloads and installs any additional dependencies

*You'll see lots of output scrolling by - this is normal! The script will show "Reading package lists...", "Setting up...", and similar messages. Wait for it to complete and return you to the command prompt before proceeding.*

**Reconnect and test Docker (run on your local machine to connect, then commands execute on EC2):**
```bash
ssh -i ~/.ssh/rails-weather-app-key.pem ubuntu@YOUR_ELASTIC_EC2_IP
docker run hello-world
```
*Note: You need to logout and login again for Docker group changes to take effect*

**If you get "permission denied" error:**
This means the Docker group changes haven't taken effect yet. Run these commands while connected to your EC2 instance:
```bash
sudo usermod -aG docker ubuntu
newgrp docker
docker run hello-world
```
*The `newgrp docker` command applies the group change without requiring a full logout/login*

## Step 2: Docker Registry Setup

AWS Elastic Container Registry (ECR) is a secure, managed Docker registry service that integrates seamlessly with your AWS infrastructure. Using ECR is considered a best practice when deploying to AWS EC2 because it keeps your container images within your AWS environment, provides better security through IAM integration, and eliminates external dependencies. While you could use Docker Hub, ECR offers superior security and performance for AWS deployments.

### Option A: AWS ECR (Recommended - Best Practice)

**Important: All commands in this section should be run in a terminal on your local machine, not in the SSH session with your EC2 instance.**

**Find your AWS region and account ID (run on your local machine):**
```bash
aws configure get region
aws sts get-caller-identity --query Account --output text
```

**Create ECR repository (run on your local machine):**
```bash
aws ecr create-repository --repository-name rails-weather-app --region YOUR_AWS_REGION
```

**Get login token (run on your local machine):**
```bash
aws ecr get-login-password --region YOUR_AWS_REGION | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.YOUR_AWS_REGION.amazonaws.com
```
*Note: Replace YOUR_ACCOUNT_ID with your actual AWS account ID and YOUR_AWS_REGION with your AWS region (e.g., us-east-1, us-west-2, eu-west-1). This login will be automated in Kamal configuration.*

### Option B: Docker Hub (Alternative)
1. **Create account** at hub.docker.com
2. **Create repository**: `your-username/rails-weather-app`
3. **Generate access token**:
   - Account Settings → Security → New Access Token
   - Name: `kamal-deployment`
   - Permissions: Read, Write, Delete
   - **Save the token** for secrets configuration

## Step 3: Prepare Rails App for Deployment

**Important: All commands in this section should be run on your local machine in the Rails project directory, NOT in the SSH session with your EC2 instance.**

### 3.1 Fix Common File Permission and Directory Issues
**Run on your local machine in the Rails project directory:**
```bash
mkdir -p log storage
touch log/.keep storage/.keep
chmod +x bin/docker-entrypoint
chmod +x bin/kamal
```

**What this does:**
- Creates `log` and `storage` directories that Docker expects
- Adds `.keep` files so Git tracks empty directories
- Makes the Docker entrypoint script executable
- Makes the Kamal executable script executable

**Commit these changes:**
```bash
git add log/.keep storage/.keep bin/docker-entrypoint bin/kamal
git commit -m "Prepare app for Kamal deployment"
```

## Step 4: Local Configuration

**Important: All commands in this section should be run on your local machine in the Rails project directory, NOT in the SSH session with your EC2 instance.**

### 4.1 Update Kamal Configuration
**Copy the production template to create your deployment configuration (run on your local machine in the Rails project directory):**
```bash
cp config/deploy.production.yml config/deploy.yml
```

**Then edit the newly created `config/deploy.yml` file to replace these placeholder values:**

**For ECR (recommended):**
- The `image:` field should already be set to `rails-weather-app` (just the repository name)
- Replace `YOUR_ELASTIC_EC2_IP` with your actual Elastic IP address
- In the `registry:` section, replace `server:` with: `YOUR_ACCOUNT_ID.dkr.ecr.YOUR_AWS_REGION.amazonaws.com`
- Keep `username: AWS` for ECR

**For Docker Hub (alternative):**
- Change `image:` to: `YOUR_DOCKERHUB_USERNAME/rails-weather-app`
- Replace `YOUR_ELASTIC_EC2_IP` with your actual Elastic IP address
- In the `registry:` section, comment out the `server:` line (Docker Hub is the default)
- Change `username:` to your Docker Hub username

*Note: We copy the template file `deploy.production.yml` to create `deploy.yml`, which is the file Kamal actually uses for deployment. You'll be editing `config/deploy.yml`, not the template file.*

### 4.1.1 Understanding Our Configuration Customizations

This tutorial's Kamal configuration includes several customizations beyond the default Rails 8 Kamal setup. If you're applying these techniques to a new Rails app, here are the key modifications:

**AWS EC2 Optimizations:**
- **Extended health check timeout** (`proxy.healthcheck.timeout: 60s`) - t2.micro instances need more time for Rails to boot
- **Resource limits** (`WEB_CONCURRENCY: 1`, `RAILS_MAX_THREADS: 5`) - Optimized for t2.micro's single CPU
- **SSH configuration** - Explicit SSH user and key path for Ubuntu AMI

**ECR Integration:**
- **Registry server specification** - Required for ECR (Docker Hub doesn't need this)
- **Username: AWS** - ECR uses "AWS" as username, not your AWS account name
- **Image naming** - Just repository name for ECR, not full URL

**Production Readiness:**
- **Persistent volumes** - SQLite database and storage persistence
- **Asset bridging** - Zero-downtime deployments with asset continuity
- **Useful aliases** - Common commands for debugging and management
- **Environment variables** - Production logging and Rails optimizations

**To replicate in a new Rails app:**
1. Run `bin/kamal init` to generate default config
2. Apply the customizations above based on your deployment target
3. Adjust resource limits based on your instance size
4. Configure registry settings for your chosen Docker registry

### 4.2 Configure Secrets
**Copy the secrets template to create your secrets configuration (run on your local machine in the Rails project directory):**
```bash
cp .kamal/secrets.example .kamal/secrets
```

**Then edit the newly created `.kamal/secrets` file by replacing the placeholder values:**
- Replace `your_rails_master_key_here` with the contents of `config/master.key`
- Replace `your_registry_password_here` with:
  - **For ECR (recommended):** Get your login token by running on your local machine: `aws ecr get-login-password --region YOUR_AWS_REGION`
  - **For Docker Hub:** Use your access token from hub.docker.com (Account Settings → Security → New Access Token)

**What is the Rails Master Key?**
The Rails Master Key encrypts your application's credentials and secrets. It's automatically created when you run `rails new` and stored in `config/master.key`. This file should never be committed to version control.

*Note: We copy the template file `secrets.example` to create `secrets`, which is the file Kamal actually uses for sensitive configuration. You'll be editing `.kamal/secrets`, not the template file.*

### 3.3 Add to .gitignore
**Run on your local machine in the Rails project directory:**
```bash
echo ".kamal/secrets" >> .gitignore
```

**What does .gitignore do?**
The `.gitignore` file tells Git which files and directories to ignore when committing code to your repository. By adding `.kamal/secrets` to `.gitignore`, we ensure that your secrets file (containing sensitive information like API keys and passwords) is never accidentally committed to version control.

**Why is this important for security?**
- **Public repositories**: If you push your code to GitHub, GitLab, or other public repositories, your secrets would be visible to anyone
- **Private repositories**: Even in private repos, secrets in version control can be accessed by anyone with repository access
- **Git history**: Once committed, secrets remain in Git history even if you delete them later
- **Best practice**: Secrets should be managed separately from code and injected at deployment time

## Step 5: Initial Deployment

**Important: All commands in this section should be run on your local machine in the Rails project directory, NOT in the SSH session with your EC2 instance.**

### 5.1 Setup Kamal on Server
**Run on your local machine in the Rails project directory:**
```bash
bin/kamal setup
```

**If you get "Permission denied" error:**
The Kamal executable might not have execute permissions. Fix this by running:
```bash
chmod +x bin/kamal
bin/kamal setup
```

**If you get "Permission denied" error:**
The Kamal executable might not have execute permissions. Fix this by running:
```bash
chmod +x bin/kamal
bin/kamal setup
```

**What this command does:**
- Installs Traefik (the reverse proxy) as a Docker container on your EC2 instance
- Creates necessary Docker networks for container communication
- Sets up volume mounts for persistent data storage
- Configures the proxy to route HTTP traffic to your Rails application
- Prepares the server environment for zero-downtime deployments

*This is a one-time setup process that prepares your server for Kamal deployments*

### 5.2 Deploy Application
**Run on your local machine in the Rails project directory:**
```bash
bin/kamal deploy
```

**What this command does:**
- Builds your Rails application into a Docker image
- Pushes the image to your Docker registry (ECR or Docker Hub)
- Pulls the image to your EC2 instance
- Starts a new container with your Rails application
- Updates the proxy to route traffic to the new container
- Removes the old container (enabling zero-downtime deployment)

*This process typically takes 2-5 minutes depending on your application size and internet speed*

### 5.3 Verify Deployment
**Run on your local machine in the Rails project directory:**
```bash
bin/kamal app logs
bin/kamal app details
curl -I http://YOUR_ELASTIC_EC2_IP
```
*These commands check logs, status, and test the application*



## Step 6: Access Your Application

Your Rails application should now be accessible at:
```
http://YOUR_ELASTIC_EC2_IP
```

**Test the deployment:**
```bash
curl http://YOUR_ELASTIC_EC2_IP
```

## Making This Production-Ready

This tutorial creates a functional Rails deployment, but for production use, consider these enhancements:

### 1. Domain Name and SSL
**Purchase a domain name** and configure DNS:
- Buy domain from registrar (Namecheap, GoDaddy, etc.)
- Create A record pointing to your Elastic IP
- Or use AWS Route 53 for DNS management ($0.50/month per hosted zone)

**Enable SSL in Kamal configuration:**
```yaml
proxy:
  ssl: true
  host: yourdomain.com
```

**Update security group** to allow HTTPS traffic (port 443)

### 2. Enhanced Security
**Restrict IP access** in security groups:
- SSH: Only your office/home IP addresses
- HTTP/HTTPS: Consider CloudFlare or AWS WAF for DDoS protection

**Example restricted security group:**
```
Type    Protocol  Port  Source
SSH     TCP       22    203.0.113.0/24  # Your office network
HTTP    TCP       80    0.0.0.0/0        # Public web traffic
HTTPS   TCP       443   0.0.0.0/0        # Public web traffic
```

### 3. Monitoring and Alerting
**AWS CloudWatch** (Free Tier: 10 metrics, 1 million API requests):
- CPU utilization alerts
- Memory usage monitoring
- Disk space alerts
- Application error tracking

**Log aggregation:**
- Centralized logging with AWS CloudWatch Logs
- Application performance monitoring (APM)

### 4. Backup Strategy
**Database backups:**
- Automated EBS snapshots
- Regular database dumps to S3
- Test restore procedures

**Application backups:**
- Code in version control (Git)
- Environment configuration backups
- Docker image versioning

### 5. Scaling Considerations
**Vertical scaling** (when Free Tier expires):
- Upgrade to t3.small or larger instances
- Add more storage as needed

**Horizontal scaling:**
- Application Load Balancer (ALB)
- Multiple EC2 instances
- RDS for managed database
- ElastiCache for Redis/Memcached

### 6. Cost Optimization
**Beyond Free Tier:**
- Reserved Instances for predictable workloads
- Spot Instances for development/testing
- S3 for static assets and backups
- CloudFront CDN for global content delivery

## Cost Breakdown (AWS Free Tier)

| Resource | Free Tier Limit | Monthly Cost |
|----------|----------------|--------------|
| EC2 t2.micro | 750 hours (~31 days) | $0 |
| EBS Storage | 30GB | $0 |
| Data Transfer | 15GB out | $0 |
| Elastic IP | 1 IP free (when associated) | $0 |
| **Total** | | **$0** |

**Important**: If you're running this for demonstration/learning purposes, always stop your EC2 instance and release the Elastic IP when finished to avoid accidental charges. The Free Tier has monthly limits, and resources left running can exceed those limits or incur charges if your Free Tier expires.

**To clean up resources:**
1. Stop EC2 instance: AWS Console → EC2 → Instances → Stop
2. Release Elastic IP: AWS Console → EC2 → Elastic IPs → Release
3. Delete ECR repository: `aws ecr delete-repository --repository-name rails-weather-app --force`

## Useful Commands

```bash
bin/kamal app logs -f
bin/kamal app exec "bin/rails console"
bin/kamal app restart
bin/kamal deploy
bin/kamal rollback
bin/kamal server status
bin/kamal app exec --interactive --reuse "bash"
```

## Common Issues

*These are environment-specific issues you might encounter, not specific to this tutorial:*

### Kamal Configuration Errors

**"unknown keys: healthcheck, traefik" error:**
Legacy Kamal configuration from older versions. Remove deprecated keys:
- `healthcheck:` (now handled automatically)
- `traefik:` (replaced by Kamal's built-in proxy)
- Complex `proxy:` configurations

### Docker Permission Issues

**Error you might see:**
```
ERROR (SSHKit::Command::Failed): docker exit status: 256
docker stderr: permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock
```

**Local Docker permission denied:**
Your local user needs Docker access to build images.

**Run on your local machine:**
```bash
sudo usermod -aG docker $USER
newgrp docker
```
*May require logout/login on some systems*

**EC2 Docker permission denied:**
The ubuntu user on EC2 needs Docker access.

**Run on EC2 instance (SSH into EC2 first):**
```bash
ssh -i ~/.ssh/rails-weather-app-key.pem ubuntu@YOUR_ELASTIC_EC2_IP
sudo usermod -aG docker ubuntu
newgrp docker
exit
```

### SSH Authentication Issues

**Error you might see:**
```
ERROR (SSHKit::Command::Failed): Authentication failed for user ubuntu@YOUR_IP
```

**Problem:** Kamal can't connect to your EC2 instance
**Solutions:**
- Verify SSH key path in `config/deploy.yml`
- Test manual connection from your local machine:
  
  **Run on your local machine:**
  ```bash
  ssh -i ~/.ssh/rails-weather-app-key.pem ubuntu@YOUR_ELASTIC_EC2_IP
  ```
- Ensure EC2 instance is running

### Registry Authentication Issues

**Error you might see:**
```
ERROR: failed to solve: failed to push: authentication required
```
or
```
ERROR: denied: User: arn:aws:sts::ACCOUNT:assumed-role is not authorized to perform: ecr:BatchCheckLayerAvailability
```
or
```
ERROR: The repository with name 'ACCOUNT.dkr.ecr.REGION.amazonaws.com/rails-weather-app' does not exist
```

**Problem:** Can't push/pull Docker images or incorrect ECR configuration
**Solutions:**

**For ECR repository not found error:**
Check your `config/deploy.yml` configuration. The `image:` should be just the repository name, not the full URL:

```yaml
# CORRECT:
image: rails-weather-app
registry:
  server: YOUR_ACCOUNT_ID.dkr.ecr.YOUR_AWS_REGION.amazonaws.com
  username: AWS

# INCORRECT:
image: YOUR_ACCOUNT_ID.dkr.ecr.YOUR_AWS_REGION.amazonaws.com/rails-weather-app
```

**Verify ECR repository exists:**

**Run on your local machine:**
```bash
aws ecr describe-repositories --repository-names rails-weather-app --region YOUR_AWS_REGION
```

**For ECR - refresh login token:**

**Run on your local machine:**
```bash
aws ecr get-login-password --region YOUR_AWS_REGION | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.YOUR_AWS_REGION.amazonaws.com
```

**For Docker Hub - verify login:**

**Run on your local machine:**
```bash
docker login
```

- For ECR: Ensure `username: AWS` and correct server URL in deploy.yml
- For Docker Hub: Verify access token (not password) in .kamal/secrets
- Check registry server configuration matches image URL

### Docker Build Issues

**Error you might see:**
```
chown: cannot access 'log': No such file or directory
chown: cannot access 'storage': No such file or directory
ERROR: failed to build: process did not complete successfully: exit code 1
```

**Problem:** Rails app missing required directories for Docker build
**Solution:** Create missing directories in your Rails app

**Run on your local machine:**
```bash
mkdir -p log storage
touch log/.keep storage/.keep
git add log/.keep storage/.keep
git commit -m "Add missing log and storage directories"
```

### Docker Container Permission Issues

**Error you might see:**
```
docker: Error response from daemon: failed to create task for container: 
exec: "/rails/bin/docker-entrypoint": permission denied
```

**Problem:** Docker entrypoint script lacks execute permissions
**Solution:** Fix entrypoint permissions in Dockerfile

**Run on your local machine:**
```bash
chmod +x bin/docker-entrypoint
git add bin/docker-entrypoint
git commit -m "Fix docker-entrypoint permissions"
```

Then rebuild and redeploy:
```bash
bin/kamal deploy
```

### Health Check Timeout Issues

**Error you might see:**
```
ERROR (SSHKit::Command::Failed): docker exit status: 1
docker stderr: Error: target failed to become healthy within configured timeout (30s)
```

**Problem:** Rails app takes longer than 30 seconds to start up
**Solutions:**

**Check what's happening:**

**Run on your local machine:**
```bash
bin/kamal app logs --lines 50
```

**Common causes:**
- **Database migration needed:** App waiting for database setup
- **Memory issues on t2.micro:** Rails using too much memory
- **Missing environment variables:** App failing to start due to config issues
- **Asset compilation:** Taking too long during startup

**If it's a slow startup, you can increase the timeout in deploy.yml:**
```yaml
# Add this to your deploy.yml
proxy:
  healthcheck:
    timeout: 60  # Increase from default 30 (seconds)
```

**Note:** If you've already deployed and are changing the timeout, you may need to restart the proxy:

**Run on your local machine:**
```bash
bin/kamal proxy restart
bin/kamal deploy
```

### General Deployment Issues

**Error you might see:**
```
ERROR (SSHKit::Command::Failed): Health check failed
```
or
```
ERROR: Container rails-weather-app-web-latest exited with status 1
```

**Out of memory on t2.micro:**
- Monitor with `htop` on server
- Consider adding swap space
- Optimize Rails memory usage

**Deployment failures:**

**Run on your local machine:**
```bash
bin/kamal app logs --lines 100
bin/kamal server status
```

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