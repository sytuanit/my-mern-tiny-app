# Quick Start - Provision Infrastructure trên LocalStack EC2

## 📋 Prerequisites

1. **Docker & Docker Compose** - Đã cài đặt và đang chạy
2. **Terraform** - Version >= 1.0
3. **LocalStack** - Đang chạy (port 4567)

## 🚀 Quick Start

### Bước 1: Start LocalStack

**Windows (PowerShell):**
```powershell
# Option 1: Sử dụng Makefile.ps1
.\Makefile.ps1 localstack-up

# Option 2: Sử dụng Docker Compose
docker-compose -f docker-compose.localstack.yml up -d localstack

# Đợi LocalStack sẵn sàng (10-15 giây)
Start-Sleep -Seconds 15

# Kiểm tra health
curl http://localhost:4567/_localstack/health
```

**Linux/Mac:**
```bash
# Option 1: Sử dụng Makefile
make localstack-up

# Option 2: Sử dụng Docker Compose
docker-compose -f docker-compose.localstack.yml up -d localstack

# Đợi LocalStack sẵn sàng
sleep 15

# Kiểm tra health
curl http://localhost:4567/_localstack/health
```

### Bước 2: Provision Infrastructure

**Windows (PowerShell) - Khuyến nghị:**
```powershell
# Sử dụng script tự động
.\scripts\provision-localstack-infra.ps1 -Environment dev

# Hoặc với staging
.\scripts\provision-localstack-infra.ps1 -Environment stg
```

**Manual - Windows (PowerShell):**
```powershell
# 1. Navigate to infrastructure directory
cd terraform/localstack/environments/dev/infrastructure

# 2. Initialize Terraform
terraform init

# 3. Validate configuration
terraform validate

# 4. Plan changes
terraform plan

# 5. Apply changes
terraform apply
```

**Linux/Mac:**
```bash
# 1. Navigate to infrastructure directory
cd terraform/localstack/environments/dev/infrastructure

# 2. Initialize Terraform
terraform init

# 3. Validate configuration
terraform validate

# 4. Plan changes
terraform plan

# 5. Apply changes
terraform apply
```

## ✅ Verify Infrastructure

Sau khi provision xong, kiểm tra:

```powershell
# Windows
aws --endpoint-url=http://localhost:4567 ec2 describe-vpcs
aws --endpoint-url=http://localhost:4567 ec2 describe-security-groups
aws --endpoint-url=http://localhost:4567 iam list-roles

# Linux/Mac
aws --endpoint-url=http://localhost:4567 ec2 describe-vpcs
aws --endpoint-url=http://localhost:4567 ec2 describe-security-groups
aws --endpoint-url=http://localhost:4567 iam list-roles
```

Hoặc xem Terraform outputs:

```powershell
cd terraform/localstack/environments/dev/infrastructure
terraform output
```

## 📊 Infrastructure Resources

Infrastructure module sẽ tạo:

- ✅ **VPC** - Virtual Private Cloud
- ✅ **Subnet** - Public subnet cho EC2 instances
- ✅ **Internet Gateway** - Để EC2 có thể truy cập internet
- ✅ **Route Table** - Routing cho subnet
- ✅ **Security Group** - Firewall rules cho EC2
- ✅ **IAM Role** - Role cho EC2 instances
- ✅ **IAM Instance Profile** - Profile để attach vào EC2

## 🔄 Next Steps

Sau khi provision infrastructure xong:

1. **Deploy Services** (EC2 instance với Docker containers):
   ```powershell
   cd terraform/localstack/environments/dev/services
   terraform init
   terraform apply
   ```

2. Hoặc sử dụng script:
   ```powershell
   .\scripts\deploy-localstack-services.ps1 -Environment dev
   ```

## 🗑️ Destroy Infrastructure

Khi không cần nữa, có thể destroy:

```powershell
cd terraform/localstack/environments/dev/infrastructure
terraform destroy
```

**Lưu ý**: Phải destroy services trước khi destroy infrastructure!

## 📝 Troubleshooting

### LocalStack không response

```powershell
# Kiểm tra LocalStack đang chạy
docker ps | Select-String localstack

# Xem logs
docker logs localstack

# Restart LocalStack
docker-compose -f docker-compose.localstack.yml restart localstack
```

### Terraform không tìm thấy provider

```powershell
# Re-initialize
cd terraform/localstack/environments/dev/infrastructure
terraform init -upgrade
```

### Port conflict

Nếu port 4567 đã được sử dụng, có thể đổi LocalStack port trong `docker-compose.localstack.yml`:

```yaml
ports:
  - "4568:4566"  # Thay đổi port mapping
```

Và cập nhật `localstack_endpoint` trong `terraform.tfvars`:

```hcl
localstack_endpoint = "http://localhost:4568"
```

## 📚 More Information

- Xem [README.md](./README.md) để hiểu chi tiết về cấu trúc
- Xem [USAGE.md](../USAGE.md) để biết cách sử dụng services

