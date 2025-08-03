@echo off
setlocal enabledelayedexpansion

REM Get Public IPs of ECS Services
REM This script will show you the public IPs of your running services

echo 🔍 Getting Public IPs of your services...
echo.

REM Configuration
set AWS_REGION=ap-south-1
set CLUSTER_NAME=multiservice-cluster

REM Get all running tasks
echo 📋 Getting running tasks...
for /f "tokens=*" %%i in ('aws ecs list-tasks --cluster %CLUSTER_NAME% --region %AWS_REGION% --query "taskArns" --output text') do set TASK_ARNS=%%i

if "%TASK_ARNS%"=="" (
    echo ❌ No running tasks found. Your services might not be running yet.
    echo.
    echo 🔧 To fix this:
    echo 1. Check if services are created: aws ecs list-services --cluster %CLUSTER_NAME% --region %AWS_REGION%
    echo 2. Check service status: aws ecs describe-services --cluster %CLUSTER_NAME% --services api-gateway-service --region %AWS_REGION%
    echo 3. If services are failing, you may need to create the IAM role: ecsTaskExecutionRole
    pause
    exit /b 1
)

echo ✅ Found running tasks. Getting details...

REM Get details for each task
for %%t in (%TASK_ARNS%) do (
    echo.
    echo 📦 Task: %%t
    echo ----------------------------------------
    
    REM Get task details
    for /f "tokens=*" %%i in ('aws ecs describe-tasks --cluster %CLUSTER_NAME% --tasks %%t --region %AWS_REGION% --query "tasks[0].{TaskDefinition:taskDefinitionArn,PublicIP:attachments[0].details[?name=='publicIp'].value,Status:lastStatus}" --output text') do (
        echo Task Definition: %%i
    )
    
    REM Get public IP specifically
    for /f "tokens=*" %%i in ('aws ecs describe-tasks --cluster %CLUSTER_NAME% --tasks %%t --region %AWS_REGION% --query "tasks[0].attachments[0].details[?name=='publicIp'].value" --output text') do (
        if not "%%i"=="" (
            echo 🌐 Public IP: %%i
            echo.
            echo 🧪 Test your services:
            echo curl http://%%i:3000/api/message1
            echo curl http://%%i:3000/service1/message1
            echo curl http://%%i:3000/service2/message2
        ) else (
            echo ❌ No public IP found (task might be in private subnet)
        )
    )
)

echo.
echo 📋 Alternative: Check AWS Console
echo https://console.aws.amazon.com/ecs/home?region=%AWS_REGION%#/clusters/%CLUSTER_NAME%/tasks
echo.

pause 