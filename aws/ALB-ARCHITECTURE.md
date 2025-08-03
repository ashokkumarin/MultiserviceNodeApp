# ALB Architecture with Internal Communication

## 🏗️ **New Architecture Overview**

### **Before (Public IPs):**
```
Internet → API Gateway (Public IP) → Service1 (Public IP) → Service2 (Public IP)
```

### **After (ALB + Internal Communication):**
```
Internet → ALB → API Gateway → Service1 (Internal) → Service2 (Internal)
```

## 🔧 **Key Changes Made**

### **1. API Gateway Updates**
- **Removed hardcoded public IPs**
- **Added internal service discovery** using service names
- **Updated service URLs** to use internal communication

```javascript
// OLD (Insecure - Public IPs)
const SERVICE1_URL = 'http://13.233.32.8:3001';
const SERVICE2_URL = 'http://35.154.157.110:3002';

// NEW (Secure - Internal Service Discovery)
const SERVICE1_URL = 'http://service1-service:3001';
const SERVICE2_URL = 'http://service2-service:3002';
```

### **2. ALB Infrastructure**
- **Application Load Balancer** for external traffic
- **Target Groups** for each service
- **Internal communication** between services
- **Service discovery** using ECS service names

### **3. Security Improvements**
- ✅ **No hardcoded IPs** in code
- ✅ **Internal communication** between services
- ✅ **ALB handles external traffic**
- ✅ **Service discovery** using service names
- ✅ **Proper load balancing**

## 🚀 **Deployment Scripts**

### **Option 1: Complete ALB Deployment**
```bash
# Deploy everything with ALB
aws/deploy-with-alb.bat
```

### **Option 2: Update Existing Services**
```bash
# Update existing services to use ALB
aws/update-services-with-alb.bat
```

### **Option 3: Create ALB Infrastructure Only**
```bash
# Create ALB infrastructure
aws/create-alb-infrastructure.bat
```

## 🌐 **Service Endpoints**

After deployment, you'll access your services through the ALB:

```
http://[ALB-DNS-NAME]/api/message1          # API Gateway direct
http://[ALB-DNS-NAME]/service1/message1     # Service 1 via API Gateway
http://[ALB-DNS-NAME]/service2/message2     # Service 2 via API Gateway
```

## 🔍 **Architecture Benefits**

### **Security:**
- **Internal communication** between services
- **No public IP exposure** for internal services
- **ALB handles external traffic** securely

### **Scalability:**
- **Load balancing** across multiple instances
- **Auto-scaling** capabilities
- **Health checks** and failover

### **Maintainability:**
- **No hardcoded IPs** to manage
- **Service discovery** using service names
- **Centralized traffic management**

### **Reliability:**
- **Health checks** ensure service availability
- **Automatic failover** if services fail
- **Load distribution** across healthy instances

## 📋 **AWS Resources Created**

1. **Application Load Balancer** (`multiservice-alb`)
2. **Target Groups**:
   - `api-gateway-tg` (Port 3000)
   - `service1-tg` (Port 3001)
   - `service2-tg` (Port 3002)
3. **ECS Services** with ALB integration
4. **Task Definitions** with proper networking

## 🧪 **Testing the New Architecture**

### **1. Check ALB DNS Name:**
```bash
aws elbv2 describe-load-balancers --names multiservice-alb --query "LoadBalancers[0].DNSName"
```

### **2. Test Endpoints:**
```bash
# Test API Gateway
curl http://[ALB-DNS-NAME]/api/message1

# Test Service 1 via API Gateway
curl http://[ALB-DNS-NAME]/service1/message1

# Test Service 2 via API Gateway
curl http://[ALB-DNS-NAME]/service2/message2
```

### **3. Check Service Health:**
```bash
# Check ALB target health
aws elbv2 describe-target-health --target-group-arn [TARGET-GROUP-ARN]
```

## 🔄 **Migration from Public IPs**

### **Step 1: Deploy ALB Infrastructure**
```bash
aws/create-alb-infrastructure.bat
```

### **Step 2: Update API Gateway Code**
- Remove hardcoded IPs
- Use service discovery names
- Rebuild and push Docker image

### **Step 3: Update ECS Services**
```bash
aws/update-services-with-alb.bat
```

### **Step 4: Test New Endpoints**
- Use ALB DNS name instead of public IPs
- Verify internal communication works

## 💡 **Best Practices**

1. **Use environment variables** for service URLs in production
2. **Implement proper health checks** for all services
3. **Set up CloudWatch monitoring** for ALB and services
4. **Configure auto-scaling** based on load
5. **Use HTTPS** for production traffic
6. **Implement proper logging** and monitoring

## 🚨 **Important Notes**

- **ALB costs** will be incurred (~$16/month)
- **Service names** must match ECS service names exactly
- **Internal communication** requires services to be in the same VPC
- **Target groups** must be configured correctly for health checks
- **Security groups** must allow internal communication

This architecture provides a much more secure, scalable, and production-ready solution for your multi-service application! 