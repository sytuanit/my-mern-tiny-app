# Kustomize Overlays - Multi-Environment Setup

## 📁 Cấu trúc

```
k8s/
├── base/                          # Base configurations (chung cho tất cả env)
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── ingress.yaml
│   ├── app/
│   ├── consumer/
│   ├── ui/
│   ├── mongodb/
│   ├── zookeeper/
│   └── kafka/
│
└── overlays/
    ├── dev/                       # Development environment
    │   ├── kustomization.yaml
    │   ├── configmap-patch.yaml
    │   ├── namespace-patch.yaml
    │   └── resources-patch.yaml
    │
    └── stg/                       # Staging environment
        ├── kustomization.yaml
        ├── configmap-patch.yaml
        ├── namespace-patch.yaml
        └── resources-patch.yaml
```

---

## 🚀 Cách sử dụng

### Xem preview (không apply)

```bash
# Dev environment
kubectl kustomize k8s/overlays/dev

# Staging environment
kubectl kustomize k8s/overlays/stg
```

### Deploy

```bash
# Deploy to dev
kubectl apply -k k8s/overlays/dev

# Deploy to staging
kubectl apply -k k8s/overlays/stg
```

### Xóa

```bash
# Delete dev
kubectl delete -k k8s/overlays/dev

# Delete staging
kubectl delete -k k8s/overlays/stg
```

---

## 🔍 Sự khác biệt giữa Dev và Staging

| Feature | Dev | Staging |
|---------|-----|---------|
| **Namespace** | `my-tiny-app-dev` | `my-tiny-app-stg` |
| **Name Prefix** | `dev-` | `stg-` |
| **Replicas** | 1 | 2 |
| **Resources (App)** | 64-128Mi, 50-100m | 256-512Mi, 200-400m |
| **Resources (UI)** | 128-256Mi, 50-100m | 512Mi-1Gi, 200-400m |
| **NODE_ENV** | `development` | `staging` |
| **Image Tags** | `dev-latest` | `stg-latest` |
| **Kafka Topic** | `item-events-dev` | `item-events-stg` |
| **MongoDB URI** | `mongodb://dev-mongodb:27017/my-tiny-app-dev` | `mongodb://stg-mongodb:27017/my-tiny-app-stg` |

---

## 📝 Thêm environment mới

Để thêm environment mới (ví dụ: `prod`):

1. Tạo thư mục: `k8s/overlays/prod/`
2. Copy từ `stg/` và chỉnh sửa:
   ```bash
   cp -r k8s/overlays/stg k8s/overlays/prod
   ```
3. Chỉnh sửa các file trong `prod/`:
   - `kustomization.yaml`: Đổi namespace, namePrefix, labels
   - `configmap-patch.yaml`: Đổi config values
   - `namespace-patch.yaml`: Đổi namespace name
   - `resources-patch.yaml`: Điều chỉnh resources và replicas

---

## 🎯 Best Practices

1. **Base**: Giữ tất cả config chung, không có env-specific values
2. **Overlays**: Chỉ patch những gì khác biệt giữa các env
3. **Namespace**: Tách riêng namespace cho từng env
4. **Labels**: Thêm labels để dễ filter và query
5. **Name Prefix**: Dùng prefix để tránh conflict giữa các env

---

## 🔄 Workflow

1. **Development**: Làm việc với `base/` và `overlays/dev/`
2. **Testing**: Test với `kubectl kustomize` trước khi apply
3. **Staging**: Deploy `overlays/stg/` để test production-like
4. **Production**: Tạo `overlays/prod/` với config tương tự staging

