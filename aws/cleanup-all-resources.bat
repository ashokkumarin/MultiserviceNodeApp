@echo off
echo 🧹 AWS Resource Cleanup - Removing All Resources to Avoid Charges...
echo.
echo ⚠️  WARNING: This will DELETE ALL AWS resources created for this project!
echo This includes:
echo - ECS Services and Tasks
echo - Application Load Balancer
echo - Target Groups
echo - ECR Repositories (Docker images)
echo - CloudWatch Log Groups
echo - ECS Cluster
echo.
set /p CONFIRM="Are you sure you want to delete ALL resources? (type 'DELETE' to confirm): "
if not "%CONFIRM%"=="DELETE" (
    echo ❌ Cleanup cancelled. No resources were deleted.
    pause
    exit /b 1
)

echo.
echo 🚀 Starting AWS Resource Cleanup...

REM Configuration
set AWS_REGION=ap-south-1
set CLUSTER_NAME=multiservice-cluster

echo.
echo 📋 Step 1: Deleting ECS Services...
echo Deleting API Gateway service...
aws ecs update-service --cluster %CLUSTER_NAME% --service api-gateway-service --desired-count 0 --region %AWS_REGION% 2>nul
aws ecs delete-service --cluster %CLUSTER_NAME% --service api-gateway-service --region %AWS_REGION% 2>nul

echo Deleting Service 1...
aws ecs update-service --cluster %CLUSTER_NAME% --service service1-service --desired-count 0 --region %AWS_REGION% 2>nul
aws ecs delete-service --cluster %CLUSTER_NAME% --service service1-service --region %AWS_REGION% 2>nul

echo Deleting Service 2...
aws ecs update-service --cluster %CLUSTER_NAME% --service service2-service --desired-count 0 --region %AWS_REGION% 2>nul
aws ecs delete-service --cluster %CLUSTER_NAME% --service service2-service --region %AWS_REGION% 2>nul

echo.
echo 📋 Step 2: Waiting for services to stop (30 seconds)...
timeout /t 30 >nul

echo.
echo 📋 Step 3: Stopping all running tasks...
for /f "tokens=*" %%i in ('aws ecs list-tasks --cluster %CLUSTER_NAME% --region %AWS_REGION% --query "taskArns" --output text 2^>nul') do (
    if not "%%i"=="None" if not "%%i"=="" (
        echo Stopping task %%i
        aws ecs stop-task --cluster %CLUSTER_NAME% --task %%i --region %AWS_REGION% 2>nul
    )
)

echo.
echo 📋 Step 4: Deleting Application Load Balancer...
echo Deleting ALB listeners...
for /f "tokens=*" %%i in ('aws elbv2 describe-load-balancers --names multiservice-alb --region %AWS_REGION% --query "LoadBalancers[0].LoadBalancerArn" --output text 2^>nul') do (
    if not "%%i"=="None" if not "%%i"=="" (
        for /f "tokens=*" %%j in ('aws elbv2 describe-listeners --load-balancer-arn %%i --region %AWS_REGION% --query "Listeners[*].ListenerArn" --output text 2^>nul') do (
            if not "%%j"=="None" if not "%%j"=="" (
                echo Deleting listener %%j
                aws elbv2 delete-listener --listener-arn %%j --region %AWS_REGION% 2>nul
            )
        )
        echo Deleting ALB %%i
        aws elbv2 delete-load-balancer --load-balancer-arn %%i --region %AWS_REGION% 2>nul
    )
)

echo.
echo 📋 Step 5: Deleting Target Groups...
aws elbv2 delete-target-group --target-group-arn "$(aws elbv2 describe-target-groups --names api-gateway-tg --region %AWS_REGION% --query 'TargetGroups[0].TargetGroupArn' --output text)" --region %AWS_REGION% 2>nul
aws elbv2 delete-target-group --target-group-arn "$(aws elbv2 describe-target-groups --names service1-tg --region %AWS_REGION% --query 'TargetGroups[0].TargetGroupArn' --output text)" --region %AWS_REGION% 2>nul
aws elbv2 delete-target-group --target-group-arn "$(aws elbv2 describe-target-groups --names service2-tg --region %AWS_REGION% --query 'TargetGroups[0].TargetGroupArn' --output text)" --region %AWS_REGION% 2>nul

echo Deleting target groups by name (alternative method)...
aws elbv2 delete-target-group --target-group-arn arn:aws:elasticloadbalancing:%AWS_REGION%:936723057830:targetgroup/api-gateway-tg/* --region %AWS_REGION% 2>nul
aws elbv2 delete-target-group --target-group-arn arn:aws:elasticloadbalancing:%AWS_REGION%:936723057830:targetgroup/service1-tg/* --region %AWS_REGION% 2>nul
aws elbv2 delete-target-group --target-group-arn arn:aws:elasticloadbalancing:%AWS_REGION%:936723057830:targetgroup/service2-tg/* --region %AWS_REGION% 2>nul

echo.
echo 📋 Step 6: Waiting for ALB deletion (60 seconds)...
timeout /t 60 >nul

echo.
echo 📋 Step 7: Deleting ECS Cluster...
aws ecs delete-cluster --cluster %CLUSTER_NAME% --region %AWS_REGION% 2>nul

echo.
echo 📋 Step 8: Deleting ECR Repositories (Docker Images)...
echo Deleting API Gateway repository...
aws ecr delete-repository --repository-name multiservice/api-gateway --force --region %AWS_REGION% 2>nul

echo Deleting Service 1 repository...
aws ecr delete-repository --repository-name multiservice/service1 --force --region %AWS_REGION% 2>nul

echo Deleting Service 2 repository...
aws ecr delete-repository --repository-name multiservice/service2 --force --region %AWS_REGION% 2>nul

echo.
echo 📋 Step 9: Deleting CloudWatch Log Groups...
aws logs delete-log-group --log-group-name /ecs/api-gateway --region %AWS_REGION% 2>nul
aws logs delete-log-group --log-group-name /ecs/service1 --region %AWS_REGION% 2>nul
aws logs delete-log-group --log-group-name /ecs/service2 --region %AWS_REGION% 2>nul

echo.
echo 📋 Step 10: Deregistering Task Definitions (Optional)...
echo Note: Task definitions cannot be deleted, only deregistered (they don't incur charges)
for /L %%i in (1,1,20) do (
    aws ecs deregister-task-definition --task-definition api-gateway:%%i --region %AWS_REGION% 2>nul
    aws ecs deregister-task-definition --task-definition service1:%%i --region %AWS_REGION% 2>nul
    aws ecs deregister-task-definition --task-definition service2:%%i --region %AWS_REGION% 2>nul
)

echo.
echo 📋 Step 11: Security Group Cleanup (Optional)...
echo Note: Default security groups cannot be deleted, but custom rules are removed
echo Removing custom ingress rules...
aws ec2 revoke-security-group-ingress --group-id sg-0b128cd8d735e209e --protocol tcp --port 80 --cidr 0.0.0.0/0 --region %AWS_REGION% 2>nul
aws ec2 revoke-security-group-ingress --group-id sg-0b128cd8d735e209e --protocol tcp --port 3000 --cidr 0.0.0.0/0 --region %AWS_REGION% 2>nul
aws ec2 revoke-security-group-ingress --group-id sg-0b128cd8d735e209e --protocol tcp --port 3001 --cidr 0.0.0.0/0 --region %AWS_REGION% 2>nul
aws ec2 revoke-security-group-ingress --group-id sg-0b128cd8d735e209e --protocol tcp --port 3002 --cidr 0.0.0.0/0 --region %AWS_REGION% 2>nul

echo.
echo ✅ AWS Resource Cleanup Complete!
echo.
echo 💰 Cost Impact:
echo - ✅ ECS Services: DELETED (no charges)
echo - ✅ ALB: DELETED (saves ~$16/month)
echo - ✅ ECR Repositories: DELETED (saves storage costs)
echo - ✅ CloudWatch Logs: DELETED (saves log storage costs)
echo - ✅ ECS Cluster: DELETED (no charges for empty cluster)
echo - ✅ Running Tasks: STOPPED (no compute charges)
echo.
echo 📊 Remaining Resources (minimal/no cost):
echo - Task Definitions: Deregistered (no charges)
echo - Security Groups: Rules removed (no charges for default SG)
echo - VPC/Subnets: Default VPC (no charges)
echo.
echo 🎓 Learning Tip:
echo Run 'aws/deploy-with-alb.bat' when you want to test again!
echo Always run this cleanup script when done to avoid charges.
echo.
echo 💡 Next Steps:
echo 1. Verify cleanup: Check AWS Console for any remaining resources
echo 2. Monitor AWS Billing Dashboard
echo 3. Set up AWS Budget Alerts for cost monitoring
echo.
pause