#!/bin/bash

# Simple AWS ECS Deployment Script
# This script will deploy your microservices to AWS ECS

set -e  # Exit on any error

# Configuration - UPDATE THESE VALUES
AWS_REGION="us-east-1"  # Change to your preferred region
AWS_ACCOUNT_ID=""       # Will be auto-detected
ECR_REPOSITORY_PREFIX="multiservice"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting AWS ECS Deployment...${NC}"

# Step 1: Check AWS CLI
echo -e "${YELLOW}Step 1: Checking AWS CLI...${NC}"
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    echo "Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Step 2: Check AWS credentials
echo -e "${YELLOW}Step 2: Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✅ AWS Account ID: $AWS_ACCOUNT_ID${NC}"

# Step 3: Create ECR repositories
echo -e "${YELLOW}Step 3: Creating ECR repositories...${NC}"
aws ecr create-repository --repository-name $ECR_REPOSITORY_PREFIX/api-gateway --region $AWS_REGION 2>/dev/null || echo "Repository already exists"
aws ecr create-repository --repository-name $ECR_REPOSITORY_PREFIX/service1 --region $AWS_REGION 2>/dev/null || echo "Repository already exists"
aws ecr create-repository --repository-name $ECR_REPOSITORY_PREFIX/service2 --region $AWS_REGION 2>/dev/null || echo "Repository already exists"

# Step 4: Login to ECR
echo -e "${YELLOW}Step 4: Logging into ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Step 5: Build and push Docker images
echo -e "${YELLOW}Step 5: Building and pushing Docker images...${NC}"

# Build and push API Gateway
echo -e "${BLUE}📦 Building and pushing API Gateway...${NC}"
docker build -t $ECR_REPOSITORY_PREFIX/api-gateway ./api-gateway
docker tag $ECR_REPOSITORY_PREFIX/api-gateway:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_PREFIX/api-gateway:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_PREFIX/api-gateway:latest

# Build and push Service 1
echo -e "${BLUE}📦 Building and pushing Service 1...${NC}"
docker build -t $ECR_REPOSITORY_PREFIX/service1 ./service1
docker tag $ECR_REPOSITORY_PREFIX/service1:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_PREFIX/service1:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_PREFIX/service1:latest

# Build and push Service 2
echo -e "${BLUE}📦 Building and pushing Service 2...${NC}"
docker build -t $ECR_REPOSITORY_PREFIX/service2 ./service2
docker tag $ECR_REPOSITORY_PREFIX/service2:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_PREFIX/service2:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_PREFIX/service2:latest

# Step 6: Create ECS cluster
echo -e "${YELLOW}Step 6: Creating ECS cluster...${NC}"
aws ecs create-cluster --cluster-name multiservice-cluster --region $AWS_REGION 2>/dev/null || echo "Cluster already exists"

# Step 7: Update task definitions with correct image URIs
echo -e "${YELLOW}Step 7: Updating task definitions...${NC}"

# Create temporary task definition files with correct image URIs
sed "s/YOUR_ACCOUNT_ID/$AWS_ACCOUNT_ID/g; s/YOUR_REGION/$AWS_REGION/g" aws/ecs-task-definition-api-gateway.json > aws/temp-api-gateway.json
sed "s/YOUR_ACCOUNT_ID/$AWS_ACCOUNT_ID/g; s/YOUR_REGION/$AWS_REGION/g" aws/ecs-task-definition-service1.json > aws/temp-service1.json
sed "s/YOUR_ACCOUNT_ID/$AWS_ACCOUNT_ID/g; s/YOUR_REGION/$AWS_REGION/g" aws/ecs-task-definition-service2.json > aws/temp-service2.json

# Step 8: Register task definitions
echo -e "${YELLOW}Step 8: Registering task definitions...${NC}"
aws ecs register-task-definition --cli-input-json file://aws/temp-api-gateway.json --region $AWS_REGION
aws ecs register-task-definition --cli-input-json file://aws/temp-service1.json --region $AWS_REGION
aws ecs register-task-definition --cli-input-json file://aws/temp-service2.json --region $AWS_REGION

# Clean up temporary files
rm aws/temp-*.json

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "1. Create VPC and subnets if you don't have them"
echo "2. Create security groups for your services"
echo "3. Create ECS services using the AWS Console or CLI"
echo ""
echo -e "${BLUE}🔗 Useful commands:${NC}"
echo "• View cluster: aws ecs describe-clusters --clusters multiservice-cluster --region $AWS_REGION"
echo "• List task definitions: aws ecs list-task-definitions --region $AWS_REGION"
echo "• View ECR repositories: aws ecr describe-repositories --region $AWS_REGION" 