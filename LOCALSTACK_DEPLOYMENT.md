# LocalStack EC2 Deployment Guide

Hướng dẫn deploy `my-tiny-app` và `my-tiny-app-consumer` lên LocalStack EC2.

## 📋 Prerequisites

1. **Docker & Docker Compose** - Đã cài đặt và đang chạy
2. **Terraform** - Version >= 1.0
3. **AWS CLI** - Để kiểm tra và quản lý LocalStack resources
4. **Make** (optional) - Để sử dụng Makefile commands

## 🚀 Quick Start

### 1. Start LocalStack và Infrastructure

**Linux/Mac:**
```bash
make localstack-up
```

**Windows (PowerShell):**
```powershell
.\Makefile.ps1 localstack-up
```

Hoặc thủ công:

```bash
docker-compose -f docker-compose.localstack.yml up -d localstack mongodb kafka zookeeper
```

### 2. Deploy Applications

**Linux/Mac:**
```bash
make deploy
```

**Windows (PowerShell):**
```powershell
.\Makefile.ps1 deploy
```

Hoặc thủ công:

**Linux/Mac:**
```bash
bash scripts/deploy-to-localstack.sh
```

**Windows (PowerShell):**
```powershell
.\scripts\deploy-to-localstack.ps1
```

## 📁 Project Structure

```
.
├── docker-compose.localstack.yml  # LocalStack và infrastructure services
├── terraform/
│   └── localstack/
│       ├── main.tf               # Terraform configuration
│       ├── variables.tf          # Variables
│       └── outputs.tf            # Outputs
├── scripts/
│   ├── deploy-to-localstack.sh   # Deployment script (Linux/Mac)
│   ├── deploy-to-localstack.ps1  # Deployment script (Windows)
│   └── destroy-localstack.sh    # Cleanup script
└── Makefile                      # Make commands
```

## 🔧 Configuration

### Environment Variables

Các biến môi trường có thể được cấu hình trong `terraform/localstack/variables.tf`:

- `docker_registry`: Docker registry URL (mặc định: "localhost")
- `mongodb_uri`: MongoDB connection URI
- `kafka_broker`: Kafka broker address
- `app_api_url`: API URL cho consumer

### LocalStack Endpoint

LocalStack chạy trên port `4566`. Tất cả AWS API calls sẽ được route tới:
```
http://localhost:4566
```

## 📊 Architecture

```
┌─────────────────────────────────────────────────┐
│           LocalStack (AWS Services)             │
│  ┌──────────────────────────────────────────┐   │
│  │  EC2 Instance (my-tiny-app)             │   │
│  │  - Runs Docker container                │   │
│  │  - Port: 3000                           │   │
│  └──────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────┐   │
│  │  EC2 Instance (my-tiny-app-consumer)     │   │
│  │  - Runs Docker container                │   │
│  │  - Port: 3001                           │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
         │                    │
         └────────────────────┘
         │
┌─────────────────────────────────────────────────┐
│        Infrastructure Services                  │
│  - MongoDB (Port: 27017)                        │
│  - Kafka (Port: 9092/9093)                      │
│  - Zookeeper (Port: 2181)                       │
└─────────────────────────────────────────────────┘
```

## 🛠️ Available Commands

### Make Commands (Linux/Mac)

```bash
make help              # Hiển thị tất cả commands
make localstack-up     # Start LocalStack và services
make localstack-down   # Stop LocalStack và services
make build             # Build Docker images
make deploy            # Deploy to LocalStack EC2
make destroy           # Destroy infrastructure
make clean             # Clean up tất cả
make test-localstack   # Test LocalStack connectivity
make list-instances    # List EC2 instances
```

### PowerShell Commands (Windows)

```powershell
.\Makefile.ps1 help              # Hiển thị tất cả commands
.\Makefile.ps1 localstack-up     # Start LocalStack và services
.\Makefile.ps1 localstack-down   # Stop LocalStack và services
.\Makefile.ps1 build             # Build Docker images
.\Makefile.ps1 deploy             # Deploy to LocalStack EC2
.\Makefile.ps1 destroy            # Destroy infrastructure
.\Makefile.ps1 clean              # Clean up tất cả
.\Makefile.ps1 test-localstack    # Test LocalStack connectivity
.\Makefile.ps1 list-instances     # List EC2 instances
```

### Manual Commands

#### Deploy
```bash
bash scripts/deploy-to-localstack.sh
```

#### Destroy
```bash
bash scripts/destroy-localstack.sh
```

#### Check LocalStack Health
```bash
curl http://localhost:4566/_localstack/health | jq .
```

#### List EC2 Instances
```bash
aws --endpoint-url=http://localhost:4566 ec2 describe-instances
```

#### Describe Specific Instance
```bash
aws --endpoint-url=http://localhost:4566 ec2 describe-instances \
  --instance-ids <instance-id>
```

## 🔍 Verification

### 1. Check LocalStack Status
```bash
curl http://localhost:4566/_localstack/health
```

### 2. List EC2 Instances
```bash
make list-instances
```

### 3. Test Applications
```bash
# Test API
curl http://localhost:3000/api/items

# Test Consumer Health
curl http://localhost:3001/health
```

## 📝 Terraform Management

### Initialize
```bash
cd terraform/localstack
terraform init
```

### Plan
```bash
terraform plan \
  -var="docker_registry=localhost" \
  -var="mongodb_uri=mongodb://mongodb:27017/my-tiny-app" \
  -var="kafka_broker=kafka:9093" \
  -var="app_api_url=http://app:3000"
```

### Apply
```bash
terraform apply -auto-approve \
  -var="docker_registry=localhost" \
  -var="mongodb_uri=mongodb://mongodb:27017/my-tiny-app" \
  -var="kafka_broker=kafka:9093" \
  -var="app_api_url=http://app:3000"
```

### Destroy
```bash
terraform destroy -auto-approve \
  -var="docker_registry=localhost" \
  -var="mongodb_uri=mongodb://mongodb:27017/my-tiny-app" \
  -var="kafka_broker=kafka:9093" \
  -var="app_api_url=http://app:3000"
```

## ⚠️ Important Notes

1. **LocalStack Limitations**: 
   - LocalStack Community không hỗ trợ đầy đủ EC2. Cần LocalStack Pro để có EC2 support tốt hơn.
   - Hoặc có thể sử dụng docker-compose để chạy containers trực tiếp (như hiện tại).

2. **AMI IDs**: 
   - LocalStack sử dụng dummy AMI IDs. Có thể sử dụng bất kỳ AMI ID nào (ví dụ: `ami-12345678`).

3. **Network Configuration**:
   - EC2 instances trong LocalStack có thể không có public IP thực sự.
   - Sử dụng docker-compose network để kết nối giữa các services.

4. **Alternative Approach**:
   - Nếu LocalStack EC2 không hoạt động tốt, có thể sử dụng docker-compose để chạy containers như "EC2 instances" và chỉ dùng LocalStack cho các AWS services khác (S3, SQS, etc.).

## 🔄 Alternative: Docker Compose Only

Nếu LocalStack EC2 không đáp ứng nhu cầu, có thể chạy trực tiếp bằng docker-compose:

```bash
docker-compose -f docker-compose.localstack.yml up -d
```

Điều này sẽ chạy apps như containers thông thường, nhưng vẫn có LocalStack cho các AWS services khác.

## 🐛 Troubleshooting

### LocalStack không start
```bash
# Check logs
docker-compose -f docker-compose.localstack.yml logs localstack

# Restart
docker-compose -f docker-compose.localstack.yml restart localstack
```

### Terraform errors
```bash
# Check Terraform state
cd terraform/localstack
terraform show

# Remove and reinitialize if needed
rm -rf .terraform terraform.tfstate
terraform init
```

### Applications không connect được
```bash
# Check network
docker network ls
docker network inspect my-mern-tiny-app-localstack_app-network

# Check container logs
docker logs my-tiny-app
docker logs my-tiny-app-consumer
```

## 📚 Resources

- [LocalStack Documentation](https://docs.localstack.cloud/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

