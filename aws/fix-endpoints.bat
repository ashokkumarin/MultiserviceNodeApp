@echo off
setlocal enabledelayedexpansion

echo 🔧 Fixing Endpoint Issues...
echo.

REM Configuration
set AWS_REGION=ap-south-1
set CLUSTER_NAME=multiservice-cluster
set SECURITY_GROUP_ID=sg-0b128cd8d735e209e

echo 📋 Step 1: Adding Security Group Rules...
echo Adding port 3000 (API Gateway)...
aws ec2 authorize-security-group-ingress --group-id %SECURITY_GROUP_ID% --protocol tcp --port 3000 --cidr 0.0.0.0/0 --region %AWS_REGION%

echo Adding port 3001 (Service 1)...
aws ec2 authorize-security-group-ingress --group-id %SECURITY_GROUP_ID% --protocol tcp --port 3001 --cidr 0.0.0.0/0 --region %AWS_REGION%

echo Adding port 3002 (Service 2)...
aws ec2 authorize-security-group-ingress --group-id %SECURITY_GROUP_ID% --protocol tcp --port 3002 --cidr 0.0.0.0/0 --region %AWS_REGION%

echo.
echo 📋 Step 2: Getting Public IPs...
for /f "tokens=*" %%i in ('aws ecs list-tasks --cluster %CLUSTER_NAME% --region %AWS_REGION% --query "taskArns" --output text') do set TASK_ARNS=%%i

echo Found tasks: %TASK_ARNS%
echo.

REM Get public IPs for each task
set TASK_COUNT=0
for %%t in (%TASK_ARNS%) do (
    set /a TASK_COUNT+=1
    
    REM Extract task ID from ARN
    for /f "tokens=6 delims=/" %%i in ("%%t") do set TASK_ID=%%i
    
    echo 📦 Task %TASK_COUNT%: !TASK_ID!
    
    REM Get network interface ID
    for /f "tokens=*" %%i in ('aws ecs describe-tasks --cluster %CLUSTER_NAME% --tasks !TASK_ID! --region %AWS_REGION% --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value" --output text') do set NETWORK_INTERFACE_ID=%%i
    
    if not "!NETWORK_INTERFACE_ID!"=="" (
        echo Network Interface: !NETWORK_INTERFACE_ID!
        
        REM Get public IP
        for /f "tokens=*" %%i in ('aws ec2 describe-network-interfaces --network-interface-ids !NETWORK_INTERFACE_ID! --region %AWS_REGION% --query "NetworkInterfaces[0].Association.PublicIp" --output text') do set PUBLIC_IP=%%i
        
        if not "!PUBLIC_IP!"=="" and not "!PUBLIC_IP!"=="None" (
            echo 🌐 Public IP: !PUBLIC_IP!
            
            REM Store IPs for testing
            if !TASK_COUNT!==1 set API_GATEWAY_IP=!PUBLIC_IP!
            if !TASK_COUNT!==2 set SERVICE1_IP=!PUBLIC_IP!
            if !TASK_COUNT!==3 set SERVICE2_IP=!PUBLIC_IP!
        ) else (
            echo ❌ No public IP found
        )
    )
    echo.
)

echo.
echo 📋 Step 3: Testing Endpoints...
echo.

if not "%API_GATEWAY_IP%"=="" (
    echo 🧪 Testing API Gateway endpoints:
    echo Testing: http://%API_GATEWAY_IP%:3000/api/message1
    curl -s -o nul -w "HTTP Status: %%{http_code}\n" http://%API_GATEWAY_IP%:3000/api/message1
    
    echo Testing: http://%API_GATEWAY_IP%:3000/service1/message1
    curl -s -o nul -w "HTTP Status: %%{http_code}\n" http://%API_GATEWAY_IP%:3000/service1/message1
    
    echo Testing: http://%API_GATEWAY_IP%:3000/service2/message2
    curl -s -o nul -w "HTTP Status: %%{http_code}\n" http://%API_GATEWAY_IP%:3000/service2/message2
    echo.
)

if not "%SERVICE1_IP%"=="" (
    echo 🧪 Testing Service 1 directly:
    echo Testing: http://%SERVICE1_IP%:3001/message1
    curl -s -o nul -w "HTTP Status: %%{http_code}\n" http://%SERVICE1_IP%:3001/message1
    echo.
)

if not "%SERVICE2_IP%"=="" (
    echo 🧪 Testing Service 2 directly:
    echo Testing: http://%SERVICE2_IP%:3002/message2
    curl -s -o nul -w "HTTP Status: %%{http_code}\n" http://%SERVICE2_IP%:3002/message2
    echo.
)

echo.
echo 📋 Step 4: Summary...
echo.
echo 🌐 Your Public IPs:
if not "%API_GATEWAY_IP%"=="" echo API Gateway: %API_GATEWAY_IP%
if not "%SERVICE1_IP%"=="" echo Service 1: %SERVICE1_IP%
if not "%SERVICE2_IP%"=="" echo Service 2: %SERVICE2_IP%
echo.

echo 🧪 Test URLs:
if not "%API_GATEWAY_IP%"=="" (
    echo API Gateway: http://%API_GATEWAY_IP%:3000/api/message1
    echo Service 1 via Gateway: http://%API_GATEWAY_IP%:3000/service1/message1
    echo Service 2 via Gateway: http://%API_GATEWAY_IP%:3000/service2/message2
)
if not "%SERVICE1_IP%"=="" echo Service 1 Direct: http://%SERVICE1_IP%:3001/message1
if not "%SERVICE2_IP%"=="" echo Service 2 Direct: http://%SERVICE2_IP%:3002/message2

echo.
echo 💡 If endpoints still don't work:
echo 1. Check AWS Console for task logs
echo 2. Verify security group rules were added
echo 3. Check if services are actually running
echo 4. Consider using Application Load Balancer

pause 