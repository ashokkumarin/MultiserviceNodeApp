@echo off
echo 🔍 Diagnosing Service Issues...
echo.

REM Configuration
set AWS_REGION=ap-south-1
set CLUSTER_NAME=multiservice-cluster

echo 📋 Step 1: Checking Service Status...
aws ecs describe-services --cluster %CLUSTER_NAME% --services api-gateway-service service1-service service2-service --query "services[*].{ServiceName:serviceName,Status:status,DesiredCount:desiredCount,RunningCount:runningCount,PendingCount:pendingCount}" --output table

echo.
echo 📋 Step 2: Checking Running Tasks...
aws ecs list-tasks --cluster %CLUSTER_NAME% --query "taskArns" --output table

echo.
echo 📋 Step 3: Getting Task Details...
for /f "tokens=*" %%i in ('aws ecs list-tasks --cluster %CLUSTER_NAME% --query "taskArns" --output text') do (
    echo Task: %%i
    aws ecs describe-tasks --cluster %CLUSTER_NAME% --tasks %%i --query "tasks[0].{Status:lastStatus,HealthStatus:healthStatus,StoppedReason:stoppedReason}" --output table
    echo.
)

echo.
echo 📋 Step 4: Checking Security Group Rules...
aws ec2 describe-security-groups --group-ids sg-0b128cd8d735e209e --query "SecurityGroups[0].IpPermissions" --output table

echo.
echo 📋 Step 5: Testing Network Connectivity...
echo Testing API Gateway: 13.233.121.64:3000
ping -n 1 13.233.121.64
echo.

echo Testing Service 1: 3.111.39.203:3001
ping -n 1 3.111.39.203
echo.

echo Testing Service 2: 13.201.25.52:3002
ping -n 1 13.201.25.52
echo.

echo.
echo 💡 If services are running but not responding:
echo 1. Check CloudWatch logs for application errors
echo 2. Verify the application is listening on the correct ports
echo 3. Check if the API Gateway is trying to proxy to container names
echo 4. Consider using Application Load Balancer for proper routing

pause 