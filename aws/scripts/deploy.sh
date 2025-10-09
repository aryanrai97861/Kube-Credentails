#!/bin/bash

# Kube Credentials - AWS Deployment Script
# This script deploys the application to AWS ECS Fargate

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="kube-credentials"
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-production}"

# Print colored output
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

# Check if AWS CLI is installed and configured
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Get AWS Account ID
get_account_id() {
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    print_status "Using AWS Account ID: $ACCOUNT_ID"
}

# Deploy infrastructure using CloudFormation
deploy_infrastructure() {
    print_status "Deploying infrastructure stack..."
    
    aws cloudformation deploy \
        --template-file aws/cloudformation/infrastructure.yaml \
        --stack-name "${PROJECT_NAME}-infrastructure" \
        --parameter-overrides \
            ProjectName="$PROJECT_NAME" \
            Environment="$ENVIRONMENT" \
        --capabilities CAPABILITY_IAM \
        --region "$AWS_REGION"
    
    print_success "Infrastructure stack deployed successfully"
}

# Build and push Docker images to ECR
build_and_push_images() {
    print_status "Building and pushing Docker images..."
    
    # Get ECR login token
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    
    # Get ECR repository URIs from CloudFormation stack
    ISSUER_REPO_URI=$(aws cloudformation describe-stacks \
        --stack-name "${PROJECT_NAME}-infrastructure" \
        --query "Stacks[0].Outputs[?OutputKey=='IssuerRepositoryURI'].OutputValue" \
        --output text \
        --region "$AWS_REGION")
    
    VERIFIER_REPO_URI=$(aws cloudformation describe-stacks \
        --stack-name "${PROJECT_NAME}-infrastructure" \
        --query "Stacks[0].Outputs[?OutputKey=='VerifierRepositoryURI'].OutputValue" \
        --output text \
        --region "$AWS_REGION")
    
    FRONTEND_REPO_URI=$(aws cloudformation describe-stacks \
        --stack-name "${PROJECT_NAME}-infrastructure" \
        --query "Stacks[0].Outputs[?OutputKey=='FrontendRepositoryURI'].OutputValue" \
        --output text \
        --region "$AWS_REGION")
    
    print_status "Repository URIs:"
    print_status "  Issuer: $ISSUER_REPO_URI"
    print_status "  Verifier: $VERIFIER_REPO_URI"
    print_status "  Frontend: $FRONTEND_REPO_URI"
    
    # Generate timestamp once for consistent tagging
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    
    # Build and tag images
    print_status "Building issuer service..."
    docker build -t "${PROJECT_NAME}-issuer:latest" ./services/issuer/
    docker tag "${PROJECT_NAME}-issuer:latest" "$ISSUER_REPO_URI:latest"
    docker tag "${PROJECT_NAME}-issuer:latest" "$ISSUER_REPO_URI:$TIMESTAMP"
    
    print_status "Building verifier service..."
    docker build -t "${PROJECT_NAME}-verifier:latest" ./services/verifier/
    docker tag "${PROJECT_NAME}-verifier:latest" "$VERIFIER_REPO_URI:latest"
    docker tag "${PROJECT_NAME}-verifier:latest" "$VERIFIER_REPO_URI:$TIMESTAMP"
    
    print_status "Building frontend..."
    docker build -t "${PROJECT_NAME}-frontend:latest" ./frontend/
    docker tag "${PROJECT_NAME}-frontend:latest" "$FRONTEND_REPO_URI:latest"
    docker tag "${PROJECT_NAME}-frontend:latest" "$FRONTEND_REPO_URI:$TIMESTAMP"
    
    # Push images
    print_status "Pushing issuer image..."
    docker push "$ISSUER_REPO_URI:latest"
    docker push "$ISSUER_REPO_URI:$TIMESTAMP"
    
    print_status "Pushing verifier image..."
    docker push "$VERIFIER_REPO_URI:latest"
    docker push "$VERIFIER_REPO_URI:$TIMESTAMP"
    
    print_status "Pushing frontend image..."
    docker push "$FRONTEND_REPO_URI:latest"
    docker push "$FRONTEND_REPO_URI:$TIMESTAMP"
    
    print_success "All images pushed successfully"
}

# Add this function to your deploy-aws.sh script

# Check and fix stack in ROLLBACK_COMPLETE state
fix_rollback_complete_stack() {
    local stack_name=$1
    
    print_status "Checking stack status: $stack_name"
    
    STACK_STATUS=$(aws cloudformation describe-stacks \
        --stack-name "$stack_name" \
        --query "Stacks[0].StackStatus" \
        --output text \
        --region "$AWS_REGION" 2>/dev/null || echo "DOES_NOT_EXIST")
    
    if [[ "$STACK_STATUS" == "ROLLBACK_COMPLETE" ]]; then
        print_warning "Stack $stack_name is in ROLLBACK_COMPLETE state"
        print_status "Deleting stack to allow recreation..."
        
        aws cloudformation delete-stack \
            --stack-name "$stack_name" \
            --region "$AWS_REGION"
        
        print_status "Waiting for stack deletion to complete..."
        aws cloudformation wait stack-delete-complete \
            --stack-name "$stack_name" \
            --region "$AWS_REGION"
        
        print_success "Stack deleted successfully"
    elif [[ "$STACK_STATUS" == "DOES_NOT_EXIST" ]]; then
        print_status "Stack does not exist, will create new"
    else
        print_status "Stack status: $STACK_STATUS"
    fi
}

# Update the deploy_services function to call this first
deploy_services() {
    print_status "Deploying ECS services..."
    
    # Fix any ROLLBACK_COMPLETE state
    fix_rollback_complete_stack "${PROJECT_NAME}-services"
    
    # Get image URIs
    ISSUER_IMAGE_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}-issuer:latest"
    VERIFIER_IMAGE_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}-verifier:latest"
    FRONTEND_IMAGE_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}-frontend:latest"
    
    aws cloudformation deploy \
        --template-file aws/cloudformation/services-working.yaml \
        --stack-name "${PROJECT_NAME}-services" \
        --parameter-overrides \
            ProjectName="$PROJECT_NAME" \
            Environment="$ENVIRONMENT" \
            IssuerImageURI="$ISSUER_IMAGE_URI" \
            VerifierImageURI="$VERIFIER_IMAGE_URI" \
            FrontendImageURI="$FRONTEND_IMAGE_URI" \
        --capabilities CAPABILITY_IAM \
        --region "$AWS_REGION"
    
    print_success "ECS services deployed successfully"
}

# Get application URL
get_application_url() {
    print_status "Getting application URL..."
    
    APP_URL=$(aws cloudformation describe-stacks \
        --stack-name "${PROJECT_NAME}-infrastructure" \
        --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerURL'].OutputValue" \
        --output text \
        --region "$AWS_REGION")
    
    print_success "Application URL: $APP_URL"
    print_status "Frontend: $APP_URL"
    print_status "Issuer API: $APP_URL/api/issue"
    print_status "Verifier API: $APP_URL/api/verify"
}

# Wait for services to be healthy
wait_for_services() {
    print_status "Waiting for services to become healthy..."
    
    # Wait for ECS services to stabilize
    aws ecs wait services-stable \
        --cluster "${PROJECT_NAME}-cluster" \
        --services "${PROJECT_NAME}-issuer" "${PROJECT_NAME}-verifier" "${PROJECT_NAME}-frontend" \
        --region "$AWS_REGION"
    
    print_success "All services are running and healthy"
}

# Test the deployment
test_deployment() {
    print_status "Testing deployment..."
    
    APP_URL=$(aws cloudformation describe-stacks \
        --stack-name "${PROJECT_NAME}-infrastructure" \
        --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerURL'].OutputValue" \
        --output text \
        --region "$AWS_REGION")
    
    # Test issuer service
    print_status "Testing issuer service..."
    ISSUE_RESPONSE=$(curl -s -X POST "$APP_URL/api/issue" \
        -H "Content-Type: application/json" \
        -d '{"studentId":"test123","course":"TestCourse"}' || echo "FAILED")
    
    if [[ "$ISSUE_RESPONSE" == *"credential issued"* ]]; then
        print_success "Issuer service is working"
    else
        print_warning "Issuer service test failed: $ISSUE_RESPONSE"
    fi
    
    # Test verifier service
    print_status "Testing verifier service..."
    VERIFY_RESPONSE=$(curl -s -X POST "$APP_URL/api/verify" \
        -H "Content-Type: application/json" \
        -d '{"studentId":"test123","course":"TestCourse"}' || echo "FAILED")
    
    if [[ "$VERIFY_RESPONSE" != "FAILED" ]]; then
        print_success "Verifier service is working"
    else
        print_warning "Verifier service test failed"
    fi
    
    # Test frontend
    print_status "Testing frontend..."
    FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL" || echo "000")
    
    if [[ "$FRONTEND_RESPONSE" == "200" ]]; then
        print_success "Frontend is working"
    else
        print_warning "Frontend test failed (HTTP $FRONTEND_RESPONSE)"
    fi
}

# Main deployment function
main() {
    print_status "Starting AWS deployment for $PROJECT_NAME"
    print_status "Region: $AWS_REGION"
    print_status "Environment: $ENVIRONMENT"
    
    check_prerequisites
    get_account_id
    deploy_infrastructure
    build_and_push_images
    deploy_services
    wait_for_services
    get_application_url
    test_deployment
    
    print_success "🎉 Deployment completed successfully!"
    print_status "Your application is now running on AWS ECS Fargate"
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "destroy")
        print_status "Destroying AWS resources..."
        aws cloudformation delete-stack --stack-name "${PROJECT_NAME}-services" --region "$AWS_REGION"
        aws cloudformation wait stack-delete-complete --stack-name "${PROJECT_NAME}-services" --region "$AWS_REGION"
        aws cloudformation delete-stack --stack-name "${PROJECT_NAME}-infrastructure" --region "$AWS_REGION"
        aws cloudformation wait stack-delete-complete --stack-name "${PROJECT_NAME}-infrastructure" --region "$AWS_REGION"
        print_success "AWS resources destroyed successfully"
        ;;
    "update")
        print_status "Updating services..."
        build_and_push_images
        deploy_services
        wait_for_services
        get_application_url
        test_deployment
        print_success "Services updated successfully"
        ;;
    *)
        echo "Usage: $0 [deploy|destroy|update]"
        echo "  deploy  - Deploy the full infrastructure and services"
        echo "  destroy - Destroy all AWS resources"
        echo "  update  - Update services with new images"
        exit 1
        ;;
esac