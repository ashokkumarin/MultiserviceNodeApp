#!/bin/bash

# AWS ECS Deployment Script
# Replace these variables with your actual values
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="YOUR_ACCOUNT_ID"
ECR_REPOSITORY_PREFIX="multiservice"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting AWS ECS Deployment...${NC}"

# Step 1: Configure AWS CLI
echo -e "${YELLOW}Step 1: Configuring AWS CLI...${NC}"
aws configure set default.region $AWS_REGION

# Step 2: Create ECR repositories
echo -e "${YELLOW}Step 2: Creating ECR repositories...${NC}"
aws ecr create-repository --repository-name $ECR_REPOSITORY_PREFIX/api-gateway --region $AWS_REGION || echo "Repository already exists"
aws ecr create-repository --repository-name $ECR_REPOSITORY_PREFIX/service1 --region $AWS_REGION || echo "Repository already exists"
aws ecr create-repository --repository-name $ECR_REPOSITORY_PREFIX/service2 --region $AWS_REGION || echo "Repository already exists"

# Step 3: Get ECR login token
echo -e "${YELLOW}Step 3: Logging into ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Step 4: Build and push Docker images
echo -e "${YELLOW}Step 4: Building and pushing Docker images...${NC}"

# Build and push API Gateway
echo "Building and pushing API Gateway..."
docker build -t $ECR_REPOSITORY_PREFIX/api-gateway ./api-gateway
docker tag $ECR_REPOSITORY_PREFIX/api-gateway:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_PREFIX/api-gateway:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_PREFIX/api-gateway:latest

# Build and push Service 1
echo "Building and pushing Service 1..."
docker build -t $ECR_REPOSITORY_PREFIX/service1 ./service1
docker tag $ECR_REPOSITORY_PREFIX/service1:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_PREFIX/service1:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_PREFIX/service1:latest

# Build and push Service 2
echo "Building and pushing Service 2..."
docker build -t $ECR_REPOSITORY_PREFIX/service2 ./service2
docker tag $ECR_REPOSITORY_PREFIX/service2:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_PREFIX/service2:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_PREFIX/service2:latest

# Step 5: Create ECS cluster
echo -e "${YELLOW}Step 5: Creating ECS cluster...${NC}"
aws ecs create-cluster --cluster-name multiservice-cluster --region $AWS_REGION || echo "Cluster already exists"

# Step 6: Register task definitions
echo -e "${YELLOW}Step 6: Registering task definitions...${NC}"
aws ecs register-task-definition --cli-input-json file://aws/ecs-task-definition-api-gateway.json --region $AWS_REGION
aws ecs register-task-definition --cli-input-json file://aws/ecs-task-definition-service1.json --region $AWS_REGION
aws ecs register-task-definition --cli-input-json file://aws/ecs-task-definition-service2.json --region $AWS_REGION

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update the security groups and subnets in aws/ecs-service-definitions.json"
echo "2. Create Application Load Balancer (if needed)"
echo "3. Run: aws ecs create-service --cli-input-json file://aws/ecs-service-definitions.json" 