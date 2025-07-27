# Multi-service Node.js Application

A microservices architecture built with Node.js, Express, and Docker, designed to be deployed on AWS ECS.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   API Gateway   │    │    Service 1    │    │    Service 2    │
│   (Port 3000)   │◄──►│   (Port 3001)   │    │   (Port 3002)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Node.js (v14 or higher)
- Docker
- Docker Compose

### Local Development

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd MultiserviceNodeApp
   ```

2. **Run with Docker Compose**
   ```bash
   docker-compose up --build
   ```

3. **Test the services**
   ```bash
   # API Gateway
   curl http://localhost:3000/api/message1
   
   # Service 1
   curl http://localhost:3000/service1/message1
   
   # Service 2
   curl http://localhost:3000/service2/message2
   ```

## 📁 Project Structure

```
MultiserviceNodeApp/
├── api-gateway/          # API Gateway service
│   ├── Dockerfile
│   ├── index.js
│   └── package.json
├── service1/             # First microservice
│   ├── Dockerfile
│   ├── index.js
│   └── package.json
├── service2/             # Second microservice
│   ├── Dockerfile
│   ├── index.js
│   └── package.json
├── aws/                  # AWS deployment files
│   ├── deploy.sh
│   ├── cloudformation-template.yml
│   └── README.md
├── docker-compose.yml    # Local development setup
└── README.md
```

## 🐳 Docker

### Build Images
```bash
# Build all services
docker-compose build

# Build individual service
docker build -t api-gateway ./api-gateway
```

### Run Containers
```bash
# Run all services
docker-compose up

# Run in background
docker-compose up -d

# Stop services
docker-compose down
```

## ☁️ AWS Deployment

This application is designed to be deployed on AWS ECS (Elastic Container Service).

### Prerequisites
- AWS CLI configured
- AWS account with appropriate permissions
- VPC and subnets created

### Deployment Options

1. **Manual Deployment** (see `aws/deploy.sh`)
2. **CloudFormation** (see `aws/cloudformation-template.yml`)

For detailed deployment instructions, see [AWS Deployment Guide](aws/README.md).

## 🔧 Configuration

### Environment Variables

Create `.env` files in each service directory for environment-specific configuration:

```bash
# api-gateway/.env
NODE_ENV=production
PORT=3000

# service1/.env
NODE_ENV=production
PORT=3001

# service2/.env
NODE_ENV=production
PORT=3002
```

### Service Communication

In production (AWS ECS), services communicate using service names:
- `http://service1:3001`
- `http://service2:3002`

In local development, services communicate via localhost:
- `http://localhost:3001`
- `http://localhost:3002`

## 🧪 Testing

### Manual Testing
```bash
# Test API Gateway
curl http://localhost:3000/api/message1

# Test Service 1 through API Gateway
curl http://localhost:3000/service1/message1

# Test Service 2 through API Gateway
curl http://localhost:3000/service2/message2
```

### Health Checks
Each service includes a health check endpoint:
- API Gateway: `GET /health`
- Service 1: `GET /health`
- Service 2: `GET /health`

## 📊 Monitoring

### Logs
- All services log to stdout/stderr
- In AWS ECS, logs are automatically sent to CloudWatch
- Local development: logs appear in Docker Compose output

### Metrics
- Request/response times
- Error rates
- Service availability

## 🔒 Security

### Best Practices
- Use HTTPS in production
- Implement authentication/authorization
- Use environment variables for secrets
- Regular security updates
- Network segmentation

### AWS Security
- IAM roles for service permissions
- Security groups for network access
- VPC isolation
- CloudTrail for audit logs

## 🚀 CI/CD

### GitHub Actions (Recommended)
Create `.github/workflows/deploy.yml` for automated deployment:

```yaml
name: Deploy to AWS ECS
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
      - name: Deploy to ECS
        run: ./aws/deploy.sh
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- Create an issue for bugs or feature requests
- Check the [AWS Deployment Guide](aws/README.md) for deployment help
- Review the troubleshooting section in the AWS guide

## 🔄 Version History

- **v1.0.0** - Initial release with basic microservices
- **v1.1.0** - Added AWS deployment configuration
- **v1.2.0** - Added Docker Compose for local development 