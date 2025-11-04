# Terraform Multi-Environment Setup

Cấu trúc này tách biệt **Infrastructure** (deploy một lần) và **Services** (deploy khi code thay đổi).

## 📁 Cấu trúc

```
terraform/kubernetes/
├── modules/
│   ├── infrastructure/    # MongoDB, Kafka, Zookeeper
│   └── services/         # App, Consumer, UI
│
└── environments/
    ├── dev/
    │   ├── infrastructure/    # Deploy once
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   ├── versions.tf
    │   │   └── terraform.tfvars
    │   │
    │   └── services/          # Deploy on code changes
    │       ├── main.tf
    │       ├── variables.tf
    │       ├── versions.tf
    │       └── terraform.tfvars
    │
    └── stg/
        ├── infrastructure/
        └── services/
```

## 🚀 Workflow

### 1. Deploy Infrastructure (Một lần)

```bash
# Dev
cd terraform/kubernetes/environments/dev/infrastructure
terraform init
terraform apply

# Staging
cd terraform/kubernetes/environments/stg/infrastructure
terraform init
terraform apply
```

Infrastructure bao gồm:
- ✅ Namespace
- ✅ ConfigMap
- ✅ MongoDB (StatefulSet + Services)
- ✅ Zookeeper (Deployment + Service)
- ✅ Kafka (Deployment + Service)

### 2. Deploy Services (Khi code thay đổi)

```bash
# Dev - Deploy sau khi merge code vào dev branch
cd terraform/kubernetes/environments/dev/services
terraform init
terraform apply -var="image_tag=dev-$(git rev-parse --short HEAD)"

# Staging - Deploy sau khi merge code vào stg branch
cd terraform/kubernetes/environments/stg/services
terraform init
terraform apply -var="image_tag=stg-$(git rev-parse --short HEAD)"
```

Services bao gồm:
- ✅ App (Deployment + Service)
- ✅ Consumer (Deployment + Service)
- ✅ UI (Deployment + Service)

## 🔗 Services Reference Infrastructure

Services module sử dụng `terraform_remote_state` để lấy thông tin từ infrastructure:

- Namespace name
- ConfigMap name
- Service names (MongoDB, Kafka)

## 📊 State Management

Mỗi environment có **2 state files riêng biệt**:

- `dev/infrastructure/terraform.tfstate` - Infrastructure state
- `dev/services/terraform.tfstate` - Services state

Điều này cho phép:
- ✅ Deploy infrastructure một lần
- ✅ Deploy services nhiều lần khi code thay đổi
- ✅ Không ảnh hưởng infrastructure khi update services

## 🔄 CI/CD Integration

### GitHub Actions Workflow

```yaml
# Deploy Infrastructure (chạy một lần khi setup)
- name: Deploy Infrastructure
  run: |
    cd terraform/kubernetes/environments/${{ env.ENVIRONMENT }}/infrastructure
    terraform init
    terraform apply -auto-approve

# Build và Deploy Services (chạy khi merge code)
- name: Build and Push Docker Images
  run: |
    docker build -t my-registry/my-tiny-app:${{ github.sha }} ./my-tiny-app
    docker push my-registry/my-tiny-app:${{ github.sha }}

- name: Deploy Services
  run: |
    cd terraform/kubernetes/environments/${{ env.ENVIRONMENT }}/services
    terraform init
    terraform apply -auto-approve \
      -var="image_tag=${{ github.sha }}"
```

## 🎯 Lợi ích

1. **Tách biệt rõ ràng**: Infrastructure vs Services
2. **State isolation**: Mỗi phần có state riêng
3. **CI/CD friendly**: Deploy services khi code thay đổi
4. **Infrastructure stability**: Infrastructure không bị ảnh hưởng khi update services
5. **Flexibility**: Có thể update services mà không touch infrastructure

## 📝 Notes

- Infrastructure phải được deploy **trước** services
- Services sử dụng `terraform_remote_state` để reference infrastructure
- Image tags được update bởi CI/CD pipeline
- Có thể dùng remote backend (S3) thay vì local state
