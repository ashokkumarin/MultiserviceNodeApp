@echo off
echo 🚀 Deploying with Application Load Balancer...
echo.

REM Configuration
set AWS_REGION=ap-south-1
set CLUSTER_NAME=multiservice-cluster

echo 📋 Step 1: Creating Application Load Balancer...
echo This will create a proper load balancer for your services

REM Create ALB
aws elbv2 create-load-balancer ^
  --name multiservice-alb ^
  --subnets subnet-068227301a464aa3f subnet-003806d439fa5fcc8 ^
  --security-groups sg-0b128cd8d735e209e ^
  --region %AWS_REGION%

echo.
echo 📋 Step 2: Creating Target Groups...
echo Creating target groups for each service

REM Create target group for API Gateway
aws elbv2 create-target-group ^
  --name api-gateway-tg ^
  --protocol HTTP ^
  --port 3000 ^
  --vpc-id vpc-0c55e3f78b0b643a6 ^
  --target-type ip ^
  --region %AWS_REGION%

REM Create target group for Service 1
aws elbv2 create-target-group ^
  --name service1-tg ^
  --protocol HTTP ^
  --port 3001 ^
  --vpc-id vpc-0c55e3f78b0b643a6 ^
  --target-type ip ^
  --region %AWS_REGION%

REM Create target group for Service 2
aws elbv2 create-target-group ^
  --name service2-tg ^
  --protocol HTTP ^
  --port 3002 ^
  --vpc-id vpc-0c55e3f78b0b643a6 ^
  --target-type ip ^
  --region %AWS_REGION%

echo.
echo 📋 Step 3: Creating Listeners...
echo Creating listeners for different paths

REM Get ALB ARN
for /f "tokens=*" %%i in ('aws elbv2 describe-load-balancers --names multiservice-alb --region %AWS_REGION% --query "LoadBalancers[0].LoadBalancerArn" --output text') do set ALB_ARN=%%i

REM Get target group ARNs
for /f "tokens=*" %%i in ('aws elbv2 describe-target-groups --names api-gateway-tg --region %AWS_REGION% --query "TargetGroups[0].TargetGroupArn" --output text') do set API_TG_ARN=%%i
for /f "tokens=*" %%i in ('aws elbv2 describe-target-groups --names service1-tg --region %AWS_REGION% --query "TargetGroups[0].TargetGroupArn" --output text') do set SERVICE1_TG_ARN=%%i
for /f "tokens=*" %%i in ('aws elbv2 describe-target-groups --names service2-tg --region %AWS_REGION% --query "TargetGroups[0].TargetGroupArn" --output text') do set SERVICE2_TG_ARN=%%i

REM Create listener with rules
aws elbv2 create-listener ^
  --load-balancer-arn %ALB_ARN% ^
  --protocol HTTP ^
  --port 80 ^
  --default-actions Type=forward,TargetGroupArn=%API_TG_ARN% ^
  --region %AWS_REGION%

echo.
echo 📋 Step 4: Creating Path-based Rules...
echo Creating rules for different service paths

REM Get listener ARN
for /f "tokens=*" %%i in ('aws elbv2 describe-listeners --load-balancer-arn %ALB_ARN% --region %AWS_REGION% --query "Listeners[0].ListenerArn" --output text') do set LISTENER_ARN=%%i

REM Create rule for service1
aws elbv2 create-rule ^
  --listener-arn %LISTENER_ARN% ^
  --priority 10 ^
  --conditions Field=path-pattern,Values=/service1/* ^
  --actions Type=forward,TargetGroupArn=%SERVICE1_TG_ARN% ^
  --region %AWS_REGION%

REM Create rule for service2
aws elbv2 create-rule ^
  --listener-arn %LISTENER_ARN% ^
  --priority 20 ^
  --conditions Field=path-pattern,Values=/service2/* ^
  --actions Type=forward,TargetGroupArn=%SERVICE2_TG_ARN% ^
  --region %AWS_REGION%

echo.
echo 📋 Step 5: Getting ALB DNS Name...
for /f "tokens=*" %%i in ('aws elbv2 describe-load-balancers --names multiservice-alb --region %AWS_REGION% --query "LoadBalancers[0].DNSName" --output text') do set ALB_DNS=%%i

echo.
echo ✅ ALB DNS Name: %ALB_DNS%
echo.
echo 🧪 Test URLs:
echo API Gateway: http://%ALB_DNS%/api/message1
echo Service 1: http://%ALB_DNS%/service1/message1
echo Service 2: http://%ALB_DNS%/service2/message2
echo.

echo 💡 Next steps:
echo 1. Update your ECS services to register with target groups
echo 2. Test the ALB endpoints
echo 3. The ALB will handle routing between services

pause 