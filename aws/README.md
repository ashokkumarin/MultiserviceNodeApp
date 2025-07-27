# AWS Deployment Guide for Multi-service Node.js Application

This guide will help you deploy your microservices application to AWS using ECS (Elastic Container Service).

## Prerequisites

1. **AWS CLI** installed and configured
2. **Docker** installed and running
3. **AWS Account** with appropriate permissions
4. **VPC and Subnets** created in your AWS account

## Deployment Options

### Option 1: Manual Deployment (Recommended for learning)

#### Step 1: Configure AWS CLI
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, and default region
```

#### Step 2: Update Configuration Files
1. Update `aws/deploy.sh`:
   - Replace `YOUR_ACCOUNT_ID` with your AWS account ID
   - Replace `us-east-1` with your preferred region

2. Update task definition files:
   - Replace `YOUR_ACCOUNT_ID` and `YOUR_REGION` in all JSON files

#### Step 3: Run Deployment Script
```bash
chmod +x aws/deploy.sh
./aws/deploy.sh
```

### Option 2: CloudFormation Deployment (Recommended for production)

#### Step 1: Deploy Infrastructure
```bash
aws cloudformation create-stack \
  --stack-name multiservice-app \
  --template-body file://aws/cloudformation-template.yml \
  --parameters ParameterKey=VpcId,ParameterValue=vpc-xxxxxxxxx \
               ParameterKey=SubnetIds,ParameterValue=subnet-xxxxxxxxx,subnet-yyyyyyyyy \
  --capabilities CAPABILITY_NAMED_IAM
```

#### Step 2: Build and Push Images
```bash
# Get your account ID and region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build and push images
docker build -t multiservice/api-gateway ./api-gateway
docker tag multiservice/api-gateway:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/multiservice/api-gateway:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/multiservice/api-gateway:latest

docker build -t multiservice/service1 ./service1
docker tag multiservice/service1:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/multiservice/service1:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/multiservice/service1:latest

docker build -t multiservice/service2 ./service2
docker tag multiservice/service2:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/multiservice/service2:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/multiservice/service2:latest
```

#### Step 3: Create ECS Services
```bash
# Create services (update security groups and subnets)
aws ecs create-service --cli-input-json file://aws/ecs-service-definitions.json
```

## Architecture Overview

```
Internet → Application Load Balancer → API Gateway (ECS) → Service1 (ECS) + Service2 (ECS)
```

## Important Notes

### 1. Networking
- Services communicate using service discovery or internal load balancers
- Update the API gateway to use service names instead of localhost
- Configure security groups to allow traffic between services

### 2. Environment Variables
- Consider using AWS Systems Manager Parameter Store for configuration
- Use environment variables for service URLs in production

### 3. Monitoring
- CloudWatch logs are automatically configured
- Set up CloudWatch alarms for monitoring
- Consider using AWS X-Ray for distributed tracing

### 4. Security
- Use IAM roles for service permissions
- Enable VPC flow logs
- Consider using AWS Secrets Manager for sensitive data

## Troubleshooting

### Common Issues:

1. **Port conflicts**: Ensure ports 3000, 3001, 3002 are not in use
2. **ECR authentication**: Run `aws ecr get-login-password` before pushing images
3. **IAM permissions**: Ensure your user has ECS, ECR, and CloudWatch permissions
4. **VPC configuration**: Ensure subnets are in the correct availability zones

### Useful Commands:

```bash
# Check ECS cluster status
aws ecs describe-clusters --clusters multiservice-cluster

# Check service status
aws ecs describe-services --cluster multiservice-cluster --services api-gateway-service

# View logs
aws logs describe-log-groups --log-group-name-prefix /ecs

# Get task details
aws ecs list-tasks --cluster multiservice-cluster
```

## Cost Optimization

1. **Use Fargate Spot** for non-critical workloads
2. **Right-size** CPU and memory allocations
3. **Set up auto-scaling** based on demand
4. **Use CloudWatch** to monitor resource usage

## Next Steps

1. Set up CI/CD pipeline using AWS CodePipeline
2. Configure auto-scaling policies
3. Set up monitoring and alerting
4. Implement blue-green deployments
5. Add SSL/TLS certificates using AWS Certificate Manager 