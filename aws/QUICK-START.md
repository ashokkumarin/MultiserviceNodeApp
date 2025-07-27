# 🚀 Quick Start: Deploy to AWS ECS

This guide will help you deploy your microservices to AWS in under 10 minutes!

## Prerequisites

1. **AWS Account** - Sign up at [aws.amazon.com](https://aws.amazon.com)
2. **AWS CLI** - Install from [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
3. **Docker** - Already installed on your system

## Step 1: Configure AWS CLI

```bash
aws configure
```

Enter your:
- **AWS Access Key ID**
- **AWS Secret Access Key** 
- **Default region** (e.g., `us-east-1`)
- **Default output format** (e.g., `json`)

> 💡 **Need AWS credentials?** Go to AWS Console → IAM → Users → Your User → Security credentials → Create access key

## Step 2: Run Deployment Script

### Option A: Windows (Recommended)
```bash
aws/deploy-simple.bat
```

### Option B: Linux/Mac
```bash
chmod +x aws/deploy-simple.sh
./aws/deploy-simple.sh
```

## Step 3: Create ECS Services (Manual)

After the script completes, you need to create ECS services:

### 3.1 Go to AWS Console
1. Open [AWS ECS Console](https://console.aws.amazon.com/ecs/)
2. Select your region
3. Click on "Clusters" → "multiservice-cluster"

### 3.2 Create Service 1
1. Click "Create Service"
2. **Launch type**: FARGATE
3. **Task definition**: service1 (latest)
4. **Service name**: service1-service
5. **Number of tasks**: 1
6. **VPC**: Select your default VPC
7. **Subnets**: Select 2 subnets
8. **Security groups**: Create new or use default
9. **Auto-assign public IP**: ENABLED
10. Click "Create Service"

### 3.3 Create Service 2
Repeat the same steps for service2

### 3.4 Create API Gateway Service
1. Click "Create Service"
2. **Launch type**: FARGATE
3. **Task definition**: api-gateway (latest)
4. **Service name**: api-gateway-service
5. **Number of tasks**: 1
6. **VPC**: Select your default VPC
7. **Subnets**: Select 2 subnets
8. **Security groups**: Create new or use default
9. **Auto-assign public IP**: ENABLED
10. Click "Create Service"

## Step 4: Test Your Application

### Get Service URLs
1. Go to ECS Console → Clusters → multiservice-cluster
2. Click on "Tasks" tab
3. Click on a running task
4. Copy the "Public IP" address

### Test Endpoints
```bash
# Replace YOUR_PUBLIC_IP with the actual IP
curl http://YOUR_PUBLIC_IP:3000/api/message1
curl http://YOUR_PUBLIC_IP:3000/service1/message1
curl http://YOUR_PUBLIC_IP:3000/service2/message2
```

## 🎉 Congratulations!

Your microservices are now running on AWS ECS!

## 🔧 Troubleshooting

### Common Issues:

1. **"Access Denied" errors**
   - Ensure your AWS user has ECS, ECR, and CloudWatch permissions
   - Add these policies: `AmazonECS-FullAccess`, `AmazonEC2ContainerRegistryFullAccess`

2. **"No VPC found"**
   - Use the default VPC or create a new one
   - Ensure you have at least 2 subnets in different availability zones

3. **"Security group not found"**
   - Create a new security group or use the default
   - Ensure it allows inbound traffic on ports 3000, 3001, 3002

4. **"Task failed to start"**
   - Check CloudWatch logs for error messages
   - Verify task definition and service configuration

### Useful Commands:

```bash
# Check cluster status
aws ecs describe-clusters --clusters multiservice-cluster

# List running tasks
aws ecs list-tasks --cluster multiservice-cluster

# Get task details
aws ecs describe-tasks --cluster multiservice-cluster --tasks TASK_ARN

# View logs
aws logs describe-log-groups --log-group-name-prefix /ecs
```

## 📊 Monitoring

- **CloudWatch Logs**: Automatic logging for all services
- **ECS Console**: Monitor service health and performance
- **CloudWatch Metrics**: CPU, memory, and network metrics

## 💰 Cost Optimization

- **Fargate Spot**: Use for non-critical workloads (50-70% cost savings)
- **Right-sizing**: Monitor and adjust CPU/memory allocations
- **Auto-scaling**: Set up scaling policies based on demand

## 🚀 Next Steps

1. **Set up Application Load Balancer** for better traffic management
2. **Configure auto-scaling** based on CPU/memory usage
3. **Set up monitoring and alerting** with CloudWatch
4. **Implement CI/CD pipeline** with GitHub Actions
5. **Add SSL/TLS certificates** using AWS Certificate Manager

## 📞 Need Help?

- Check the [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- Review the [detailed deployment guide](README.md)
- Create an issue in this repository 