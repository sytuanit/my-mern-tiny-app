# Thông tin AWS cần để Deploy lên EC2

## 🎯 TÓM TẮT NHANH

### **Cho LocalStack: KHÔNG CẦN gì cả! ✅**
- LocalStack dùng **dummy credentials** đã config sẵn
- Không cần AWS account
- Không cần Access Key

### **Cho AWS thật: CẦN các thông tin sau ⬇️**

---

## 📋 CHI TIẾT

### **1. LocalStack EC2 (Hiện tại - KHÔNG CẦN)**

✅ **Đã có sẵn trong `terraform/localstack/main.tf`:**
```terraform
provider "aws" {
  access_key = "test"              # ← Dummy
  secret_key = "test"              # ← Dummy
  region     = "us-east-1"         # ← Bất kỳ region nào
  # ... đã skip tất cả validation
}
```

**Kết luận:** Bạn **KHÔNG CẦN** làm gì cả, chỉ cần chạy `.\deploy-all.ps1`!

---

### **2. AWS Thật EC2 (CẦN các thông tin sau)**

#### **A. AWS Credentials (Bắt buộc)**

1. **AWS Access Key ID**
   - Format: `AKIAIOSFODNN7EXAMPLE`
   - Lấy từ: AWS Console → IAM → Users → Security credentials → Create access key

2. **AWS Secret Access Key**
   - Format: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`
   - ⚠️ **CHỈ HIỂN THỊ 1 LẦN** khi tạo, phải lưu lại ngay!

3. **AWS Region**
   - Ví dụ: `us-east-1`, `ap-southeast-1`, `eu-west-1`
   - Xem danh sách: https://docs.aws.amazon.com/general/latest/gr/rande.html

#### **B. AWS Account Information**

1. **AWS Account ID** (12 chữ số)
   - Format: `123456789012`
   - Tìm ở: AWS Console → Support → Account

2. **Default VPC ID** (nếu muốn dùng VPC có sẵn)
   - Format: `vpc-12345678`
   - Hoặc để Terraform tự tạo VPC mới

#### **C. EC2 Specific Information**

1. **AMI ID** (Amazon Machine Image)
   - Format: `ami-0c55b159cbfafe1f0`
   - Ví dụ cho Ubuntu: `ami-0c55b159cbfafe1f0` (us-east-1)
   - Tìm tại: EC2 Console → AMIs → Search

2. **Key Pair Name** (cho SSH access)
   - Format: `my-key-pair`
   - Tạo tại: EC2 Console → Key Pairs → Create key pair
   - ⚠️ Phải download `.pem` file và giữ an toàn!

3. **Security Group** (hoặc để Terraform tạo mới)
   - Cho phép ports: 3000, 3001 (app ports), 22 (SSH)
   - Source: 0.0.0.0/0 (public) hoặc IP cụ thể

4. **Instance Type**
   - Ví dụ: `t3.micro` (free tier), `t3.small`, `t3.medium`
   - Xem pricing: https://aws.amazon.com/ec2/pricing/

#### **D. Network Configuration**

1. **Subnet ID** (nếu muốn chỉ định)
   - Format: `subnet-12345678`
   - Hoặc để Terraform tự tạo

2. **VPC ID** (nếu muốn chỉ định)
   - Format: `vpc-12345678`
   - Hoặc để Terraform tự tạo

#### **E. Docker Registry (Nếu dùng ECR)**

1. **ECR Repository URL**
   - Format: `123456789012.dkr.ecr.us-east-1.amazonaws.com/my-tiny-app`
   - Hoặc dùng Docker Hub: `your-username/my-tiny-app`

2. **ECR Login Token** (nếu private)
   - Chạy: `aws ecr get-login-password --region us-east-1 | docker login ...`

#### **F. Managed Services (Nếu dùng)**

1. **RDS Endpoint** (nếu dùng Amazon RDS cho MongoDB)
   - Format: `mydb.123456789012.us-east-1.rds.amazonaws.com:27017`

2. **MSK Bootstrap Brokers** (nếu dùng Amazon MSK cho Kafka)
   - Format: `broker1.abc123.c2.kafka.us-east-1.amazonaws.com:9092`

---

## 🔧 Cách Setup cho AWS Thật

### **Bước 1: Tạo IAM User với Permissions**

```bash
# Permissions cần:
- EC2FullAccess (hoặc các permissions cụ thể)
- VPCFullAccess (nếu tạo VPC mới)
- IAMReadOnlyAccess (cho một số operations)
```

### **Bước 2: Tạo Access Keys**

1. AWS Console → IAM → Users → Create user
2. Attach policies: `AmazonEC2FullAccess`, `AmazonVPCFullAccess`
3. Security credentials → Create access key
4. Download hoặc copy **Access Key ID** và **Secret Access Key**

### **Bước 3: Configure AWS CLI (Optional nhưng recommended)**

```powershell
aws configure
# AWS Access Key ID: [paste your key]
# AWS Secret Access Key: [paste your secret]
# Default region: us-east-1
# Default output format: json
```

### **Bước 4: Cập nhật Terraform**

Tạo file mới: `terraform/aws/main.tf` (thay vì `terraform/localstack/main.tf`)

```terraform
provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Không dùng endpoints nữa (vì là AWS thật)
# Không skip validation
```

### **Bước 5: Cập nhật Variables**

```terraform
# terraform/aws/variables.tf
variable "aws_region" {
  default = "us-east-1"
}

variable "aws_access_key" {
  sensitive = true
}

variable "aws_secret_key" {
  sensitive = true
}

variable "ami_id" {
  default = "ami-0c55b159cbfafe1f0"  # Ubuntu 22.04 LTS us-east-1
}

variable "key_pair_name" {
  default = "my-key-pair"
}
```

### **Bước 6: Chạy Terraform**

```powershell
Set-Location terraform/aws
terraform init
terraform plan \
  -var="aws_access_key=YOUR_ACCESS_KEY" \
  -var="aws_secret_key=YOUR_SECRET_KEY" \
  -var="aws_region=us-east-1"

terraform apply
```

---

## 📊 So sánh LocalStack vs AWS Thật

| Item | LocalStack | AWS Thật |
|------|------------|----------|
| **Access Key** | `test` (dummy) | Real AWS Access Key |
| **Secret Key** | `test` (dummy) | Real AWS Secret Key |
| **Region** | Bất kỳ | Phải là region thật |
| **AMI ID** | `ami-12345678` (dummy) | Real AMI ID |
| **Account ID** | Không cần | Cần 12 chữ số |
| **Key Pair** | Không cần | Cần tạo |
| **VPC/Subnet** | Terraform tạo | Có thể dùng có sẵn |
| **Cost** | Free | Có phí (~$0.01/hour cho t3.micro) |

---

## ✅ Checklist cho AWS Thật

- [ ] AWS Account đã được tạo và verified
- [ ] IAM User đã được tạo với EC2 permissions
- [ ] Access Key ID và Secret Access Key đã được tạo và lưu
- [ ] Key Pair đã được tạo và download `.pem` file
- [ ] AMI ID đã được chọn (ví dụ: Ubuntu 22.04)
- [ ] Region đã được chọn (ví dụ: us-east-1)
- [ ] AWS CLI đã được configure (optional)
- [ ] Terraform đã được cập nhật với real credentials
- [ ] Hiểu về AWS costs (EC2 instances có phí)

---

## 🚨 Security Best Practices

### **Cho LocalStack:**
- ✅ Không cần lo lắng (dummy credentials)

### **Cho AWS Thật:**
- ⚠️ **KHÔNG** commit Access Keys vào Git
- ✅ Dùng environment variables hoặc AWS Secrets Manager
- ✅ Dùng IAM roles thay vì hardcode credentials
- ✅ Rotate keys định kỳ
- ✅ Dùng least privilege (chỉ cấp permissions cần thiết)
- ✅ Enable MFA cho IAM users

**Ví dụ an toàn:**

```powershell
# Dùng environment variables
$env:AWS_ACCESS_KEY_ID = "YOUR_KEY"
$env:AWS_SECRET_ACCESS_KEY = "YOUR_SECRET"
terraform apply  # Terraform tự động đọc env vars
```

Hoặc dùng AWS credential files:
```powershell
# ~/.aws/credentials
[default]
aws_access_key_id = YOUR_KEY
aws_secret_access_key = YOUR_SECRET
```

---

## 📝 TÓM TẮT CHO BẠN

### **Câu hỏi: Cần thông tin gì của AWS để deploy lên EC2 success?**

### **Trả lời:**

**Cho LocalStack (hiện tại):**
- ✅ **KHÔNG CẦN GÌ CẢ** - đã config sẵn!
- Chỉ cần chạy: `.\deploy-all.ps1`

**Cho AWS thật:**
1. ✅ AWS Access Key ID
2. ✅ AWS Secret Access Key
3. ✅ AWS Region
4. ✅ AMI ID (ví dụ: Ubuntu AMI)
5. ✅ Key Pair Name (cho SSH)
6. ⚠️ Hiểu về costs (EC2 instances có phí)

**Khuyến nghị:**
- Để test EC2: Dùng **LocalStack** (không cần gì)
- Để deploy production: Dùng **AWS thật** (cần credentials ở trên)

