# AWS Requirements cho LocalStack Deployment

## 🎯 LocalStack vs AWS Thật

**LocalStack không cần AWS credentials thật!** LocalStack là AWS emulator chạy locally, chỉ cần dummy credentials.

## ✅ Thông tin cần thiết cho LocalStack

### 1. AWS Credentials (Dummy - đã cấu hình sẵn)

Terraform đã được cấu hình với dummy credentials:
```hcl
provider "aws" {
  access_key = "test"           # Dummy access key
  secret_key = "test"           # Dummy secret key
  region     = "us-east-1"      # Region (có thể là bất kỳ giá trị nào)
  
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}
```

**✅ Không cần:** AWS Access Key ID, Secret Access Key thật  
**✅ Đã có sẵn:** Dummy credentials trong Terraform config

### 2. LocalStack Endpoint

LocalStack chạy trên:
- **Port:** `4567` (đã được cấu hình trong `docker-compose.localstack.yml`)
- **Endpoint:** `http://localhost:4567`

**✅ Đã cấu hình sẵn trong:**
- `terraform/localstack/main.tf` - Terraform endpoints
- `docker-compose.localstack.yml` - LocalStack service port

### 3. AWS CLI Configuration (Optional - chỉ để kiểm tra)

Nếu muốn dùng AWS CLI để kiểm tra LocalStack resources:

**Option A: Dùng --endpoint-url (khuyến nghị)**
```powershell
aws --endpoint-url=http://localhost:4567 ec2 describe-instances
```

**Option B: Configure AWS CLI profile (optional)**
```powershell
aws configure set aws_access_key_id test --profile localstack
aws configure set aws_secret_access_key test --profile localstack
aws configure set region us-east-1 --profile localstack

# Sau đó dùng:
aws --endpoint-url=http://localhost:4567 --profile localstack ec2 describe-instances
```

**⚠️ Lưu ý:** Không cần config AWS CLI nếu không muốn kiểm tra resources. Script sẽ tự động deploy qua Terraform.

### 4. Terraform Variables (Đã có defaults)

Các biến có thể tùy chỉnh trong `terraform/localstack/variables.tf`:

| Variable | Default Value | Mô tả |
|----------|--------------|-------|
| `docker_registry` | `localhost` | Docker registry URL |
| `mongodb_uri` | `mongodb://mongodb:27017/my-tiny-app` | MongoDB connection string |
| `kafka_broker` | `kafka:9093` | Kafka broker address |
| `app_api_url` | `http://app:3000` | API URL cho consumer |

**✅ Đã có defaults** - Không cần thay đổi nếu dùng docker-compose network.

## 📋 Checklist trước khi deploy

### Bắt buộc:
- [x] **Docker Desktop** đang chạy
- [x] **LocalStack** đang chạy (port 4567)
- [x] **Terraform** đã cài đặt (đã tìm thấy trong WinGet packages)
- [x] **MongoDB, Kafka, Zookeeper** đang chạy

### Không bắt buộc nhưng hữu ích:
- [ ] **AWS CLI** đã cài (để kiểm tra resources) - Optional
- [ ] **Make** đã cài (cho Makefile commands) - Optional

## 🚀 Deploy mà không cần AWS credentials

**Tất cả đã được cấu hình sẵn!** Chỉ cần chạy:

```powershell
.\deploy-all.ps1
```

Script sẽ:
1. ✅ Tự động tìm Terraform
2. ✅ Dùng dummy AWS credentials đã cấu hình
3. ✅ Kết nối tới LocalStack tại `http://localhost:4567`
4. ✅ Deploy EC2 instances trên LocalStack

## 🔍 Nếu muốn deploy lên AWS thật

Nếu muốn deploy lên AWS thật (không phải LocalStack), bạn cần:

### 1. AWS Account & Credentials
- AWS Access Key ID
- AWS Secret Access Key
- AWS Region (ví dụ: `us-east-1`)

### 2. Cấu hình Terraform cho AWS thật

Cập nhật `terraform/localstack/main.tf`:

```hcl
provider "aws" {
  access_key = var.aws_access_key_id      # Từ environment hoặc variable
  secret_key = var.aws_secret_access_key  # Từ environment hoặc variable
  region     = var.aws_region              # Ví dụ: "us-east-1"
  
  # Bỏ các skip flags khi dùng AWS thật
  # skip_credentials_validation = false
  # skip_metadata_api_check     = false
  # skip_requesting_account_id  = false
  
  # Bỏ endpoints block khi dùng AWS thật
  # endpoints { ... }
}
```

### 3. Set environment variables hoặc terraform.tfvars

```powershell
# Option 1: Environment variables
$env:AWS_ACCESS_KEY_ID = "your-access-key"
$env:AWS_SECRET_ACCESS_KEY = "your-secret-key"
$env:AWS_REGION = "us-east-1"

# Option 2: terraform.tfvars
# aws_access_key_id = "your-access-key"
# aws_secret_access_key = "your-secret-key"
# aws_region = "us-east-1"
```

### 4. Real AMI ID

Cần AMI ID thật từ AWS (không phải dummy `ami-12345678`).

## 📝 Tóm tắt

### Cho LocalStack (hiện tại):
- ✅ **Không cần** AWS credentials thật
- ✅ **Không cần** AWS account
- ✅ **Chỉ cần** LocalStack chạy trên port 4567
- ✅ Tất cả đã được cấu hình sẵn trong Terraform

### Cho AWS thật (nếu cần):
- ❌ **Cần** AWS Account
- ❌ **Cần** AWS Access Key ID & Secret Access Key
- ❌ **Cần** Cập nhật Terraform config
- ❌ **Cần** Real AMI IDs

## 🎯 Kết luận

**Để deploy lên LocalStack EC2 thành công, bạn KHÔNG CẦN thông tin AWS thật nào cả!**

Tất cả đã được cấu hình sẵn với dummy credentials. Chỉ cần:
1. LocalStack đang chạy ✅
2. Terraform đã cài ✅  
3. Docker images đã build ✅
4. Chạy `.\deploy-all.ps1` ✅

