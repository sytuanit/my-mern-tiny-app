# Terraform Structure - Best Practices

Cấu trúc này tuân theo [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html) cho multi-environment deployments.

## 📁 Cấu trúc chuẩn

```
terraform/kubernetes/
├── modules/
│   └── app/                    # Reusable module
│       ├── main.tf            # Resources
│       ├── variables.tf       # Input variables
│       └── outputs.tf        # Output values
│
└── environments/               # Environment-specific configs
    ├── dev/
    │   ├── main.tf            # Calls module
    │   ├── variables.tf       # Variable definitions
    │   ├── versions.tf       # Terraform & provider versions
    │   ├── terraform.tfvars  # Environment values (gitignored)
    │   └── terraform.tfvars.example  # Template (committed)
    │
    └── stg/
        └── (same structure)
```

## ✅ Best Practices được áp dụng

### 1. **Module Structure**
- ✅ Modules trong `modules/` directory
- ✅ Mỗi module có `main.tf`, `variables.tf`, `outputs.tf`
- ✅ Module là reusable và environment-agnostic

### 2. **Environment Separation**
- ✅ Mỗi environment có thư mục riêng
- ✅ State files tách biệt (không share state)
- ✅ Variables riêng cho mỗi environment

### 3. **File Organization**
- ✅ `versions.tf`: Terraform và provider versions
- ✅ `main.tf`: Module calls và resources
- ✅ `variables.tf`: Variable definitions
- ✅ `terraform.tfvars`: Environment-specific values (gitignored)
- ✅ `terraform.tfvars.example`: Template (committed)

### 4. **Security**
- ✅ `.gitignore` cho state files và sensitive data
- ✅ `terraform.tfvars` không commit (chứa secrets)
- ✅ `terraform.tfvars.example` là template an toàn

### 5. **State Management**
- ✅ Mỗi environment có state riêng
- ✅ Có thể config remote backend trong `versions.tf`
- ✅ State locking support (với remote backend)

## 🔄 So sánh với các cấu trúc khác

### Option 1: Workspaces (Không khuyến nghị cho multi-env)
```
terraform/
├── main.tf
└── terraform.tfvars
# Dùng terraform workspace select dev|stg
```
❌ Không tách biệt rõ ràng, dễ nhầm lẫn

### Option 2: Separate directories (Khuyến nghị - ĐANG DÙNG)
```
terraform/
└── environments/
    ├── dev/
    └── stg/
```
✅ Tách biệt rõ ràng, dễ quản lý

### Option 3: Service-based
```
terraform/
├── kubernetes/
│   └── environments/
└── aws/
    └── environments/
```
✅ Tốt cho multi-cloud, phức tạp hơn

## 📋 Checklist

- [x] Modules trong `modules/` directory
- [x] Environments trong `environments/` directory
- [x] `versions.tf` cho mỗi environment
- [x] `.gitignore` cho state files
- [x] `terraform.tfvars.example` template
- [x] Separate state files per environment
- [ ] Remote backend config (optional)
- [ ] CI/CD integration (optional)

## 🚀 Next Steps

1. **Remote State Backend** (Production):
   - Uncomment backend config trong `versions.tf`
   - Setup S3 bucket hoặc Terraform Cloud

2. **CI/CD Integration**:
   - Auto-apply cho dev
   - Manual approval cho staging/prod

3. **Secrets Management**:
   - Dùng AWS Secrets Manager hoặc HashiCorp Vault
   - Reference trong `terraform.tfvars`

