# Quick Start Guide - Windows PowerShell

## 🚀 Cách Start LocalStack trên Windows

### Option 1: Sử dụng PowerShell Script (Khuyến nghị)

**Bước 1: Cho phép chạy script PowerShell (chỉ cần làm 1 lần)**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Bước 2: Start LocalStack**
```powershell
.\Makefile.ps1 localstack-up
```

### Option 2: Chạy trực tiếp Docker Compose

```powershell
# Start LocalStack và infrastructure
docker-compose -f docker-compose.localstack.yml up -d localstack mongodb kafka zookeeper

# Kiểm tra status
docker-compose -f docker-compose.localstack.yml ps
```

### Option 3: Chạy từng lệnh riêng

```powershell
# 1. Start LocalStack
docker-compose -f docker-compose.localstack.yml up -d localstack

# 2. Start MongoDB
docker-compose -f docker-compose.localstack.yml up -d mongodb

# 3. Start Kafka & Zookeeper
docker-compose -f docker-compose.localstack.yml up -d kafka zookeeper

# 4. Đợi services ready (10 giây)
Start-Sleep -Seconds 10

# 5. Kiểm tra LocalStack health
curl http://localhost:4566/_localstack/health
```

## ✅ Verify Services đang chạy

```powershell
# Xem tất cả containers
docker ps

# Kiểm tra LocalStack
curl http://localhost:4566/_localstack/health

# Xem logs LocalStack
docker logs localstack

# Xem logs các services khác
docker logs my-tiny-app-mongodb
docker logs my-tiny-app-kafka
```

## 🛑 Stop Services

```powershell
# Stop tất cả
docker-compose -f docker-compose.localstack.yml down

# Hoặc dùng script
.\Makefile.ps1 localstack-down
```

## 📝 Lưu ý

1. **Nếu gặp lỗi Execution Policy:**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Nếu Docker chưa chạy:**
   - Mở Docker Desktop và đợi nó khởi động xong

3. **Kiểm tra port đã được sử dụng chưa:**
   ```powershell
   netstat -ano | findstr :4566  # LocalStack
   netstat -ano | findstr :27017 # MongoDB
   netstat -ano | findstr :9092  # Kafka
   ```

