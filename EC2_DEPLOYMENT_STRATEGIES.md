# Chiến lược Deploy lên EC2

## ❓ Câu hỏi: Có phải deploy TẤT CẢ lên EC2?

**Trả lời ngắn gọn: KHÔNG nhất thiết!** Có nhiều cách tiếp cận, tùy vào mục đích.

## 🏗️ Các Cách Tiếp Cận

### **Option 1: Tất cả lên EC2 (Monolithic EC2)**

```
┌─────────────────────────────────────────┐
│  EC2 Instance 1 (app)                  │
│  ├── my-tiny-app (container)           │
│  └── MongoDB (container)                │
│                                         │
│  EC2 Instance 2 (consumer)             │
│  ├── my-tiny-app-consumer (container)  │
│  └── Kafka (container)                  │
└─────────────────────────────────────────┘
```

**Ưu điểm:**
- ✅ Đơn giản - mọi thứ ở một chỗ
- ✅ Dễ deploy (1 lệnh Terraform)
- ✅ Phù hợp cho testing/prototyping

**Nhược điểm:**
- ❌ Không scalable
- ❌ Không phản ánh production (production thường dùng managed services)
- ❌ Resource intensive cho EC2 instances
- ❌ Khó maintain

**Khi nào dùng:**
- Testing đơn giản
- Prototyping nhanh
- LocalStack testing

---

### **Option 2: Hybrid - Apps trên EC2, Services trên Docker Host (Khuyến nghị cho LocalStack)**

```
┌─────────────────────────────────────────┐
│  Docker Host                            │
│  ├── MongoDB (container)                │
│  ├── Kafka (container)                  │
│  └── LocalStack                         │
│                                         │
│  LocalStack EC2 Instances               │
│  ├── EC2 Instance 1                     │
│  │   └── my-tiny-app (container)       │
│  └── EC2 Instance 2                     │
│      └── my-tiny-app-consumer           │
└─────────────────────────────────────────┘
```

**Ưu điểm:**
- ✅ Test EC2 infrastructure mà không cần deploy services
- ✅ Services chạy ổn định trên Docker host
- ✅ Tiết kiệm resources cho EC2 instances
- ✅ Dễ debug services

**Nhược điểm:**
- ⚠️ Cần network connectivity từ EC2 tới Docker host
- ⚠️ Với LocalStack Community có thể có limitations

**Khi nào dùng:**
- Testing EC2 workflows
- Development với LocalStack
- Muốn test infrastructure riêng biệt với services

---

### **Option 3: AWS Production Pattern (Recommended cho Production)**

```
┌─────────────────────────────────────────┐
│  AWS Managed Services                   │
│  ├── Amazon RDS (MongoDB Atlas)         │
│  ├── Amazon MSK (Managed Kafka)         │
│  └── Amazon ECR (Container Registry)   │
│                                         │
│  EC2 Instances                          │
│  ├── EC2 Instance 1                     │
│  │   └── my-tiny-app (container)       │
│  └── EC2 Instance 2                     │
│      └── my-tiny-app-consumer           │
└─────────────────────────────────────────┘
```

**Ưu điểm:**
- ✅ Production-ready
- ✅ Scalable và reliable
- ✅ Managed services tự động backup, monitoring
- ✅ Best practices

**Nhược điểm:**
- ❌ Phức tạp hơn
- ❌ Cần AWS account và phí
- ❌ Khó test local

**Khi nào dùng:**
- Production deployment
- Cần scalability và reliability
- Có budget cho AWS services

---

### **Option 4: Tất cả trên Docker (Simple Local Development)**

```
┌─────────────────────────────────────────┐
│  Docker Host                            │
│  ├── my-tiny-app (container)           │
│  ├── my-tiny-app-consumer (container)  │
│  ├── MongoDB (container)                │
│  ├── Kafka (container)                  │
│  └── LocalStack                         │
└─────────────────────────────────────────┘
```

**Ưu điểm:**
- ✅ Đơn giản nhất
- ✅ Dễ debug
- ✅ Phù hợp local development
- ✅ Không cần EC2

**Nhược điểm:**
- ❌ Không test được EC2 workflows
- ❌ Không phản ánh production infrastructure

**Khi nào dùng:**
- Local development
- Quick testing
- Không cần test EC2

---

## 🎯 Khuyến nghị cho từng Mục đích

### **1. Local Development (LocalStack)**
👉 **Option 4** (Tất cả trên Docker)
- Đơn giản, nhanh
- Dễ debug
- Không cần EC2

### **2. Test EC2 Infrastructure**
👉 **Option 2** (Hybrid)
- Apps trên EC2 instances
- Services trên Docker host
- Test được infrastructure mà không cần deploy services

### **3. Test Production-like Setup**
👉 **Option 1** (Tất cả lên EC2) hoặc **Option 3** (AWS Production)
- Tất cả trên EC2 (với LocalStack)
- Hoặc dùng AWS managed services (production)

### **4. Production**
👉 **Option 3** (AWS Production Pattern)
- EC2 cho apps
- Managed services cho data/services
- Best practices

---

## 🔧 Implementation cho từng Option

### **Option 1: Tất cả lên EC2**

Cần cập nhật Terraform để:
1. Tạo thêm EC2 instances cho MongoDB và Kafka
2. Hoặc deploy MongoDB và Kafka trong cùng EC2 instances với apps
3. Cập nhật network configs

```terraform
# EC2 Instance với tất cả services
resource "aws_instance" "full_stack" {
  # Install Docker
  # Run MongoDB container
  # Run Kafka container
  # Run app container
}
```

### **Option 2: Hybrid (Apps trên EC2, Services trên Docker)**

Hiện tại đã có setup này! Chỉ cần:
1. ✅ Services chạy trên Docker host (mongodb, kafka)
2. ✅ Apps deploy lên EC2 instances
3. ⚠️ Cần fix network config để EC2 containers connect tới Docker host services

**Cần sửa:**
- User_data script trong Terraform
- Dùng `host.docker.internal` hoặc Docker host IP
- Expose MongoDB và Kafka ports từ Docker host

### **Option 3: AWS Production**

Cần:
1. Setup Amazon RDS hoặc MongoDB Atlas
2. Setup Amazon MSK hoặc Confluent Cloud
3. EC2 instances connect tới managed services qua VPC endpoints

### **Option 4: Tất cả trên Docker**

Đã có sẵn! Chỉ cần:
```powershell
docker compose -f docker-compose.localstack.yml up -d
```

---

## 🚀 Khuyến nghị cho Dự án Hiện tại

### **Cho LocalStack Testing:**

**Tốt nhất: Option 2 (Hybrid)**
- ✅ Test được EC2 infrastructure
- ✅ Services chạy ổn định trên Docker
- ⚠️ Cần fix network connectivity

**Cách fix network:**
1. Expose MongoDB và Kafka ports từ Docker host
2. Update Terraform user_data để dùng host IP thay vì Docker network names
3. Hoặc dùng `--network host` cho containers trong EC2

**Code example:**

```terraform
# In EC2 user_data, thay vì:
MONGODB_URI=mongodb://mongodb:27017/my-tiny-app

# Dùng:
MONGODB_URI=mongodb://172.17.0.1:27017/my-tiny-app  # Docker bridge IP
# Hoặc
MONGODB_URI=mongodb://host.docker.internal:27017/my-tiny-app
```

---

## 📋 Tóm tắt

**Câu trả lời:**
- ❌ **KHÔNG cần** deploy tất cả lên EC2
- ✅ **CÓ THỂ** deploy chỉ apps lên EC2, services giữ trên Docker
- ✅ **HOẶC** deploy tất cả lên EC2 nếu muốn test full stack
- ✅ **TỐT NHẤT**: Hybrid approach cho LocalStack testing

**Khuyến nghị:**
- Cho LocalStack: **Hybrid (Option 2)** - Apps trên EC2, services trên Docker
- Cho Production: **AWS Pattern (Option 3)** - Apps trên EC2, managed services

**Next Steps:**
1. Nếu muốn test EC2 với hybrid: Fix network config trong Terraform
2. Nếu muốn test full stack trên EC2: Tạo thêm EC2 instances cho services
3. Nếu chỉ development: Giữ nguyên tất cả trên Docker

