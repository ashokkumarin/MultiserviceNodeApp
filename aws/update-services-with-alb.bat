@echo off
echo 🔧 Updating ECS Services for ALB and Internal Communication...
echo.

REM Configuration
set AWS_REGION=ap-south-1
set AWS_ACCOUNT_ID=936723057830
set CLUSTER_NAME=multiservice-cluster

echo 📋 Step 1: Getting Target Group ARNs...
for /f "tokens=*" %%i in ('aws elbv2 describe-target-groups --names api-gateway-tg --region %AWS_REGION% --query "TargetGroups[0].TargetGroupArn" --output text') do set API_TG_ARN=%%i
for /f "tokens=*" %%i in ('aws elbv2 describe-target-groups --names service1-tg --region %AWS_REGION% --query "TargetGroups[0].TargetGroupArn" --output text') do set SERVICE1_TG_ARN=%%i
for /f "tokens=*" %%i in ('aws elbv2 describe-target-groups --names service2-tg --region %AWS_REGION% --query "TargetGroups[0].TargetGroupArn" --output text') do set SERVICE2_TG_ARN=%%i

echo API Gateway Target Group: %API_TG_ARN%
echo Service 1 Target Group: %SERVICE1_TG_ARN%
echo Service 2 Target Group: %SERVICE2_TG_ARN%

echo.
echo 📋 Step 2: Rebuilding and Pushing Updated API Gateway...
docker build -t %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/multiservice/api-gateway:latest ./api-gateway
aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com
docker push %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/multiservice/api-gateway:latest

echo.
echo 📋 Step 3: Registering New Task Definitions with ALB Integration...
echo Registering API Gateway task definition with ALB...
aws ecs register-task-definition ^
  --family api-gateway ^
  --network-mode awsvpc ^
  --requires-compatibilities FARGATE ^
  --cpu 256 ^
  --memory 512 ^
  --execution-role-arn arn:aws:iam::%AWS_ACCOUNT_ID%:role/ecsTaskExecutionRole ^
  --container-definitions "[{\"name\":\"api-gateway\",\"image\":\"%AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/multiservice/api-gateway:latest\",\"portMappings\":[{\"containerPort\":3000,\"protocol\":\"tcp\"}],\"essential\":true,\"logConfiguration\":{\"logDriver\":\"awslogs\",\"options\":{\"awslogs-group\":\"/ecs/api-gateway\",\"awslogs-region\":\"%AWS_REGION%\",\"awslogs-stream-prefix\":\"ecs\"}}}]" ^
  --region %AWS_REGION%

echo Registering Service 1 task definition...
aws ecs register-task-definition ^
  --family service1 ^
  --network-mode awsvpc ^
  --requires-compatibilities FARGATE ^
  --cpu 256 ^
  --memory 512 ^
  --execution-role-arn arn:aws:iam::%AWS_ACCOUNT_ID%:role/ecsTaskExecutionRole ^
  --container-definitions "[{\"name\":\"service1\",\"image\":\"%AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/multiservice/service1:latest\",\"portMappings\":[{\"containerPort\":3001,\"protocol\":\"tcp\"}],\"essential\":true,\"logConfiguration\":{\"logDriver\":\"awslogs\",\"options\":{\"awslogs-group\":\"/ecs/service1\",\"awslogs-region\":\"%AWS_REGION%\",\"awslogs-stream-prefix\":\"ecs\"}}}]" ^
  --region %AWS_REGION%

echo Registering Service 2 task definition...
aws ecs register-task-definition ^
  --family service2 ^
  --network-mode awsvpc ^
  --requires-compatibilities FARGATE ^
  --cpu 256 ^
  --memory 512 ^
  --execution-role-arn arn:aws:iam::%AWS_ACCOUNT_ID%:role/ecsTaskExecutionRole ^
  --container-definitions "[{\"name\":\"service2\",\"image\":\"%AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/multiservice/service2:latest\",\"portMappings\":[{\"containerPort\":3002,\"protocol\":\"tcp\"}],\"essential\":true,\"logConfiguration\":{\"logDriver\":\"awslogs\",\"options\":{\"awslogs-group\":\"/ecs/service2\",\"awslogs-region\":\"%AWS_REGION%\",\"awslogs-stream-prefix\":\"ecs\"}}}]" ^
  --region %AWS_REGION%

echo.
echo 📋 Step 4: Updating Services with ALB Integration...
echo Updating API Gateway service with ALB...
aws ecs update-service ^
  --cluster %CLUSTER_NAME% ^
  --service api-gateway-service ^
  --task-definition api-gateway ^
  --load-balancers "targetGroupArn=%API_TG_ARN%,containerName=api-gateway,containerPort=3000" ^
  --region %AWS_REGION%

echo Updating Service 1...
aws ecs update-service ^
  --cluster %CLUSTER_NAME% ^
  --service service1-service ^
  --task-definition service1 ^
  --load-balancers "targetGroupArn=%SERVICE1_TG_ARN%,containerName=service1,containerPort=3001" ^
  --region %AWS_REGION%

echo Updating Service 2...
aws ecs update-service ^
  --cluster %CLUSTER_NAME% ^
  --service service2-service ^
  --task-definition service2 ^
  --load-balancers "targetGroupArn=%SERVICE2_TG_ARN%,containerName=service2,containerPort=3002" ^
  --region %AWS_REGION%

echo.
echo 📋 Step 5: Getting ALB DNS Name...
for /f "tokens=*" %%i in ('aws elbv2 describe-load-balancers --names multiservice-alb --region %AWS_REGION% --query "LoadBalancers[0].DNSName" --output text') do set ALB_DNS=%%i

echo.
echo ✅ Services Updated with ALB Integration!
echo 🌐 ALB DNS Name: %ALB_DNS%
echo.
echo 🧪 Test URLs (after services are stable):
echo API Gateway: http://%ALB_DNS%/api/message1
echo Service 1: http://%ALB_DNS%/service1/message1
echo Service 2: http://%ALB_DNS%/service2/message2
echo.
echo 💡 Benefits of this setup:
echo - Internal communication between services
echo - No hardcoded IPs
echo - Proper load balancing
echo - More secure architecture

pause 