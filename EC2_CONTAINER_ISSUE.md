# Vấn đề: Containers trong EC2 Instances không chạy được

## 🔍 Vấn đề hiện tại

EC2 instances đã được tạo trên LocalStack, nhưng containers bên trong chúng **không thể chạy** vì:

### 1. **Docker Network Names không hoạt động**
Trong `terraform/localstack/main.tf`, user_data script đang dùng:
- `MONGODB_URI=mongodb://mongodb:27017/...` ❌
- `KAFKA_BROKER=kafka:9093` ❌
- `AWS_ENDPOINT_URL=http://localstack:4566` ❌

**Vấn đề:** Containers trong EC2 instances (simulated) không thể resolve Docker network names (`mongodb`, `kafka`, `localstack`) vì:
- EC2 instances không join vào Docker network của host
- EC2 instances là simulated, không có real network stack

### 2. **LocalStack EC2 Limitations**
- EC2 instances trong LocalStack Community là **simulated**, không phải real VMs
- User data scripts có thể **không execute** hoặc execute nhưng không có effect
- Containers cần Docker daemon, nhưng EC2 instances không có real OS

### 3. **Network Isolation**
Containers trong EC2 instances không thể truy cập:
- Docker services trên host (mongodb, kafka, localstack)
- Docker network names
- Host network services (trừ khi expose qua security groups)

## ✅ Giải pháp

### **Option 1: Dùng Host Network Mode (Khuyến nghị cho LocalStack)**

Sửa user_data script để containers dùng host network hoặc connect tới services qua host IP:

```bash
# Thay vì mongodb:27017, dùng host.docker.internal hoặc localhost
MONGODB_URI=mongodb://host.docker.internal:27017/my-tiny-app

# Thay vì kafka:9093
KAFKA_BROKER=host.docker.internal:9093

# Thay vì localstack:4566
AWS_ENDPOINT_URL=http://host.docker.internal:4567
```

### **Option 2: Hybrid Approach (Khuyến nghị nhất)**

Giữ nguyên cách hiện tại:
- ✅ **EC2 instances** để mô phỏng infrastructure (VPC, Security Groups, etc.)
- ✅ **Containers** vẫn chạy trên Docker host (dễ debug, hoạt động tốt)
- ✅ Sử dụng LocalStack cho các AWS services khác (S3, SQS, etc.)

### **Option 3: LocalStack Pro**

Upgrade lên LocalStack Pro:
- ✅ EC2 support tốt hơn
- ✅ Containers có thể chạy trong EC2 instances
- ✅ Network connectivity tốt hơn

### **Option 4: AWS thật**

Deploy lên AWS EC2 thật:
- ✅ Real VMs, real network
- ✅ Containers chạy được trong EC2 instances
- ✅ Cần AWS account và credentials

## 🔧 Cách fix ngay (Option 1)

### Bước 1: Cập nhật Terraform variables để dùng host IP

Sửa `terraform/localstack/main.tf`:

```terraform
user_data = base64encode(<<-EOF
  #!/bin/bash
  # Install Docker
  yum update -y
  yum install -y docker
  systemctl start docker
  systemctl enable docker
  
  # Get host IP (nếu có thể)
  HOST_IP=$(ip route | grep default | awk '{print $3}')
  
  # Pull and run my-tiny-app container
  docker pull ${var.docker_registry}/my-tiny-app:latest || docker load -i /tmp/my-tiny-app.tar
  docker run -d \
    --name my-tiny-app \
    --restart unless-stopped \
    --network host \
    -e PORT=3000 \
    -e MONGODB_URI=mongodb://localhost:27017/my-tiny-app \
    -e KAFKA_BROKER=localhost:9092 \
    -e KAFKA_TOPIC=item-events \
    -e NODE_ENV=production \
    -e AWS_REGION=us-east-1 \
    -e AWS_ENDPOINT_URL=http://localhost:4567 \
    ${var.docker_registry}/my-tiny-app:latest
EOF
)
```

**Lưu ý:** Option này vẫn có thể không hoạt động vì LocalStack EC2 instances không có real network stack.

## 📋 Khuyến nghị

**Cho development hiện tại:**
1. ✅ **Giữ nguyên containers trên Docker host** (như hiện tại)
2. ✅ **EC2 instances chỉ để test Terraform configs**
3. ✅ **Sử dụng LocalStack cho S3, SQS, etc.**

**Khi cần test real EC2 workflows:**
1. ✅ Deploy lên **AWS thật**
2. ✅ Hoặc dùng **LocalStack Pro**
3. ✅ Hoặc dùng **hybrid approach** (EC2 cho infra, containers trên host)

## 🚀 Next Steps

1. **Nếu muốn giữ containers trên Docker host:**
   ```powershell
   # Không làm gì cả - giữ nguyên như hiện tại
   ```

2. **Nếu muốn thử fix containers trong EC2:**
   ```powershell
   # 1. Dừng containers hiện tại
   docker compose -f docker-compose.localstack.yml stop app consumer
   
   # 2. Sửa terraform/localstack/main.tf (dùng host network)
   
   # 3. Re-apply Terraform
   Set-Location terraform/localstack
   terraform apply
   Set-Location ../..
   ```

3. **Nếu muốn test trên AWS thật:**
   - Cập nhật Terraform với real AWS provider
   - Cung cấp real AWS credentials
   - Deploy lên real EC2 instances

