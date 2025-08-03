@echo off
setlocal enabledelayedexpansion

REM Create ECS Services Script
REM This script will create the ECS services after deployment

echo 🚀 Creating ECS Services...

REM Configuration
set AWS_REGION=ap-south-1
set CLUSTER_NAME=multiservice-cluster

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

REM Create Service 1
echo Creating Service 1...
aws ecs create-service ^
  --cluster %CLUSTER_NAME% ^
  --service-name service1-service ^
  --task-definition service1:6 ^
  --desired-count 1 ^
  --launch-type FARGATE ^
  --network-configuration "awsvpcConfiguration={subnets=[%SUBNET_IDS%],securityGroups=[%SECURITY_GROUP_ID%],assignPublicIp=ENABLED}" ^
  --region %AWS_REGION%

REM Create Service 2
echo Creating Service 2...
aws ecs create-service ^
  --cluster %CLUSTER_NAME% ^
  --service-name service2-service ^
  --task-definition service2:6 ^
  --desired-count 1 ^
  --launch-type FARGATE ^
  --network-configuration "awsvpcConfiguration={subnets=[%SUBNET_IDS%],securityGroups=[%SECURITY_GROUP_ID%],assignPublicIp=ENABLED}" ^
  --region %AWS_REGION%

REM Create API Gateway Service
echo Creating API Gateway Service...
aws ecs create-service ^
  --cluster %CLUSTER_NAME% ^
  --service-name api-gateway-service ^
  --task-definition api-gateway:6 ^
  --desired-count 1 ^
  --launch-type FARGATE ^
  --network-configuration "awsvpcConfiguration={subnets=[%SUBNET_IDS%],securityGroups=[%SECURITY_GROUP_ID%],assignPublicIp=ENABLED}" ^
  --region %AWS_REGION%

echo ✅ Services created successfully!
echo.
echo 🔗 Check your services in AWS Console:
echo https://console.aws.amazon.com/ecs/home?region=%AWS_REGION%#/clusters/%CLUSTER_NAME%/services
echo.
echo 📋 Next: Wait a few minutes for services to start, then test them!

pause 