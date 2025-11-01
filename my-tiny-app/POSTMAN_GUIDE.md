# Hướng dẫn sử dụng Postman Collection

## Import vào Collection "Study" - Folder "NodeJS"

### Cách import vào folder NodeJS trong collection Study:

1. **Mở Postman** và đảm bảo bạn đang ở collection **"Study"**

2. **Import collection mới:**
   - Click **Import** (góc trên bên trái)
   - Chọn file `My-Tiny-App-API.postman_collection.json`
   - Click **Import**
   - Collection "My Tiny App API" sẽ xuất hiện (có folder "My Tiny App" chứa tất cả requests)

3. **Copy requests vào folder NodeJS:**
   - Mở collection **"My Tiny App API"**
   - Mở folder **"My Tiny App"**
   - Chọn tất cả requests (Ctrl+A hoặc click từng request với Ctrl/Cmd)
   - **Right-click** → Chọn **Copy** hoặc **Duplicate**
   - Mở collection **"Study"**
   - Mở folder **"NodeJS"**
   - **Right-click** vào folder "NodeJS" → Chọn **Paste** hoặc **Paste after**

4. **Xóa collection tạm (tùy chọn):**
   - Nếu không cần collection "My Tiny App API" nữa, có thể xóa nó

### Cách khác - Import và đổi tên folder:

1. Import collection như bước 2 ở trên
2. Trong collection "My Tiny App API", **rename folder "My Tiny App" thành "NodeJS"**
3. **Cut/Move** folder "NodeJS" từ collection "My Tiny App API" vào collection "Study"

## Setup Variables

Sau khi import, collection đã có sẵn 2 variables:

1. **baseUrl**: `http://localhost:3000` (đã set mặc định)
2. **itemId**: Để trống (sẽ set sau khi tạo item mới)

### Cách set itemId sau khi tạo item:

1. Chạy request **"3. POST - Create New Item"**
2. Trong response, copy giá trị `_id`
3. Click vào collection name → tab **Variables**
4. Set giá trị cho `itemId` = ID vừa copy
5. Hoặc trong request, replace `{{itemId}}` bằng ID trực tiếp

## Test Sequence (Thứ tự test)

1. **Health Check** - Kiểm tra server đang chạy
2. **1. GET - Get All Items** - Xem danh sách (có thể trống)
3. **3. POST - Create New Item** - Tạo item mới
   - Copy `_id` từ response và set vào variable `itemId`
4. **2. GET - Get Item By ID** - Xem chi tiết item vừa tạo
5. **1. GET - Get All Items** - Xem lại danh sách (có item mới)
6. **5. PUT - Update Item** - Cập nhật item
7. **2. GET - Get Item By ID** - Kiểm tra đã cập nhật
8. **7. DELETE - Delete Item** - Xóa item
9. **2. GET - Get Item By ID** - Kiểm tra đã xóa (sẽ trả về 404)

## Request Examples

### Create Item với đầy đủ fields:
```json
{
  "name": "Laptop Dell XPS 15",
  "description": "High-performance laptop for developers",
  "price": 1599.99,
  "quantity": 5
}
```

### Create Item chỉ với name (required):
```json
{
  "name": "Simple Item"
}
```

### Update Item (partial - chỉ một field):
```json
{
  "price": 1299.99
}
```

### Update Item (nhiều fields):
```json
{
  "name": "Updated Name",
  "description": "Updated description",
  "price": 1499.99,
  "quantity": 3
}
```

## Response Examples

### Success Response (200/201)
```json
{
  "success": true,
  "data": {
    "_id": "6905a4ee7159478e535ecc74",
    "name": "Laptop Dell XPS 15",
    "description": "High-performance laptop",
    "price": 1599.99,
    "quantity": 5,
    "createdAt": "2025-11-01T06:13:02.847Z",
    "updatedAt": "2025-11-01T06:13:02.847Z",
    "__v": 0
  }
}
```

### Error Response (404)
```json
{
  "success": false,
  "message": "Item not found"
}
```

### Error Response (400 - Validation)
```json
{
  "success": false,
  "message": "Validation error",
  "errors": [
    {
      "code": "too_small",
      "minimum": 1,
      "type": "string",
      "message": "Name is required",
      "path": ["name"]
    }
  ]
}
```

## Tips

- Sử dụng **Collection Runner** để chạy tất cả requests tự động
- Tạo **Tests** scripts để tự động lưu `_id` vào variable sau khi tạo item
- Sử dụng **Environments** để switch giữa development và production

