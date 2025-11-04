# Cài đặt Chocolatey trên Windows

## 🚀 Cách 1: Dùng Script (Khuyến nghị)

### Bước 1: Mở PowerShell as Administrator

1. Nhấn `Win + X`
2. Chọn **Windows PowerShell (Admin)** hoặc **Terminal (Admin)**
3. Hoặc tìm "PowerShell" → Right-click → **Run as Administrator**

### Bước 2: Chạy Script

```powershell
cd D:\working\my-study\nodejs\my-mern-tiny-app
.\install-chocolatey.ps1
```

---

## 🚀 Cách 2: Cài trực tiếp (Nhanh nhất)

Mở PowerShell as Administrator và chạy:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

---

## ✅ Kiểm tra cài đặt

Sau khi cài xong, kiểm tra:

```powershell
choco --version
```

Nếu hiện version (ví dụ: `2.2.2`) là thành công!

---

## 📦 Sau khi cài Chocolatey, cài Minikube

```powershell
choco install minikube -y
```

Sau đó cài thêm:
```powershell
choco install kubernetes-cli -y  # kubectl
choco install docker-desktop -y  # Docker (nếu chưa có)
```

---

## ⚠️ Lưu ý

- **PHẢI** chạy PowerShell với quyền Administrator
- Nếu gặp lỗi `Execution Policy`, chạy: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
- Sau khi cài xong, **restart PowerShell** hoặc chạy `refreshenv`

---

## 🐛 Troubleshooting

### Lỗi: "choco is not recognized"

**Giải pháp:**
1. Restart PowerShell (đóng và mở lại)
2. Hoặc chạy: `refreshenv`
3. Kiểm tra PATH: `$env:Path -split ';' | Select-String chocolatey`

### Lỗi: "Execution Policy"

**Giải pháp:**
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Lỗi: "Access Denied"

**Giải pháp:**
- Đảm bảo đang chạy PowerShell as Administrator
- Right-click PowerShell → Run as Administrator

