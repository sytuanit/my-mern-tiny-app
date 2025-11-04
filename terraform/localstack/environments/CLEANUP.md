# Cleanup EC2 Instances trên LocalStack

Hướng dẫn cleanup các EC2 instances đã tạo trước đây trên LocalStack.

## 🗑️ Các Cách Cleanup

### Cách 1: Sử dụng Script Tự động (Khuyến nghị)

**Windows (PowerShell):**
```powershell
# Interactive mode - sẽ hỏi bạn muốn cleanup như thế nào
.\scripts\cleanup-localstack-ec2.ps1 -Environment dev

# Terminate tất cả instances
.\scripts\cleanup-localstack-ec2.ps1 -DestroyAll -Environment dev

# Terminate instance cụ thể
.\scripts\cleanup-localstack-ec2.ps1 -InstanceId i-fa8ad53b5222216b3
```

Script sẽ:
1. ✅ Kiểm tra LocalStack health
2. ✅ Liệt kê tất cả EC2 instances
3. ✅ Cho phép chọn method cleanup (Terraform destroy hoặc AWS CLI terminate)
4. ✅ Verify cleanup thành công

### Cách 2: Destroy via Terraform (Nếu tạo bằng Terraform)

Nếu instances được tạo bằng Terraform, nên destroy qua Terraform để đảm bảo cleanup đúng cách:

```powershell
# 1. Destroy services (EC2 instances)
cd terraform/localstack/environments/dev/services
terraform destroy

# 2. Destroy infrastructure (VPC, Security Groups, IAM) - chỉ khi không còn instances
cd ../infrastructure
terraform destroy
```

**Lưu ý**: Phải destroy services trước khi destroy infrastructure!

### Cách 3: Terminate qua AWS CLI (Manual)

```powershell
# Liệt kê tất cả instances
aws --endpoint-url=http://localhost:4567 ec2 describe-instances --output json

# Terminate instance cụ thể
aws --endpoint-url=http://localhost:4567 ec2 terminate-instances --instance-ids i-fa8ad53b5222216b3

# Terminate nhiều instances
aws --endpoint-url=http://localhost:4567 ec2 terminate-instances --instance-ids i-fa8ad53b5222216b3 i-c91df76007707494f
```

### Cách 4: Terminate tất cả Running/Stopped Instances

```powershell
# Lấy tất cả instance IDs (trừ terminated)
$instances = aws --endpoint-url=http://localhost:4567 ec2 describe-instances --query "Reservations[*].Instances[?State.Name!='terminated'].InstanceId" --output text

# Terminate tất cả
foreach ($id in $instances) {
    if ($id) {
        aws --endpoint-url=http://localhost:4567 ec2 terminate-instances --instance-ids $id
        Write-Host "Terminated: $id" -ForegroundColor Green
    }
}
```

## ✅ Verify Cleanup

Sau khi cleanup, kiểm tra:

```powershell
# List instances còn lại
aws --endpoint-url=http://localhost:4567 ec2 describe-instances --output json

# Hoặc sử dụng script
.\scripts\cleanup-localstack-ec2.ps1 -Environment dev
```

## 📊 Instance States

Các trạng thái của EC2 instances:

- **running** - Đang chạy → Cần terminate
- **stopped** - Đã dừng → Cần terminate
- **terminated** - Đã terminate → Không cần làm gì
- **pending** - Đang khởi động → Có thể terminate

## 🔄 Cleanup Infrastructure (Sau khi cleanup instances)

Sau khi đã cleanup tất cả instances, có thể cleanup infrastructure:

```powershell
cd terraform/localstack/environments/dev/infrastructure
terraform destroy
```

Infrastructure bao gồm:
- VPC
- Subnets
- Internet Gateway
- Route Tables
- Security Groups
- IAM Roles & Instance Profiles

## ⚠️ Lưu ý

1. **Terminated vs Stopped**: 
   - Stopped instances vẫn còn trong LocalStack và có thể khởi động lại
   - Terminated instances sẽ bị xóa vĩnh viễn

2. **Terraform State**: 
   - Nếu terminate instances bằng AWS CLI, Terraform state vẫn có thể chứa thông tin về instances
   - Nên destroy qua Terraform để sync state

3. **LocalStack Data**:
   - LocalStack lưu data trong `./localstack-data/`
   - Nếu muốn cleanup hoàn toàn, có thể xóa thư mục này (sau khi stop LocalStack)

## 🧹 Full Cleanup (Tất cả)

Nếu muốn cleanup hoàn toàn LocalStack:

```powershell
# 1. Stop LocalStack
docker-compose -f docker-compose.localstack.yml down

# 2. Xóa LocalStack data
Remove-Item -Recurse -Force ./localstack-data

# 3. Start lại LocalStack (nếu cần)
docker-compose -f docker-compose.localstack.yml up -d localstack
```

## 📝 Troubleshooting

### Instance không terminate được

```powershell
# Kiểm tra state của instance
aws --endpoint-url=http://localhost:4567 ec2 describe-instances --instance-ids i-fa8ad53b5222216b3

# Force terminate (nếu LocalStack hỗ trợ)
aws --endpoint-url=http://localhost:4567 ec2 terminate-instances --instance-ids i-fa8ad53b5222216b3 --force
```

### LocalStack không response

```powershell
# Restart LocalStack
docker-compose -f docker-compose.localstack.yml restart localstack

# Hoặc stop và start lại
docker-compose -f docker-compose.localstack.yml down
docker-compose -f docker-compose.localstack.yml up -d localstack
```

