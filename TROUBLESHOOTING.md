# Troubleshooting LocalStack trên Windows

## 🐛 Vấn đề thường gặp

### 1. LocalStack không start được

**Nguyên nhân:** Trên Windows, Docker socket mount (`/var/run/docker.sock`) không hoạt động.

**Giải pháp:** Đã cập nhật `docker-compose.localstack.yml` để sử dụng:
- `LAMBDA_EXECUTOR=local` thay vì `docker`
- `DOCKER_HOST=tcp://host.docker.internal:2375` cho Windows
- `extra_hosts` để resolve `host.docker.internal`

### 2. Container name conflict

**Lỗi:** `Error response from daemon: Conflict. The container name is already in use`

**Giải pháp:**
```powershell
# Stop và remove containers cũ
docker-compose -f docker-compose.yml down
docker rm -f my-tiny-app-zookeeper my-tiny-app-kafka my-tiny-app-mongodb localstack

# Hoặc xóa tất cả containers
docker ps -a | Select-String "my-tiny-app|localstack" | ForEach-Object { docker rm -f $_.Split()[0] }
```

### 3. LocalStack container exits ngay lập tức

**Kiểm tra logs:**
```powershell
docker logs localstack
```

**Các nguyên nhân có thể:**
- Port 4566 đã được sử dụng: `netstat -ano | findstr :4566`
- Volume permission issues (trên Windows thường không có vấn đề này)
- Memory/Resource limits

**Giải pháp:**
```powershell
# Kiểm tra port
netstat -ano | findstr :4566

# Nếu port đang được dùng, đổi port trong docker-compose:
# ports:
#   - "4567:4566"  # Thay đổi port host
```

### 4. Docker Desktop chưa chạy

**Kiểm tra:**
```powershell
docker ps
```

**Nếu lỗi:** "Cannot connect to the Docker daemon" → Cần mở Docker Desktop

### 5. Volume path issues trên Windows

**Vấn đề:** Windows paths có thể gây conflict với container paths

**Giải pháp:** Sử dụng relative path `./localstack-data` (đã cấu hình sẵn)

## 🔧 Các bước khắc phục nhanh

### Step 1: Clean up
```powershell
docker-compose -f docker-compose.localstack.yml down -v
docker system prune -f
```

### Step 2: Kiểm tra Docker
```powershell
docker ps
docker version
```

### Step 3: Start lại
```powershell
docker compose -f docker-compose.localstack.yml up -d localstack
```

### Step 4: Kiểm tra logs
```powershell
docker logs localstack -f
```

### Step 5: Test health
```powershell
Start-Sleep -Seconds 10
curl http://localhost:4566/_localstack/health
```

## 📝 Alternative: Chạy LocalStack đơn giản hơn

Nếu vẫn gặp vấn đề, có thể chạy LocalStack đơn giản:

```powershell
docker run -d `
  --name localstack `
  -p 4566:4566 `
  -e SERVICES=ec2,s3,iam,sts,ssm `
  -e DEBUG=1 `
  -v "./localstack-data:/var/lib/localstack" `
  localstack/localstack:latest
```

Sau đó kiểm tra:
```powershell
curl http://localhost:4566/_localstack/health
```

## 🔍 Debug Commands

```powershell
# Xem tất cả containers
docker ps -a

# Xem logs chi tiết
docker logs localstack --tail 100

# Kiểm tra networks
docker network ls
docker network inspect my-mern-tiny-app-localstack_app-network

# Kiểm tra volumes
docker volume ls
```

## 📚 Resources

- [LocalStack Documentation](https://docs.localstack.cloud/)
- [LocalStack Windows Setup](https://docs.localstack.cloud/getting-started/installation/)
- [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)

