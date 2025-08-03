@echo off
echo 🚀 Creating ALB Infrastructure for Internal Communication...
echo.

REM Configuration
set AWS_REGION=ap-south-1
set CLUSTER_NAME=multiservice-cluster

echo 📋 Step 1: Creating Application Load Balancer...
aws elbv2 create-load-balancer ^
  --name multiservice-alb ^
  --subnets subnet-068227301a464aa3f subnet-003806d439fa5fcc8 ^
  --security-groups sg-0b128cd8d735e209e ^
  --region %AWS_REGION%

echo.
echo 📋 Step 2: Creating Target Groups...
echo Creating target group for API Gateway...
aws elbv2 create-target-group ^
  --name api-gateway-tg ^
  --protocol HTTP ^
  --port 3000 ^
  --vpc-id vpc-0c55e3f78b0b643a6 ^
  --target-type ip ^
  --region %AWS_REGION%

echo Creating target group for Service 1...
aws elbv2 create-target-group ^
  --name service1-tg ^
  --protocol HTTP ^
  --port 3001 ^
  --vpc-id vpc-0c55e3f78b0b643a6 ^
  --target-type ip ^
  --region %AWS_REGION%

echo Creating target group for Service 2...
aws elbv2 create-target-group ^
  --name service2-tg ^
  --protocol HTTP ^
  --port 3002 ^
  --vpc-id vpc-0c55e3f78b0b643a6 ^
  --target-type ip ^
  --region %AWS_REGION%

echo.
echo 📋 Step 3: Getting ALB ARN...
for /f "tokens=*" %%i in ('aws elbv2 describe-load-balancers --names multiservice-alb --region %AWS_REGION% --query "LoadBalancers[0].LoadBalancerArn" --output text') do set ALB_ARN=%%i

echo ALB ARN: %ALB_ARN%

echo.
echo 📋 Step 4: Creating Listener...
aws elbv2 create-listener ^
  --load-balancer-arn %ALB_ARN% ^
  --protocol HTTP ^
  --port 80 ^
  --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:%AWS_REGION%:936723057830:targetgroup/api-gateway-tg/00000000000000000000000000000000 ^
  --region %AWS_REGION%

echo.
echo 📋 Step 5: Getting ALB DNS Name...
for /f "tokens=*" %%i in ('aws elbv2 describe-load-balancers --names multiservice-alb --region %AWS_REGION% --query "LoadBalancers[0].DNSName" --output text') do set ALB_DNS=%%i

echo.
echo ✅ ALB Infrastructure Created!
echo 🌐 ALB DNS Name: %ALB_DNS%
echo.
echo 🧪 Test URLs (after updating services):
echo API Gateway: http://%ALB_DNS%/api/message1
echo Service 1: http://%ALB_DNS%/service1/message1
echo Service 2: http://%ALB_DNS%/service2/message2

pause 