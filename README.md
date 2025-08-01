# Rails 8 + Kamal + AWS EC2 Deployment Tutorial

> **Complete guide to deploying a Rails 8 application to AWS EC2 using Kamal with zero-downtime deployments, SSL certificates, and AWS Free Tier optimization.**

## 🎯 Tutorial Overview

This repository contains a complete tutorial for deploying a Rails 8 weather application to AWS EC2 using Kamal, Rails 8's built-in deployment tool. The tutorial includes a working Rails app, comprehensive deployment guides, and automation scripts. Everything stays within AWS Free Tier limits.

## 📋 What You'll Learn

- ✅ Setting up AWS EC2 for Rails deployment
- ✅ Configuring Kamal for zero-downtime deployments  
- ✅ Managing secrets and environment variables securely
- ✅ Automatic SSL certificate management with Let's Encrypt
- ✅ Docker containerization best practices
- ✅ Production monitoring and troubleshooting
- ✅ Cost optimization with AWS Free Tier

## 🚀 Quick Start

### Prerequisites
- AWS Account with Free Tier access
- Docker installed locally
- Docker Hub account (free)
- Domain name (optional)

### 1. Clone and Setup
```bash
git clone https://github.com/worshamweb/rails8-kamal-aws-tutorial.git
cd rails8-kamal-aws-tutorial
bundle install
rails db:prepare
```

### 2. Follow Setup Guides
1. **[AWS Setup Guide](AWS_SETUP_GUIDE.md)** - Complete AWS EC2 configuration
2. **[Kamal Deployment Tutorial](KAMAL_DEPLOYMENT_TUTORIAL.md)** - Detailed deployment walkthrough

### 3. Quick Deploy
```bash
# Configure your settings
cp config/deploy.production.yml config/deploy.yml
cp .kamal/secrets.example .kamal/secrets

# Edit files with your details, then deploy
./scripts/deploy.sh
```

## 📁 Repository Structure

```
rails8-kamal-aws-tutorial/
├── README.md                       # This overview (start here!)
├── KAMAL_DEPLOYMENT_TUTORIAL.md    # Complete step-by-step tutorial
├── AWS_SETUP_GUIDE.md              # AWS EC2 setup guide
├── WEATHER_APP_README.md           # Weather app documentation
├── config/
│   ├── deploy.yml                  # Kamal configuration
│   └── deploy.production.yml       # Production template
├── scripts/
│   ├── aws-ec2-setup.sh           # EC2 server setup
│   └── deploy.sh                  # Quick deployment
├── .kamal/
│   └── secrets.example            # Secrets template
├── Dockerfile                     # Production container
└── [Rails app files...]           # Complete weather app
```

## 💰 Cost Breakdown (AWS Free Tier)

| Resource | Free Tier Limit | Monthly Cost |
|----------|----------------|--------------|
| EC2 t2.micro | 750 hours | **$0** |
| EBS Storage | 30GB | **$0** |
| Data Transfer | 15GB out | **$0** |
| Elastic IP | 1 IP (when associated) | **$0** |
| **Total** | | **$0** |

## 🛠 Key Features Demonstrated

### Kamal Configuration
- Zero-downtime deployments
- Automatic SSL with Let's Encrypt
- Health checks and monitoring
- Asset bridging between deployments
- Docker image optimization

### AWS Best Practices
- Security group configuration
- Elastic IP management
- Cost optimization
- Monitoring setup
- Backup strategies

### Production Readiness
- Environment variable management
- Secret handling
- Log rotation
- Error monitoring
- Performance optimization

## 📚 Tutorial Documentation

### 🚀 [Start Here: Complete Tutorial](KAMAL_DEPLOYMENT_TUTORIAL.md)
The main tutorial with step-by-step instructions for the entire deployment process.

### ☁️ [AWS Setup Guide](AWS_SETUP_GUIDE.md)
Detailed AWS EC2 configuration, security groups, and server preparation.

### 🌤️ [Weather App Documentation](WEATHER_APP_README.md)
Information about the Rails weather application used in this tutorial.

### 📂 Key Configuration Files
- [`config/deploy.yml`](config/deploy.yml) - Main Kamal configuration
- [`config/deploy.production.yml`](config/deploy.production.yml) - Production template
- [`.kamal/secrets.example`](.kamal/secrets.example) - Secrets configuration template
- [`scripts/aws-ec2-setup.sh`](scripts/aws-ec2-setup.sh) - Automated server setup
- [`scripts/deploy.sh`](scripts/deploy.sh) - Quick deployment script

## 🔧 Useful Commands

```bash
# Deploy application
bin/kamal deploy

# View logs
bin/kamal app logs -f

# Execute Rails console
bin/kamal console

# Check application status
bin/kamal app details

# Rollback deployment
bin/kamal rollback

# SSH into server
bin/kamal shell
```

## 🐛 Troubleshooting

### Common Issues
- **Docker permission errors**: Ensure user is in docker group
- **SSL certificate issues**: Verify domain DNS and security groups
- **Memory issues on t2.micro**: Monitor usage and optimize Rails
- **Deployment failures**: Check logs with `bin/kamal app logs`

### Getting Help
1. Check the [troubleshooting section](AWS_SETUP_GUIDE.md#troubleshooting)
2. Review Kamal logs: `bin/kamal app logs --lines 100`
3. Verify server status: `bin/kamal server status`

## 🎓 Learning Outcomes

After completing this tutorial, you'll understand:

- **Kamal fundamentals**: Configuration, deployment, and management
- **AWS EC2 deployment**: Best practices for Rails applications
- **Docker containerization**: Production-ready container setup
- **SSL/TLS management**: Automatic certificate handling
- **Cost optimization**: Maximizing AWS Free Tier benefits
- **Production monitoring**: Health checks and logging
- **Security practices**: Secrets management and server hardening

## 🔗 Additional Resources

- [Kamal Official Documentation](https://kamal-deploy.org/)
- [Rails 8 Release Notes](https://guides.rubyonrails.org/8_0_release_notes.html)
- [AWS Free Tier Details](https://aws.amazon.com/free/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)

## 🤝 Contributing

This tutorial is designed to be a learning resource. If you find improvements or have suggestions:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request with your improvements

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

**Happy Deploying! 🚀**

*This tutorial demonstrates real-world Rails 8 deployment practices using modern tools and AWS Free Tier resources.*