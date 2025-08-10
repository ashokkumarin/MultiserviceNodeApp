@echo off
echo 🧪 Testing ALB Deployment - Verifying All Endpoints...
echo.

REM Configuration
set AWS_REGION=ap-south-1

echo 📋 Step 1: Getting ALB DNS Name...
for /f "tokens=*" %%i in ('aws elbv2 describe-load-balancers --names multiservice-alb --region %AWS_REGION% --query "LoadBalancers[0].DNSName" --output text 2^>nul') do set ALB_DNS=%%i

if "%ALB_DNS%"=="None" (
    echo ❌ ALB not found! Make sure you've deployed using deploy-with-alb.bat
    pause
    exit /b 1
)

echo ✅ ALB DNS: %ALB_DNS%
echo.

echo 📋 Step 2: Waiting for services to be ready (30 seconds)...
timeout /t 30 >nul

echo.
echo 📋 Step 3: Testing Endpoints...

echo.
echo 🔍 Testing Health Check...
curl -s http://%ALB_DNS%/health
if %ERRORLEVEL% EQU 0 (
    echo ✅ Health check: PASSED
) else (
    echo ❌ Health check: FAILED
)

echo.
echo 🔍 Testing API Gateway Direct...
curl -s http://%ALB_DNS%/api/message1
if %ERRORLEVEL% EQU 0 (
    echo ✅ API Gateway: PASSED
) else (
    echo ❌ API Gateway: FAILED
)

echo.
echo 🔍 Testing Service 1 via Proxy...
curl -s http://%ALB_DNS%/service1/message1
if %ERRORLEVEL% EQU 0 (
    echo ✅ Service 1 Proxy: PASSED
) else (
    echo ❌ Service 1 Proxy: FAILED
)

echo.
echo 🔍 Testing Service 2 via Proxy...
curl -s http://%ALB_DNS%/service2/message2
if %ERRORLEVEL% EQU 0 (
    echo ✅ Service 2 Proxy: PASSED
) else (
    echo ❌ Service 2 Proxy: FAILED
)

echo.
echo 📋 Step 4: Checking ECS Service Status...
aws ecs describe-services --cluster multiservice-cluster --services api-gateway-service service1-service service2-service --query "services[*].{ServiceName:serviceName,Status:status,Running:runningCount,Desired:desiredCount}" --output table

echo.
echo 📋 Step 5: Checking ALB Target Health...
for /f "tokens=*" %%i in ('aws elbv2 describe-target-groups --names api-gateway-tg --region %AWS_REGION% --query "TargetGroups[0].TargetGroupArn" --output text 2^>nul') do (
    if not "%%i"=="None" if not "%%i"=="" (
        echo API Gateway Target Health:
        aws elbv2 describe-target-health --target-group-arn %%i --query "TargetHealthDescriptions[*].{Target:Target.Id,Health:TargetHealth.State}" --output table
    )
)

echo.
echo 🎯 **Test Summary:**
echo.
echo 🌐 **ALB URL**: http://%ALB_DNS%
echo.
echo 📝 **Test URLs:**
echo - Health: http://%ALB_DNS%/health
echo - API Gateway: http://%ALB_DNS%/api/message1  
echo - Service 1: http://%ALB_DNS%/service1/message1
echo - Service 2: http://%ALB_DNS%/service2/message2
echo.
echo 💰 **Cost Reminder:**
echo This deployment costs ~$0.10-0.30 per hour
echo Run 'aws\cleanup-all-resources.bat' when done testing!
echo.
echo 🎓 **Learning Activities:**
echo 1. Explore AWS ECS Console
echo 2. Check CloudWatch Logs
echo 3. Monitor ALB Target Groups
echo 4. Test scaling by changing desired count
echo 5. Examine security groups and networking
echo.
pause