@echo off
setlocal enabledelayedexpansion

REM Fix Task Definitions Script
REM This script will create new task definitions with correct image URIs

echo 🔧 Fixing Task Definitions with correct image URIs...

REM Configuration
set AWS_REGION=ap-south-1
set AWS_ACCOUNT_ID=936723057830

REM Create new task definition for API Gateway
echo Creating new API Gateway task definition...
aws ecs register-task-definition ^
  --family api-gateway ^
  --network-mode awsvpc ^
  --requires-compatibilities FARGATE ^
  --cpu 256 ^
  --memory 512 ^
  --execution-role-arn arn:aws:iam::%AWS_ACCOUNT_ID%:role/ecsTaskExecutionRole ^
  --container-definitions "[{\"name\":\"api-gateway\",\"image\":\"%AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/multiservice/api-gateway:latest\",\"portMappings\":[{\"containerPort\":3000,\"protocol\":\"tcp\"}],\"essential\":true,\"logConfiguration\":{\"logDriver\":\"awslogs\",\"options\":{\"awslogs-group\":\"/ecs/api-gateway\",\"awslogs-region\":\"%AWS_REGION%\",\"awslogs-stream-prefix\":\"ecs\"}}}]" ^
  --region %AWS_REGION%

REM Create new task definition for Service 1
echo Creating new Service 1 task definition...
aws ecs register-task-definition ^
  --family service1 ^
  --network-mode awsvpc ^
  --requires-compatibilities FARGATE ^
  --cpu 256 ^
  --memory 512 ^
  --execution-role-arn arn:aws:iam::%AWS_ACCOUNT_ID%:role/ecsTaskExecutionRole ^
  --container-definitions "[{\"name\":\"service1\",\"image\":\"%AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/multiservice/service1:latest\",\"portMappings\":[{\"containerPort\":3001,\"protocol\":\"tcp\"}],\"essential\":true,\"logConfiguration\":{\"logDriver\":\"awslogs\",\"options\":{\"awslogs-group\":\"/ecs/service1\",\"awslogs-region\":\"%AWS_REGION%\",\"awslogs-stream-prefix\":\"ecs\"}}}]" ^
  --region %AWS_REGION%

REM Create new task definition for Service 2
echo Creating new Service 2 task definition...
aws ecs register-task-definition ^
  --family service2 ^
  --network-mode awsvpc ^
  --requires-compatibilities FARGATE ^
  --cpu 256 ^
  --memory 512 ^
  --execution-role-arn arn:aws:iam::%AWS_ACCOUNT_ID%:role/ecsTaskExecutionRole ^
  --container-definitions "[{\"name\":\"service2\",\"image\":\"%AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/multiservice/service2:latest\",\"portMappings\":[{\"containerPort\":3002,\"protocol\":\"tcp\"}],\"essential\":true,\"logConfiguration\":{\"logDriver\":\"awslogs\",\"options\":{\"awslogs-group\":\"/ecs/service2\",\"awslogs-region\":\"%AWS_REGION%\",\"awslogs-stream-prefix\":\"ecs\"}}}]" ^
  --region %AWS_REGION%

echo ✅ Task definitions updated successfully!
echo.
echo 🔄 Now updating services to use new task definitions...

REM Update services to use new task definitions
aws ecs update-service --cluster multiservice-cluster --service api-gateway-service --task-definition api-gateway --region %AWS_REGION%
aws ecs update-service --cluster multiservice-cluster --service service1-service --task-definition service1 --region %AWS_REGION%
aws ecs update-service --cluster multiservice-cluster --service service2-service --task-definition service2 --region %AWS_REGION%

echo ✅ Services updated successfully!
echo.
echo 🧪 Wait a few minutes for services to restart, then check running tasks:
echo aws ecs list-tasks --cluster multiservice-cluster

pause 