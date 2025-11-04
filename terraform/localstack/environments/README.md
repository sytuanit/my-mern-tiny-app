# Terraform LocalStack EC2 Deployment

Cấu trúc này tách biệt **Infrastructure** (deploy một lần) và **Services** (deploy khi code thay đổi) trên LocalStack EC2.

## 📁 Cấu trúc

```
terraform/localstack/
├── modules/
│   ├── infrastructure/    # VPC, Security Groups, IAM
│   └── services/           # EC2 Instance với Docker containers
│
└── environments/
    ├── dev/
    │   ├── infrastructure/    # Deploy once
    │   └── services/          # Deploy on code changes
    │
    └── stg/
        ├── infrastructure/
        └── services/
```

## 🏗️ Architecture

**Single EC2 Instance** chạy tất cả services:

```
EC2 Instance
├── Infrastructure Services (Docker Compose)
│   ├── MongoDB (port 27017)
│   ├── Zookeeper (port 2181)
│   └── Kafka (ports 9092, 9093)
│
└── Application Services (Docker Compose)
    ├── App (port 3000)
    ├── Consumer (port 3001)
    └── UI (port 3002)
```

## 🚀 Workflow

### 1. Deploy Infrastructure (Một lần)

```bash
# Dev
cd terraform/localstack/environments/dev/infrastructure
terraform init
terraform apply

# Staging
cd terraform/localstack/environments/stg/infrastructure
terraform init
terraform apply
```

Infrastructure bao gồm:
- ✅ VPC
- ✅ Subnet
- ✅ Internet Gateway
- ✅ Route Table
- ✅ Security Group
- ✅ IAM Role & Instance Profile

### 2. Deploy Services (Khi code thay đổi)

```bash
# Dev - Deploy sau khi merge code vào dev branch
cd terraform/localstack/environments/dev/services
terraform init
terraform apply -var="app_image_tag=dev-$(git rev-parse --short HEAD)"

# Staging - Deploy sau khi merge code vào stg branch
cd terraform/localstack/environments/stg/services
terraform init
terraform apply -var="app_image_tag=stg-$(git rev-parse --short HEAD)"
```

Services bao gồm:
- ✅ EC2 Instance
- ✅ Docker containers (MongoDB, Kafka, Zookeeper, App, Consumer, UI)

## 🔗 Services Reference Infrastructure

Services module sử dụng `terraform_remote_state` để lấy thông tin từ infrastructure:

- Subnet ID
- Security Group ID
- IAM Instance Profile name

## 📊 State Management

Mỗi environment có **2 state files riêng biệt**:

- `dev/infrastructure/terraform.tfstate` - Infrastructure state
- `dev/services/terraform.tfstate` - Services state

## 🔄 CI/CD Integration

### GitHub Actions Workflow

```yaml
# Deploy Infrastructure (chạy một lần khi setup)
- name: Deploy Infrastructure
  run: |
    cd terraform/localstack/environments/${{ env.ENVIRONMENT }}/infrastructure
    terraform init
    terraform apply -auto-approve

# Build và Deploy Services (chạy khi merge code)
- name: Build Docker Images
  run: |
    docker build -t localhost/my-tiny-app:${{ github.sha }} ./my-tiny-app
    docker build -t localhost/my-tiny-app-consumer:${{ github.sha }} ./my-tiny-app-consumer
    docker build -t localhost/my-tiny-app-ui:${{ github.sha }} ./my-tiny-app-ui

- name: Deploy Services
  run: |
    cd terraform/localstack/environments/${{ env.ENVIRONMENT }}/services
    terraform init
    terraform apply -auto-approve \
      -var="app_image_tag=${{ github.sha }}" \
      -var="consumer_image_tag=${{ github.sha }}" \
      -var="ui_image_tag=${{ github.sha }}"
```

## 🎯 Lợi ích

1. **Single Instance**: Tất cả services trên cùng 1 EC2 instance
2. **Tách biệt rõ ràng**: Infrastructure vs Services
3. **State isolation**: Mỗi phần có state riêng
4. **CI/CD friendly**: Deploy services khi code thay đổi
5. **Cost effective**: Chỉ 1 EC2 instance cho tất cả services

## 📝 Notes

- Infrastructure phải được deploy **trước** services
- Services sử dụng `terraform_remote_state` để reference infrastructure
- Image tags được update bởi CI/CD pipeline
- Tất cả services chạy trên cùng 1 EC2 instance qua Docker Compose

