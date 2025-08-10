@echo off
echo 🚀 Deploying Multi-Service App with ALB and Internal Communication...
echo.

REM Configuration
set AWS_REGION=ap-south-1
set AWS_ACCOUNT_ID=936723057830
set CLUSTER_NAME=multiservice-cluster

echo 📋 Step 1: Building and Pushing Docker Images...
echo Building API Gateway...
docker build -t %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/multiservice/api-gateway:latest ./api-gateway

echo Building Service 1...
docker build -t %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/multiservice/service1:latest ./service1

echo Building Service 2...
docker build -t %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/multiservice/service2:latest ./service2

echo.
echo 📋 Step 2: Pushing to ECR...
aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com
docker push %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/multiservice/api-gateway:latest
docker push %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/multiservice/service1:latest
docker push %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/multiservice/service2:latest

echo.
echo 📋 Step 3: Creating ALB Infrastructure...
echo Creating Application Load Balancer...
aws elbv2 create-load-balancer ^
  --name multiservice-alb ^
  --subnets subnet-068227301a464aa3f subnet-003806d439fa5fcc8 ^
  --security-groups sg-0b128cd8d735e209e ^
  --region %AWS_REGION%

echo Creating Target Groups...
aws elbv2 create-target-group ^
  --name api-gateway-tg ^
  --protocol HTTP ^
  --port 3000 ^
  --vpc-id vpc-0b4e329bb2df78153 ^
  --target-type ip ^
  --region %AWS_REGION%

aws elbv2 create-target-group ^
  --name service1-tg ^
  --protocol HTTP ^
  --port 3001 ^
  --vpc-id vpc-0b4e329bb2df78153 ^
  --target-type ip ^
  --region %AWS_REGION%

aws elbv2 create-target-group ^
  --name service2-tg ^
  --protocol HTTP ^
  --port 3002 ^
  --vpc-id vpc-0b4e329bb2df78153 ^
  --target-type ip ^
  --region %AWS_REGION%

echo.
echo 📋 Step 4: Getting ALB and Target Group ARNs...
for /f "tokens=*" %%i in ('aws elbv2 describe-load-balancers --names multiservice-alb --region %AWS_REGION% --query "LoadBalancers[0].LoadBalancerArn" --output text') do set ALB_ARN=%%i
for /f "tokens=*" %%i in ('aws elbv2 describe-target-groups --names api-gateway-tg --region %AWS_REGION% --query "TargetGroups[0].TargetGroupArn" --output text') do set API_TG_ARN=%%i
for /f "tokens=*" %%i in ('aws elbv2 describe-target-groups --names service1-tg --region %AWS_REGION% --query "TargetGroups[0].TargetGroupArn" --output text') do set SERVICE1_TG_ARN=%%i
for /f "tokens=*" %%i in ('aws elbv2 describe-target-groups --names service2-tg --region %AWS_REGION% --query "TargetGroups[0].TargetGroupArn" --output text') do set SERVICE2_TG_ARN=%%i

echo ALB ARN: %ALB_ARN%
echo API Gateway Target Group: %API_TG_ARN%
echo Service 1 Target Group: %SERVICE1_TG_ARN%
echo Service 2 Target Group: %SERVICE2_TG_ARN%

echo.
echo 📋 Step 5: Creating ALB Listener...
aws elbv2 create-listener ^
  --load-balancer-arn %ALB_ARN% ^
  --protocol HTTP ^
  --port 80 ^
  --default-actions Type=forward,TargetGroupArn=%API_TG_ARN% ^
  --region %AWS_REGION%

echo.
echo 📋 Step 6: Registering Task Definitions...
echo Registering API Gateway task definition...
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
echo 📋 Step 7: Creating ECS Services with ALB Integration...
echo Creating API Gateway service...
aws ecs create-service ^
  --cluster %CLUSTER_NAME% ^
  --service-name api-gateway-service ^
  --task-definition api-gateway ^
  --desired-count 1 ^
  --launch-type FARGATE ^
  --network-configuration "awsvpcConfiguration={subnets=[subnet-068227301a464aa3f,subnet-003806d439fa5fcc8],securityGroups=[sg-0b128cd8d735e209e],assignPublicIp=ENABLED}" ^
  --load-balancers "targetGroupArn=%API_TG_ARN%,containerName=api-gateway,containerPort=3000" ^
  --region %AWS_REGION%

echo Creating Service 1...
aws ecs create-service ^
  --cluster %CLUSTER_NAME% ^
  --service-name service1-service ^
  --task-definition service1 ^
  --desired-count 1 ^
  --launch-type FARGATE ^
  --network-configuration "awsvpcConfiguration={subnets=[subnet-068227301a464aa3f,subnet-003806d439fa5fcc8],securityGroups=[sg-0b128cd8d735e209e],assignPublicIp=ENABLED}" ^
  --load-balancers "targetGroupArn=%SERVICE1_TG_ARN%,containerName=service1,containerPort=3001" ^
  --region %AWS_REGION%

echo Creating Service 2...
aws ecs create-service ^
  --cluster %CLUSTER_NAME% ^
  --service-name service2-service ^
  --task-definition service2 ^
  --desired-count 1 ^
  --launch-type FARGATE ^
  --network-configuration "awsvpcConfiguration={subnets=[subnet-068227301a464aa3f,subnet-003806d439fa5fcc8],securityGroups=[sg-0b128cd8d735e209e],assignPublicIp=ENABLED}" ^
  --load-balancers "targetGroupArn=%SERVICE2_TG_ARN%,containerName=service2,containerPort=3002" ^
  --region %AWS_REGION%

echo.
echo 📋 Step 8: Getting ALB DNS Name...
for /f "tokens=*" %%i in ('aws elbv2 describe-load-balancers --names multiservice-alb --region %AWS_REGION% --query "LoadBalancers[0].DNSName" --output text') do set ALB_DNS=%%i

echo.
echo ✅ Deployment Complete with ALB and Internal Communication!
echo 🌐 ALB DNS Name: %ALB_DNS%
echo.
echo 🧪 Test URLs (after services are stable):
echo API Gateway: http://%ALB_DNS%/api/message1
echo Service 1: http://%ALB_DNS%/service1/message1
echo Service 2: http://%ALB_DNS%/service2/message2
echo.
echo 💡 Architecture Benefits:
echo - ✅ Internal communication between services
echo - ✅ No hardcoded IPs
echo - ✅ Proper load balancing
echo - ✅ More secure architecture
echo - ✅ Service discovery using internal IPs
echo - ✅ ALB handles external traffic
echo.
echo 💰 COST MANAGEMENT REMINDER:
echo ⚠️  ALB costs ~$16/month + usage charges
echo ⚠️  ECS Fargate charges for running time
echo ⚠️  ECR storage charges for Docker images
echo.
echo 🧹 CLEANUP WHEN DONE:
echo Run 'aws\cleanup-all-resources.bat' to DELETE ALL resources
echo This will avoid ongoing charges when you're done testing!
echo.
echo 📊 Estimated monthly cost if left running:
echo - ALB: ~$16/month
echo - ECS Fargate (3 services): ~$20-30/month
echo - ECR storage: ~$1-2/month
echo - Total: ~$37-48/month if left running 24/7
echo.
echo 🎓 Learning tip: Deploy → Test → Cleanup → Repeat!

pause 