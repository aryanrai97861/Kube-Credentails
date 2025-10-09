#!/bin/bash

# Kube Credentials - AWS Setup Script
# This script helps set up the AWS environment and prerequisites

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Windows (Git Bash/WSL)
check_platform() {
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        print_status "Detected Windows environment (Git Bash)"
        PLATFORM="windows"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -q Microsoft /proc/version 2>/dev/null; then
            print_status "Detected WSL environment"
            PLATFORM="wsl"
        else
            print_status "Detected Linux environment"
            PLATFORM="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        print_status "Detected macOS environment"
        PLATFORM="macos"
    else
        print_warning "Unknown platform: $OSTYPE"
        PLATFORM="unknown"
    fi
}

# Install AWS CLI
install_aws_cli() {
    print_status "Checking AWS CLI installation..."
    
    if command -v aws &> /dev/null; then
        AWS_VERSION=$(aws --version 2>&1 | cut -d/ -f2 | cut -d' ' -f1)
        print_success "AWS CLI is already installed (version: $AWS_VERSION)"
        return 0
    fi
    
    print_status "Installing AWS CLI..."
    
    case $PLATFORM in
        "windows"|"wsl")
            print_status "For Windows, please download and install AWS CLI from:"
            print_status "https://awscli.amazonaws.com/AWSCLIV2.msi"
            print_warning "Please install AWS CLI manually and run this script again."
            exit 1
            ;;
        "macos")
            if command -v brew &> /dev/null; then
                brew install awscli
            else
                print_status "Installing via curl..."
                curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
                sudo installer -pkg AWSCLIV2.pkg -target /
                rm AWSCLIV2.pkg
            fi
            ;;
        "linux")
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install
            rm -rf awscliv2.zip aws/
            ;;
    esac
    
    print_success "AWS CLI installed successfully"
}

# Check Docker installation
check_docker() {
    print_status "Checking Docker installation..."
    
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        print_success "Docker is installed (version: $DOCKER_VERSION)"
        
        # Check if Docker daemon is running
        if docker info &> /dev/null; then
            print_success "Docker daemon is running"
        else
            print_error "Docker daemon is not running. Please start Docker."
            exit 1
        fi
    else
        print_error "Docker is not installed."
        print_status "Please install Docker from: https://www.docker.com/products/docker-desktop"
        exit 1
    fi
}

# Configure AWS CLI
configure_aws() {
    print_status "Checking AWS CLI configuration..."
    
    if aws sts get-caller-identity &> /dev/null; then
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        REGION=$(aws configure get region)
        print_success "AWS CLI is configured"
        print_status "Account ID: $ACCOUNT_ID"
        print_status "Region: $REGION"
        return 0
    fi
    
    print_warning "AWS CLI is not configured"
    print_status "Please run the following command to configure AWS CLI:"
    print_status "aws configure"
    print_status ""
    print_status "You will need:"
    print_status "1. AWS Access Key ID"
    print_status "2. AWS Secret Access Key"
    print_status "3. Default region (recommended: us-east-1 for free tier)"
    print_status "4. Default output format (recommended: json)"
    print_status ""
    print_status "To get AWS credentials:"
    print_status "1. Go to AWS Console → IAM → Users → Your User → Security Credentials"
    print_status "2. Create Access Key → Command Line Interface (CLI)"
    print_status "3. Copy the Access Key ID and Secret Access Key"
    
    read -p "Press Enter after configuring AWS CLI to continue..."
    
    if aws sts get-caller-identity &> /dev/null; then
        print_success "AWS CLI configured successfully"
    else
        print_error "AWS CLI configuration failed"
        exit 1
    fi
}

# Validate AWS permissions
validate_permissions() {
    print_status "Validating AWS permissions..."
    
    # Check required permissions
    REQUIRED_SERVICES=(
        "ecs"
        "ecr"
        "ec2"
        "elasticloadbalancing"
        "iam"
        "cloudformation"
        "logs"
        "efs"
        "application-autoscaling"
    )
    
    for service in "${REQUIRED_SERVICES[@]}"; do
        print_status "Checking $service permissions..."
        case $service in
            "ecs")
                aws ecs list-clusters --region us-east-1 &> /dev/null || {
                    print_error "Missing ECS permissions"
                    exit 1
                }
                ;;
            "ecr")
                aws ecr describe-repositories --region us-east-1 &> /dev/null || {
                    print_error "Missing ECR permissions"
                    exit 1
                }
                ;;
            "ec2")
                aws ec2 describe-vpcs --region us-east-1 &> /dev/null || {
                    print_error "Missing EC2 permissions"
                    exit 1
                }
                ;;
            "cloudformation")
                aws cloudformation list-stacks --region us-east-1 &> /dev/null || {
                    print_error "Missing CloudFormation permissions"
                    exit 1
                }
                ;;
        esac
    done
    
    print_success "All required permissions validated"
}

# Create environment configuration
create_env_config() {
    print_status "Creating environment configuration..."
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    REGION=$(aws configure get region)
    
    cat > aws/.env << EOF
# AWS Configuration
AWS_ACCOUNT_ID=$ACCOUNT_ID
AWS_REGION=$REGION
PROJECT_NAME=kube-credentials
ENVIRONMENT=production

# Docker Configuration
ISSUER_IMAGE_URI=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/kube-credentials-issuer
VERIFIER_IMAGE_URI=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/kube-credentials-verifier
FRONTEND_IMAGE_URI=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/kube-credentials-frontend

# ECS Configuration
ECS_CLUSTER_NAME=kube-credentials-cluster
ECS_SERVICE_DESIRED_COUNT=1
ECS_TASK_CPU=256
ECS_TASK_MEMORY=512

# Load Balancer Configuration
ALB_SCHEME=internet-facing
ALB_TYPE=application

# Auto Scaling Configuration
MIN_CAPACITY=1
MAX_CAPACITY=3
TARGET_CPU_UTILIZATION=70
EOF
    
    print_success "Environment configuration created at aws/.env"
}

# Check free tier limits
check_free_tier() {
    print_status "Checking AWS Free Tier eligibility..."
    
    ACCOUNT_AGE=$(aws support describe-cases --max-items 1 2>/dev/null | jq -r '.cases[0].timeCreated // "unknown"' || echo "unknown")
    
    print_warning "Important Free Tier Information:"
    print_status "• ECS Fargate: 400,000 vCPU seconds and 800,000 memory seconds per month"
    print_status "• Application Load Balancer: 750 hours per month"
    print_status "• ECR: 500 MB-month of storage"
    print_status "• CloudWatch Logs: 5 GB of ingestion, 5 GB of archive, 3 dashboards"
    print_status "• EFS: 5 GB of storage"
    print_status ""
    print_warning "This deployment uses minimal resources but may incur small charges after free tier limits."
    print_status "Estimated monthly cost (after free tier): $5-15 USD"
    print_status ""
    
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Setup cancelled by user"
        exit 0
    fi
}

# Generate parameter files
generate_parameter_files() {
    print_status "Generating CloudFormation parameter files..."
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    REGION=$(aws configure get region)
    
    # Infrastructure parameters
    cat > aws/parameters/infrastructure-params.json << EOF
[
  {
    "ParameterKey": "ProjectName",
    "ParameterValue": "kube-credentials"
  },
  {
    "ParameterKey": "Environment",
    "ParameterValue": "production"
  }
]
EOF
    
    # Services parameters
    cat > aws/parameters/services-params.json << EOF
[
  {
    "ParameterKey": "ProjectName",
    "ParameterValue": "kube-credentials"
  },
  {
    "ParameterKey": "Environment",
    "ParameterValue": "production"
  },
  {
    "ParameterKey": "IssuerImageURI",
    "ParameterValue": "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/kube-credentials-issuer:latest"
  },
  {
    "ParameterKey": "VerifierImageURI",
    "ParameterValue": "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/kube-credentials-verifier:latest"
  },
  {
    "ParameterKey": "FrontendImageURI",
    "ParameterValue": "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/kube-credentials-frontend:latest"
  }
]
EOF
    
    print_success "Parameter files generated"
}

# Main setup function
main() {
    print_status "🚀 Starting AWS setup for Kube Credentials"
    
    check_platform
    install_aws_cli
    check_docker
    configure_aws
    validate_permissions
    check_free_tier
    create_env_config
    generate_parameter_files
    
    print_success "✅ AWS setup completed successfully!"
    print_status ""
    print_status "Next steps:"
    print_status "1. Review the configuration in aws/.env"
    print_status "2. Run './aws/scripts/deploy.sh' to deploy to AWS"
    print_status "3. Run './aws/scripts/deploy.sh destroy' to clean up resources"
    print_status ""
    print_warning "Remember to destroy resources when not in use to avoid charges:"
    print_status "./aws/scripts/deploy.sh destroy"
}

# Run main function
main