# Terraform Deployment Usage Guide

## 📋 Tổng quan

Terraform được tách thành **2 phần độc lập**:

1. **Infrastructure** - MongoDB, Kafka, Zookeeper (deploy một lần)
2. **Services** - App, Consumer, UI (deploy khi code thay đổi)

## 🚀 Workflow Deployment

### Bước 1: Deploy Infrastructure (Một lần)

Infrastructure chỉ cần deploy một lần khi setup environment mới.

```bash
# Dev Environment
cd terraform/kubernetes/environments/dev/infrastructure
terraform init
terraform plan
terraform apply

# Staging Environment
cd terraform/kubernetes/environments/stg/infrastructure
terraform init
terraform plan
terraform apply
```

**Lưu ý**: Infrastructure phải được deploy **trước** services.

### Bước 2: Deploy Services (Khi code thay đổi)

Services được deploy tự động khi merge code vào `dev` hoặc `stg` branch.

```bash
# Dev Environment - Manual
cd terraform/kubernetes/environments/dev/services
terraform init
terraform plan -var="image_tag=dev-latest"
terraform apply -var="image_tag=dev-latest"

# Staging Environment - Manual
cd terraform/kubernetes/environments/stg/services
terraform init
terraform plan -var="image_tag=stg-latest"
terraform apply -var="image_tag=stg-latest"
```

**CI/CD sẽ tự động**:
- Build Docker images với tag từ commit SHA
- Deploy services với image tag mới
- Update `image_tag` trong terraform.tfvars

## 🔄 CI/CD Integration

### GitHub Actions Workflow Example

```yaml
name: Deploy Services to Dev

on:
  push:
    branches: [dev]

jobs:
  deploy:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      
      - name: Build Docker Images
        run: |
          docker build -t localhost/my-tiny-app:${{ github.sha }} ./my-tiny-app
          docker build -t localhost/my-tiny-app-consumer:${{ github.sha }} ./my-tiny-app-consumer
          docker build -t localhost/my-tiny-app-ui:${{ github.sha }} ./my-tiny-app-ui
      
      - name: Deploy Services
        run: |
          cd terraform/kubernetes/environments/dev/services
          terraform init
          terraform apply -auto-approve \
            -var="image_tag=${{ github.sha }}"
```

## 📊 State Files

Mỗi environment có **2 state files riêng biệt**:

```
terraform/kubernetes/environments/dev/
├── infrastructure/
│   └── terraform.tfstate     # Infrastructure state
└── services/
    └── terraform.tfstate    # Services state
```

### Lợi ích:
- ✅ Update services không ảnh hưởng infrastructure
- ✅ Có thể rollback services độc lập
- ✅ Infrastructure state ổn định hơn

## 🔍 Services Reference Infrastructure

Services module sử dụng `terraform_remote_state` để lấy thông tin từ infrastructure:

```hcl
data "terraform_remote_state" "infrastructure" {
  backend = "local"
  config = {
    path = "../infrastructure/terraform.tfstate"
  }
}
```

Services sẽ tự động lấy:
- Namespace name
- ConfigMap name
- Service names (MongoDB, Kafka)

## 🗑️ Destroy

### Destroy Services (Không ảnh hưởng Infrastructure)

```bash
cd terraform/kubernetes/environments/dev/services
terraform destroy
```

### Destroy Infrastructure (Cần destroy Services trước)

```bash
# 1. Destroy Services trước
cd terraform/kubernetes/environments/dev/services
terraform destroy

# 2. Sau đó destroy Infrastructure
cd terraform/kubernetes/environments/dev/infrastructure
terraform destroy
```

## ⚠️ Lưu ý quan trọng

1. **Thứ tự deploy**: Infrastructure → Services
2. **State files**: Mỗi phần có state riêng, không share
3. **Dependencies**: Services phụ thuộc vào Infrastructure outputs
4. **Image tags**: Services sử dụng image tags từ CI/CD

## 🔧 Troubleshooting

### Services không tìm thấy Infrastructure

```bash
# Kiểm tra Infrastructure đã deploy chưa
cd terraform/kubernetes/environments/dev/infrastructure
terraform output

# Kiểm tra state file tồn tại
ls terraform.tfstate
```

### Update Infrastructure

Nếu cần update infrastructure (thay đổi ConfigMap, resources):

```bash
cd terraform/kubernetes/environments/dev/infrastructure
terraform plan
terraform apply
```

Services sẽ tự động sử dụng ConfigMap mới (không cần redeploy).

