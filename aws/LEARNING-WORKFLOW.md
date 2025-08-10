# 🎓 AWS Learning Workflow - Quick Reference

## 🚀 **Complete Learning Session**

### **1. Deploy (5-10 minutes)**
```bash
cd C:\Users\aasho\Documents\Code\MultiserviceNodeApp
aws\deploy-with-alb.bat
```

### **2. Test (2-3 minutes)**
```bash
aws\test-deployment.bat
```

### **3. Learn & Explore (30-60 minutes)**
- **AWS Console Exploration**
- **Test Different Scenarios**
- **Monitor Resources**

### **4. Cleanup (3-5 minutes)**
```bash
aws\cleanup-all-resources.bat
```

---

## 🧪 **Quick Test Commands**

```bash
# Get ALB DNS
aws elbv2 describe-load-balancers --names multiservice-alb --query "LoadBalancers[0].DNSName"

# Test endpoints manually
curl http://[ALB-DNS]/health
curl http://[ALB-DNS]/api/message1
curl http://[ALB-DNS]/service1/message1
curl http://[ALB-DNS]/service2/message2
```

---

## 📊 **Resource Monitoring**

```bash
# Check running services
aws ecs list-services --cluster multiservice-cluster

# Check running tasks
aws ecs list-tasks --cluster multiservice-cluster

# Check ALB status
aws elbv2 describe-load-balancers --names multiservice-alb

# Check target health
aws elbv2 describe-target-health --target-group-arn [TG-ARN]
```

---

## 💰 **Cost Management**

### **Session Costs:**
- **1 hour**: ~$0.10-0.30
- **2 hours**: ~$0.20-0.60
- **Forgot cleanup**: ~$1-2/day

### **Monthly Budget:**
- **Conservative learning**: $3-8/month
- **Intensive learning**: $8-15/month

---

## 🎯 **Learning Focus Areas**

### **Session 1: ECS Basics**
- [ ] Deploy services
- [ ] Understand task definitions
- [ ] Monitor container logs
- [ ] Practice cleanup

### **Session 2: Load Balancing**
- [ ] Explore ALB configuration
- [ ] Test target groups
- [ ] Monitor health checks
- [ ] Test routing rules

### **Session 3: Networking**
- [ ] Understand VPC concepts
- [ ] Security group configuration
- [ ] Internal vs external communication
- [ ] Network troubleshooting

### **Session 4: Scaling & Monitoring**
- [ ] Manual scaling
- [ ] CloudWatch metrics
- [ ] Log analysis
- [ ] Performance monitoring

---

## 🚨 **Emergency Commands**

### **If Things Go Wrong:**
```bash
# Force cleanup everything
aws\cleanup-all-resources.bat

# Check what's still running
aws ecs list-clusters
aws elbv2 describe-load-balancers
aws ecr describe-repositories

# Manual service deletion
aws ecs update-service --cluster multiservice-cluster --service [SERVICE] --desired-count 0
aws ecs delete-service --cluster multiservice-cluster --service [SERVICE]
```

### **If Cleanup Fails:**
```bash
# Manual ALB deletion
aws elbv2 delete-load-balancer --load-balancer-arn [ALB-ARN]

# Manual target group deletion
aws elbv2 delete-target-group --target-group-arn [TG-ARN]

# Manual ECR deletion
aws ecr delete-repository --repository-name [REPO] --force
```

---

## 📱 **Mobile Quick Reference**

### **Deploy → Test → Learn → Cleanup**

1. 🚀 `deploy-with-alb.bat`
2. 🧪 `test-deployment.bat`  
3. 🎓 **Explore AWS Console**
4. 🧹 `cleanup-all-resources.bat`

### **Key URLs:**
- AWS Console: https://console.aws.amazon.com
- ECS Services: https://console.aws.amazon.com/ecs
- Load Balancers: https://console.aws.amazon.com/ec2/home#LoadBalancers
- Billing: https://console.aws.amazon.com/billing

---

## 🎯 **Success Metrics**

### **Technical Learning:**
- [ ] Can deploy from scratch
- [ ] Understands ECS concepts
- [ ] Can troubleshoot issues
- [ ] Masters cleanup process

### **Cost Management:**
- [ ] Never forgets cleanup
- [ ] Monitors AWS billing
- [ ] Stays within budget
- [ ] Optimizes resource usage

---

## 📞 **Quick Help**

### **Common Issues:**
1. **ALB not responding**: Wait 2-3 minutes after deployment
2. **Service unhealthy**: Check security groups and health check path
3. **Internal communication failing**: Verify internal IPs in API Gateway
4. **Cleanup failing**: Run manual deletion commands

### **Resources:**
- AWS Documentation: https://docs.aws.amazon.com
- ECS Troubleshooting: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/troubleshooting.html
- ALB Troubleshooting: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-troubleshooting.html

**Remember: Deploy → Test → Learn → Cleanup! 🎓💰**