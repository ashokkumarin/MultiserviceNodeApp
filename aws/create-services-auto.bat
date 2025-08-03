@echo off
setlocal enabledelayedexpansion

REM Create ECS Services Script with Auto-Detection
REM This script will create the ECS services using the latest task definitions

echo 🚀 Creating ECS Services with Auto-Detection...

REM Configuration
set AWS_REGION=ap-south-1
set CLUSTER_NAME=multiservice-cluster

REM Get latest task definition versions
echo Getting latest task definition versions...
for /f "tokens=*" %%i in ('aws ecs describe-task-definition --task-definition api-gateway --region %AWS_REGION% --query "taskDefinition.taskDefinitionArn" --output text') do set API_GATEWAY_TASK=%%i
for /f "tokens=*" %%i in ('aws ecs describe-task-definition --task-definition service1 --region %AWS_REGION% --query "taskDefinition.taskDefinitionArn" --output text') do set SERVICE1_TASK=%%i
for /f "tokens=*" %%i in ('aws ecs describe-task-definition --task-definition service2 --region %AWS_REGION% --query "taskDefinition.taskDefinitionArn" --output text') do set SERVICE2_TASK=%%i

echo API Gateway Task: %API_GATEWAY_TASK%
echo Service1 Task: %SERVICE1_TASK%
echo Service2 Task: %SERVICE2_TASK%

REM Get VPC and Subnet information
echo Getting VPC and Subnet information...
for /f "tokens=*" %%i in ('aws ec2 describe-vpcs --region %AWS_REGION% --query "Vpcs[?IsDefault==true].VpcId" --output text') do set VPC_ID=%%i
echo VPC ID: %VPC_ID%

for /f "tokens=*" %%i in ('aws ec2 describe-subnets --region %AWS_REGION% --filters "Name=vpc-id,Values=%VPC_ID%" --query "Subnets[0:2].SubnetId" --output text') do set SUBNET_IDS=%%i
echo Subnet IDs: %SUBNET_IDS%

REM Create Security Group
echo Creating Security Group...
aws ec2 create-security-group --group-name multiservice-sg --description "Security group for multiservice app" --vpc-id %VPC_ID% --region %AWS_REGION% >nul 2>&1 || echo Security group already exists

for /f "tokens=*" %%i in ('aws ec2 describe-security-groups --region %AWS_REGION% --filters "Name=group-name,Values=multiservice-sg" --query "SecurityGroups[0].GroupId" --output text') do set SECURITY_GROUP_ID=%%i

REM Add inbound rules
aws ec2 authorize-security-group-ingress --group-id %SECURITY_GROUP_ID% --protocol tcp --port 3000 --cidr 0.0.0.0/0 --region %AWS_REGION% >nul 2>&1
aws ec2 authorize-security-group-ingress --group-id %SECURITY_GROUP_ID% --protocol tcp --port 3001 --cidr 0.0.0.0/0 --region %AWS_REGION% >nul 2>&1
aws ec2 authorize-security-group-ingress --group-id %SECURITY_GROUP_ID% --protocol tcp --port 3002 --cidr 0.0.0.0/0 --region %AWS_REGION% >nul 2>&1

echo Security Group ID: %SECURITY_GROUP_ID%

REM Check if services already exist
echo Checking if services already exist...
aws ecs describe-services --cluster %CLUSTER_NAME% --services service1-service --region %AWS_REGION% >nul 2>&1
if not errorlevel 1 (
    echo Service1 already exists, skipping...
) else (
    echo Creating Service 1...
    aws ecs create-service ^
      --cluster %CLUSTER_NAME% ^
      --service-name service1-service ^
      --task-definition %SERVICE1_TASK% ^
      --desired-count 1 ^
      --launch-type FARGATE ^
      --network-configuration "awsvpcConfiguration={subnets=[%SUBNET_IDS%],securityGroups=[%SECURITY_GROUP_ID%],assignPublicIp=ENABLED}" ^
      --region %AWS_REGION%
)

aws ecs describe-services --cluster %CLUSTER_NAME% --services service2-service --region %AWS_REGION% >nul 2>&1
if not errorlevel 1 (
    echo Service2 already exists, skipping...
) else (
    echo Creating Service 2...
    aws ecs create-service ^
      --cluster %CLUSTER_NAME% ^
      --service-name service2-service ^
      --task-definition %SERVICE2_TASK% ^
      --desired-count 1 ^
      --launch-type FARGATE ^
      --network-configuration "awsvpcConfiguration={subnets=[%SUBNET_IDS%],securityGroups=[%SECURITY_GROUP_ID%],assignPublicIp=ENABLED}" ^
      --region %AWS_REGION%
)

aws ecs describe-services --cluster %CLUSTER_NAME% --services api-gateway-service --region %AWS_REGION% >nul 2>&1
if not errorlevel 1 (
    echo API Gateway service already exists, skipping...
) else (
    echo Creating API Gateway Service...
    aws ecs create-service ^
      --cluster %CLUSTER_NAME% ^
      --service-name api-gateway-service ^
      --task-definition %API_GATEWAY_TASK% ^
      --desired-count 1 ^
      --launch-type FARGATE ^
      --network-configuration "awsvpcConfiguration={subnets=[%SUBNET_IDS%],securityGroups=[%SECURITY_GROUP_ID%],assignPublicIp=ENABLED}" ^
      --region %AWS_REGION%
)

echo ✅ Services created successfully!
echo.
echo 🔗 Check your services in AWS Console:
echo https://console.aws.amazon.com/ecs/home?region=%AWS_REGION%#/clusters/%CLUSTER_NAME%/services
echo.
echo 📋 Next: Wait a few minutes for services to start, then test them!
echo.
echo 🧪 To get public IPs, run: aws/get-public-ips.bat

pause 