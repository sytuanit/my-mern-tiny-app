# 🚀 Kustomize Multi-Environment Guide

## 📁 Cấu trúc

```
k8s/
├── base/                    # Base config (shared)
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── ingress.yaml
│   └── [services]/
│
└── overlays/
    ├── dev/                 # Development
    │   ├── kustomization.yaml
    │   ├── configmap-patch.yaml
    │   ├── namespace-patch.yaml
    │   └── resources-patch.yaml
    │
    └── stg/                 # Staging
        ├── kustomization.yaml
        ├── configmap-patch.yaml
        ├── namespace-patch.yaml
        └── resources-patch.yaml
```

---

## 🎯 Cách sử dụng

### 1. Preview (không apply)

```bash
# Xem config sẽ được apply cho dev
kubectl kustomize k8s/overlays/dev

# Xem config sẽ được apply cho staging
kubectl kustomize k8s/overlays/stg
```

### 2. Deploy

```bash
# Deploy to dev
kubectl apply -k k8s/overlays/dev

# Deploy to staging
kubectl apply -k k8s/overlays/stg
```

### 3. Xem resources đã deploy

```bash
# Dev
kubectl get all -n my-tiny-app-dev

# Staging
kubectl get all -n my-tiny-app-stg
```

### 4. Xóa

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
| **App Resources** | 64-128Mi, 50-100m | 256-512Mi, 200-400m |
| **UI Resources** | 128-256Mi, 50-100m | 512Mi-1Gi, 200-400m |
| **NODE_ENV** | `development` | `staging` |
| **Image Tags** | `dev-latest` | `stg-latest` |
| **Kafka Topic** | `item-events-dev` | `item-events-stg` |
| **MongoDB DB** | `my-tiny-app-dev` | `my-tiny-app-stg` |

---

## 📝 Ví dụ: Deploy Dev

```bash
# 1. Preview
kubectl kustomize k8s/overlays/dev | head -50

# 2. Apply
kubectl apply -k k8s/overlays/dev

# 3. Check status
kubectl get pods -n my-tiny-app-dev
kubectl get services -n my-tiny-app-dev

# 4. Check logs
kubectl logs -n my-tiny-app-dev deployment/dev-my-tiny-app
```

---

## 🔧 Customize cho từng env

### Thay đổi replicas

Sửa trong `kustomization.yaml`:
```yaml
replicas:
  - name: my-tiny-app
    count: 3  # Thay đổi số replicas
```

### Thay đổi resources

Sửa trong `resources-patch.yaml`:
```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

### Thay đổi config

Sửa trong `configmap-patch.yaml`:
```yaml
data:
  NODE_ENV: "production"
  MONGODB_URI: "mongodb://prod-mongodb:27017/my-tiny-app-prod"
```

---

## 🎨 Thêm environment mới (ví dụ: prod)

```bash
# 1. Tạo thư mục
mkdir -p k8s/overlays/prod

# 2. Copy từ stg
cp k8s/overlays/stg/* k8s/overlays/prod/

# 3. Sửa các file trong prod/
# - kustomization.yaml: Đổi namespace, namePrefix
# - namespace-patch.yaml: Đổi namespace name
# - configmap-patch.yaml: Đổi config values
# - resources-patch.yaml: Điều chỉnh resources
```

---

## 💡 Tips

1. **Luôn preview trước**: Dùng `kubectl kustomize` để xem config trước khi apply
2. **Test với dev**: Test changes trên dev trước khi deploy staging
3. **Version control**: Commit cả base và overlays vào Git
4. **Base changes**: Sửa base sẽ ảnh hưởng tất cả env, cẩn thận!
5. **Overlay changes**: Chỉ ảnh hưởng env đó

---

## 🐛 Troubleshooting

### Lỗi: "resource not found"
- Kiểm tra đường dẫn trong `kustomization.yaml`
- Đảm bảo file tồn tại trong `base/`

### Lỗi: "namespace not found"
- Kiểm tra namespace trong overlay patch
- Đảm bảo namespace được tạo trước

### Preview không đúng
- Chạy `kubectl kustomize` từ thư mục overlay
- Hoặc chỉ định đường dẫn đầy đủ

