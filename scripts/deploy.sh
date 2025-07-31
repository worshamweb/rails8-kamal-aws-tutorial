#!/bin/bash
# Quick deployment script for Rails 8 + Kamal

set -e

echo "🚀 Starting Rails 8 + Kamal deployment..."

# Check if secrets file exists
if [ ! -f ".kamal/secrets" ]; then
    echo "❌ Error: .kamal/secrets file not found!"
    echo "Please copy .kamal/secrets.example to .kamal/secrets and fill in your values."
    exit 1
fi

# Check if deploy.yml is configured
if grep -q "YOUR_" config/deploy.yml; then
    echo "❌ Error: config/deploy.yml contains placeholder values!"
    echo "Please update config/deploy.yml with your actual configuration."
    exit 1
fi

# Verify Docker is running locally
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running locally!"
    echo "Please start Docker and try again."
    exit 1
fi

echo "✅ Pre-flight checks passed!"

# Build and deploy
echo "🔨 Building and deploying application..."
bin/kamal deploy

echo "🎉 Deployment complete!"
echo ""
echo "Useful commands:"
echo "  bin/kamal app logs -f    # View application logs"
echo "  bin/kamal app details    # Check application status"
echo "  bin/kamal rollback       # Rollback if needed"