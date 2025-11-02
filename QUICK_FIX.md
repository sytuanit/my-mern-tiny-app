# Quick Fix - Port 4566 Already in Use

## Vấn đề
Port 4566 đã được sử dụng bởi container hoặc process khác.

## Giải pháp nhanh

### Option 1: Dùng port khác (4567)
File `docker-compose.localstack.yml` đã được cập nhật để dùng port 4567.

**Lưu ý:** Khi dùng port 4567, cần update:
- Terraform endpoint: `http://localhost:4567`
- AWS CLI endpoint: `--endpoint-url=http://localhost:4567`
- Health check: `curl http://localhost:4567/_localstack/health`

### Option 2: Tìm và xóa container đang dùng port 4566

```powershell
# Tìm containers
docker ps -a | Select-String "localstack"

# Xóa container cũ
docker rm -f <container-id>

# Hoặc xóa tất cả
docker rm -f $(docker ps -aq --filter "name=localstack")
```

### Option 3: Kiểm tra và kill process

```powershell
# Tìm process đang dùng port 4566
$connection = Get-NetTCPConnection -LocalPort 4566 -ErrorAction SilentlyContinue
if ($connection) {
    $process = Get-Process -Id $connection.OwningProcess
    Write-Host "Process using port 4566: $($process.ProcessName) (PID: $($process.Id))"
    # Kill process nếu cần
    # Stop-Process -Id $process.Id -Force
}
```

## Start với port mới (4567)

```powershell
docker compose -f docker-compose.localstack.yml up -d localstack
```

Sau đó test:
```powershell
curl http://localhost:4567/_localstack/health
```

## Cập nhật Terraform và scripts

Nếu đổi port, cần update:
1. `terraform/localstack/main.tf` - endpoints
2. Scripts trong `scripts/` - endpoint URLs

