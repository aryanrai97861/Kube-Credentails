# AWS Deployment Guide for Kube Credentials

This guide will help you deploy the Kube Credentials application to AWS using ECS Fargate, taking advantage of the AWS Free Tier.

## 📋 Prerequisites

Before starting, ensure you have:

1. **AWS Account**: A valid AWS account (preferably within the 12-month free tier period)
2. **AWS CLI**: Installed and configured with appropriate permissions
3. **Docker**: Installed and running on your local machine
4. **Git Bash/WSL**: If you're on Windows

## 🏗️ Architecture Overview

The deployment includes:

- **Amazon ECS Fargate**: Serverless container hosting
- **Application Load Balancer**: Route traffic between services
- **Amazon ECR**: Docker image registry
- **Amazon EFS**: Persistent file storage for databases
- **CloudWatch**: Logging and monitoring
- **Auto Scaling**: Automatic scaling based on CPU usage
- **VPC**: Secure network isolation

## 💰 Cost Estimation

### Free Tier Resources (First 12 months):
- **ECS Fargate**: 400,000 vCPU seconds + 800,000 memory seconds/month
- **ALB**: 750 hours/month
- **ECR**: 500 MB storage/month
- **CloudWatch Logs**: 5 GB ingestion + 5 GB archive/month
- **EFS**: 5 GB storage/month

### Estimated Monthly Cost (after free tier):
- **Small usage**: $5-10 USD/month
- **Medium usage**: $10-20 USD/month

## 🚀 Quick Start

### Step 1: Setup AWS Environment

```bash
# Make scripts executable
chmod +x aws/scripts/*.sh

# Run the setup script
./aws/scripts/setup.sh
```

This script will:
- Check and install AWS CLI (if needed)
- Verify Docker installation
- Configure AWS credentials
- Validate required permissions
- Create environment configuration files

### Step 2: Deploy to AWS

```bash
# Deploy the complete application
./aws/scripts/deploy.sh
```

This will:
- Deploy infrastructure (VPC, ALB, ECS cluster, ECR repositories)
- Build and push Docker images to ECR
- Deploy ECS services
- Wait for services to become healthy
- Run basic health checks

### Step 3: Access Your Application

After successful deployment, you'll see output like:

```
✅ Deployment completed successfully!
🌐 Application URL: http://kube-alb-xxxxxxxx.us-east-1.elb.amazonaws.com

Services:
• Frontend: http://kube-alb-xxxxxxxx.us-east-1.elb.amazonaws.com
• Issuer API: http://kube-alb-xxxxxxxx.us-east-1.elb.amazonaws.com/api/issue
• Verifier API: http://kube-alb-xxxxxxxx.us-east-1.elb.amazonaws.com/api/verify
```

## 🔧 Management Commands

### Update Services (after code changes)
```bash
./aws/scripts/deploy.sh update
```

### Destroy All Resources
```bash
./aws/scripts/deploy.sh destroy
```

**⚠️ Important**: Always destroy resources when not in use to avoid charges!

## 📁 Project Structure

```
aws/
├── cloudformation/
│   ├── infrastructure.yaml    # VPC, ALB, ECS cluster, ECR
│   └── services.yaml         # ECS tasks, services, auto-scaling
├── scripts/
│   ├── setup.sh             # Environment setup
│   └── deploy.sh            # Deployment automation
├── parameters/
│   ├── infrastructure-params.json
│   └── services-params.json
└── .env                     # Environment variables
```

## 🔍 Monitoring and Troubleshooting

### Check Service Status
```bash
aws ecs describe-services \
    --cluster kube-credentials-cluster \
    --services kube-credentials-issuer kube-credentials-verifier kube-credentials-frontend
```

### View Logs
```bash
# Get log group names
aws logs describe-log-groups --log-group-name-prefix "/ecs/kube-credentials"

# View specific service logs
aws logs tail "/ecs/kube-credentials-issuer" --follow
```

### Check Load Balancer Health
```bash
aws elbv2 describe-target-health \
    --target-group-arn $(aws elbv2 describe-target-groups \
        --names kube-credentials-issuer-tg \
        --query 'TargetGroups[0].TargetGroupArn' \
        --output text)
```

## 🛠️ Configuration

### Environment Variables

Edit `aws/.env` to customize:

```bash
# AWS Configuration
AWS_ACCOUNT_ID=123456789012
AWS_REGION=us-east-1
PROJECT_NAME=kube-credentials
ENVIRONMENT=production

# ECS Configuration
ECS_TASK_CPU=256
ECS_TASK_MEMORY=512
ECS_SERVICE_DESIRED_COUNT=1

# Auto Scaling
MIN_CAPACITY=1
MAX_CAPACITY=3
TARGET_CPU_UTILIZATION=70
```

### Custom Domains (Optional)

To use a custom domain:

1. Register domain in Route 53
2. Request SSL certificate in ACM
3. Update ALB listener to use HTTPS
4. Add CNAME record pointing to ALB

## 🔒 Security Best Practices

### IAM Permissions
The deployment uses least-privilege IAM roles:
- **ECS Task Role**: Access to EFS and CloudWatch
- **ECS Execution Role**: Pull images from ECR
- **Auto Scaling Role**: Scale ECS services

### Network Security
- All services run in private subnets
- ALB in public subnets handles external traffic
- Security groups restrict access to necessary ports only
- EFS mount targets in private subnets

### Database Security
- SQLite databases stored on encrypted EFS
- No direct external access to databases
- Service-to-service communication over private network

## 📊 Performance Optimization

### ECS Task Sizing
```yaml
# For development/testing
CPU: 256 (0.25 vCPU)
Memory: 512 MB

# For production
CPU: 512 (0.5 vCPU)
Memory: 1024 MB
```

### Auto Scaling Configuration
```yaml
MinCapacity: 1
MaxCapacity: 3
TargetCPUUtilization: 70%
ScaleOutCooldown: 300s
ScaleInCooldown: 300s
```

## 🚨 Common Issues and Solutions

### Issue: Docker Build Fails
```bash
# Clear Docker cache
docker system prune -a

# Rebuild without cache
docker build --no-cache -t service-name ./path/to/service
```

### Issue: ECS Service Won't Start
```bash
# Check ECS events
aws ecs describe-services --cluster kube-credentials-cluster --services service-name

# Check CloudWatch logs
aws logs tail "/ecs/kube-credentials-service-name" --follow
```

### Issue: Load Balancer Health Checks Fail
- Verify service is listening on correct port
- Check security group allows traffic from ALB
- Ensure health check path returns 200 OK

### Issue: Out of Free Tier Limits
```bash
# Check current usage
aws ce get-dimension-values --dimension Key=SERVICE --time-period Start=2024-01-01,End=2024-01-31

# Scale down to minimum
aws ecs update-service --cluster kube-credentials-cluster --service service-name --desired-count 1
```

## 🧹 Cleanup

To completely remove all AWS resources:

```bash
# Destroy all CloudFormation stacks
./aws/scripts/deploy.sh destroy

# Clean up any remaining ECR images (optional)
aws ecr list-images --repository-name kube-credentials-issuer --query 'imageIds[*]' --output json | \
aws ecr batch-delete-image --repository-name kube-credentials-issuer --image-ids file:///dev/stdin
```

## 📞 Support

### AWS Support Resources
- [AWS Free Tier Documentation](https://aws.amazon.com/free/)
- [ECS Fargate Pricing](https://aws.amazon.com/fargate/pricing/)
- [AWS CLI Documentation](https://aws.amazon.com/cli/)

### Common AWS CLI Commands
```bash
# Check AWS configuration
aws configure list

# Verify credentials
aws sts get-caller-identity

# List running ECS services
aws ecs list-services --cluster kube-credentials-cluster

# Check CloudFormation stacks
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE
```

---

## 🎯 Next Steps

After successful deployment:

1. **Test the application** thoroughly
2. **Set up monitoring** with CloudWatch dashboards
3. **Configure backup** for EFS if needed
4. **Set up CI/CD pipeline** with GitHub Actions
5. **Implement custom domain** and SSL certificate

Remember to monitor your AWS usage to stay within free tier limits!