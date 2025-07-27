@echo off
setlocal enabledelayedexpansion

REM Simple AWS ECS Deployment Script for Windows
REM This script will deploy your microservices to AWS ECS

echo 🚀 Starting AWS ECS Deployment...

REM Configuration - UPDATE THESE VALUES
set AWS_REGION=us-east-1
set ECR_REPOSITORY_PREFIX=multiservice

REM Step 1: Check AWS CLI
echo Step 1: Checking AWS CLI...
aws --version >nul 2>&1
if errorlevel 1 (
    echo ❌ AWS CLI is not installed. Please install it first.
    echo Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
    pause
    exit /b 1
)

REM Step 2: Check AWS credentials
echo Step 2: Checking AWS credentials...
aws sts get-caller-identity >nul 2>&1
if errorlevel 1 (
    echo ❌ AWS credentials not configured. Please run 'aws configure' first.
    pause
    exit /b 1
)

REM Get AWS Account ID
for /f "tokens=*" %%i in ('aws sts get-caller-identity --query Account --output text') do set AWS_ACCOUNT_ID=%%i
echo ✅ AWS Account ID: %AWS_ACCOUNT_ID%

REM Step 3: Create ECR repositories
echo Step 3: Creating ECR repositories...
aws ecr create-repository --repository-name %ECR_REPOSITORY_PREFIX%/api-gateway --region %AWS_REGION% >nul 2>&1 || echo Repository already exists
aws ecr create-repository --repository-name %ECR_REPOSITORY_PREFIX%/service1 --region %AWS_REGION% >nul 2>&1 || echo Repository already exists
aws ecr create-repository --repository-name %ECR_REPOSITORY_PREFIX%/service2 --region %AWS_REGION% >nul 2>&1 || echo Repository already exists

REM Step 4: Login to ECR
echo Step 4: Logging into ECR...
aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com

REM Step 5: Build and push Docker images
echo Step 5: Building and pushing Docker images...

echo 📦 Building and pushing API Gateway...
docker build -t %ECR_REPOSITORY_PREFIX%/api-gateway ./api-gateway
docker tag %ECR_REPOSITORY_PREFIX%/api-gateway:latest %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPOSITORY_PREFIX%/api-gateway:latest
docker push %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPOSITORY_PREFIX%/api-gateway:latest

echo 📦 Building and pushing Service 1...
docker build -t %ECR_REPOSITORY_PREFIX%/service1 ./service1
docker tag %ECR_REPOSITORY_PREFIX%/service1:latest %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPOSITORY_PREFIX%/service1:latest
docker push %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPOSITORY_PREFIX%/service1:latest

echo 📦 Building and pushing Service 2...
docker build -t %ECR_REPOSITORY_PREFIX%/service2 ./service2
docker tag %ECR_REPOSITORY_PREFIX%/service2:latest %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPOSITORY_PREFIX%/service2:latest
docker push %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPOSITORY_PREFIX%/service2:latest

REM Step 6: Create ECS cluster
echo Step 6: Creating ECS cluster...
aws ecs create-cluster --cluster-name multiservice-cluster --region %AWS_REGION% >nul 2>&1 || echo Cluster already exists

REM Step 7: Update task definitions with correct image URIs
echo Step 7: Updating task definitions...

REM Create temporary task definition files with correct image URIs
powershell -Command "(Get-Content aws/ecs-task-definition-api-gateway.json) -replace 'YOUR_ACCOUNT_ID', '%AWS_ACCOUNT_ID%' -replace 'YOUR_REGION', '%AWS_REGION%' | Set-Content aws/temp-api-gateway.json"
powershell -Command "(Get-Content aws/ecs-task-definition-service1.json) -replace 'YOUR_ACCOUNT_ID', '%AWS_ACCOUNT_ID%' -replace 'YOUR_REGION', '%AWS_REGION%' | Set-Content aws/temp-service1.json"
powershell -Command "(Get-Content aws/ecs-task-definition-service2.json) -replace 'YOUR_ACCOUNT_ID', '%AWS_ACCOUNT_ID%' -replace 'YOUR_REGION', '%AWS_REGION%' | Set-Content aws/temp-service2.json"

REM Step 8: Register task definitions
echo Step 8: Registering task definitions...
aws ecs register-task-definition --cli-input-json file://aws/temp-api-gateway.json --region %AWS_REGION%
aws ecs register-task-definition --cli-input-json file://aws/temp-service1.json --region %AWS_REGION%
aws ecs register-task-definition --cli-input-json file://aws/temp-service2.json --region %AWS_REGION%

REM Clean up temporary files
del aws\temp-*.json

echo ✅ Deployment completed successfully!
echo.
echo 📋 Next steps:
echo 1. Create VPC and subnets if you don't have them
echo 2. Create security groups for your services
echo 3. Create ECS services using the AWS Console or CLI
echo.
echo 🔗 Useful commands:
echo • View cluster: aws ecs describe-clusters --clusters multiservice-cluster --region %AWS_REGION%
echo • List task definitions: aws ecs list-task-definitions --region %AWS_REGION%
echo • View ECR repositories: aws ecr describe-repositories --region %AWS_REGION%

pause 