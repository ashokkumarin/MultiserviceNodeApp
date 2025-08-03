@echo off
setlocal enabledelayedexpansion

REM Get Public IPs and Fix Networking Issues
REM This script will help you get public IPs for your ECS tasks

echo 🔍 Getting Public IPs for your ECS tasks...
echo.

REM Configuration
set AWS_REGION=ap-south-1
set CLUSTER_NAME=multiservice-cluster

REM Get all running tasks
echo 📋 Getting running tasks...
for /f "tokens=*" %%i in ('aws ecs list-tasks --cluster %CLUSTER_NAME% --region %AWS_REGION% --query "taskArns" --output text') do set TASK_ARNS=%%i

if "%TASK_ARNS%"=="" (
    echo ❌ No running tasks found.
    echo.
    echo 🔧 To fix this:
    echo 1. Check if services are running: aws ecs describe-services --cluster %CLUSTER_NAME% --services api-gateway-service
    echo 2. Check service status in AWS Console
    pause
    exit /b 1
)

echo ✅ Found running tasks. Getting details...
echo.

REM Process each task
for %%t in (%TASK_ARNS%) do (
    echo 📦 Task: %%t
    echo ----------------------------------------
    
    REM Get task details
    for /f "tokens=*" %%i in ('aws ecs describe-tasks --cluster %CLUSTER_NAME% --tasks %%t --region %AWS_REGION% --query "tasks[0].lastStatus" --output text') do set TASK_STATUS=%%i
    echo Status: !TASK_STATUS!
    
    REM Get network interface ID
    for /f "tokens=*" %%i in ('aws ecs describe-tasks --cluster %CLUSTER_NAME% --tasks %%t --region %AWS_REGION% --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value" --output text') do set NETWORK_INTERFACE_ID=%%i
    
    if not "!NETWORK_INTERFACE_ID!"=="" (
        echo Network Interface ID: !NETWORK_INTERFACE_ID!
        
        REM Get public IP from network interface
        for /f "tokens=*" %%i in ('aws ec2 describe-network-interfaces --network-interface-ids !NETWORK_INTERFACE_ID! --region %AWS_REGION% --query "NetworkInterfaces[0].Association.PublicIp" --output text') do set PUBLIC_IP=%%i
        
        if not "!PUBLIC_IP!"=="" and not "!PUBLIC_IP!"=="None" (
            echo 🌐 Public IP: !PUBLIC_IP!
            echo.
            echo 🧪 Test your services:
            echo curl http://!PUBLIC_IP!:3000/api/message1
            echo curl http://!PUBLIC_IP!:3000/service1/message1
            echo curl http://!PUBLIC_IP!:3000/service2/message2
        ) else (
            echo ❌ No public IP found. This might be because:
            echo    - Task is in a private subnet
            echo    - Security group doesn't allow public access
            echo    - Network interface doesn't have public IP association
            echo.
            echo 🔧 To fix this, you can:
            echo 1. Check AWS Console for task details
            echo 2. Use Application Load Balancer instead
            echo 3. Configure public subnets
        )
    ) else (
        echo ❌ No network interface found
    )
    
    echo.
)

echo.
echo 📋 Alternative: Check AWS Console
echo https://console.aws.amazon.com/ecs/home?region=%AWS_REGION%#/clusters/%CLUSTER_NAME%/tasks
echo.
echo 💡 If no public IPs are found, consider:
echo 1. Using Application Load Balancer (recommended for production)
echo 2. Configuring public subnets
echo 3. Using AWS Console to check task details

pause 