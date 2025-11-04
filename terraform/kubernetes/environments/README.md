# Terraform Multi-Environment Setup

Cấu trúc này tương tự như Kustomize overlays, cho phép tách biệt environment (dev, stg) với shared base module.

## 📁 Cấu trúc

```
terraform/kubernetes/
├── modules/
│   └── app/              # Base module (shared code - tương tự k8s/base/)
│       ├── main.tf       # Shared resources
│       ├── variables.tf
│       └── outputs.tf
│
└── environments/         # Environment-specific configs (tương tự k8s/overlays/)
    ├── dev/
    │   ├── main.tf          # Calls base module
    │   ├── variables.tf     # Variable definitions
    │   └── terraform.tfvars # Dev-specific values
    │
    └── stg/
        ├── main.tf          # Calls base module
        ├── variables.tf     # Variable definitions
        └── terraform.tfvars # Stg-specific values
```

## 🚀 Cách sử dụng

### Deploy to Dev

```bash
cd terraform/kubernetes/environments/dev
terraform init
terraform plan
terraform apply
```

### Deploy to Staging

```bash
cd terraform/kubernetes/environments/stg
terraform init
terraform plan
terraform apply
```

### Destroy

```bash
# Dev
cd terraform/kubernetes/environments/dev
terraform destroy

# Staging
cd terraform/kubernetes/environments/stg
terraform destroy
```

## 🔍 Sự khác biệt giữa Dev và Stg

| Feature | Dev | Stg |
|---------|-----|-----|
| **Namespace** | `my-tiny-app-dev` | `my-tiny-app-stg` |
| **Name Prefix** | `dev-` | `stg-` |
| **Replicas** | 1 | 2 |
| **App Resources** | 64-128Mi, 50-100m | 256-512Mi, 200-400m |
| **UI Resources** | 128-256Mi, 50-100m | 512Mi-1Gi, 200-400m |
| **NODE_ENV** | `development` | `staging` |
| **Image Tags** | `dev-latest` | `stg-latest` |
| **Kafka Topic** | `item-events-dev` | `item-events-stg` |
| **MongoDB URI** | `mongodb://dev-mongodb:27017/my-tiny-app-dev` | `mongodb://stg-mongodb:27017/my-tiny-app-stg` |

## 📝 So sánh với Kustomize

| Kustomize | Terraform |
|-----------|-----------|
| `k8s/base/` | `terraform/kubernetes/modules/app/` |
| `k8s/overlays/dev/` | `terraform/kubernetes/environments/dev/` |
| `k8s/overlays/stg/` | `terraform/kubernetes/environments/stg/` |
| `kubectl apply -k` | `terraform apply` |
| `kubectl kustomize` | `terraform plan` |
| `patchesStrategicMerge` | `terraform.tfvars` với variables |

## 🎯 Ưu điểm

1. **State Management**: Mỗi environment có state riêng
2. **Variables**: Dễ quản lý config qua tfvars
3. **Modules**: Code reuse, DRY principle
4. **Terraform Features**: State locking, remote state, workspaces
5. **Type Safety**: Terraform validate variables

## 📋 Module Resources

Module `modules/app/` bao gồm:
- ✅ Namespace
- ✅ ConfigMap
- ✅ MongoDB (StatefulSet + Services)
- ✅ Zookeeper (Deployment + Service)
- ✅ Kafka (Deployment + Service)
- ✅ App (Deployment + Service)
- ✅ Consumer (Deployment + Service)
- ✅ UI (Deployment + Service)

Tất cả resources đều:
- Dùng `name_prefix` để tách biệt environment
- Dùng variables cho replicas và resources
- Có labels để filter theo environment
