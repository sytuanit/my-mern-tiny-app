# My Tiny App - Node.js Express CRUD API

Ứng dụng Node.js với Express và MongoDB cung cấp các chức năng CRUD (Create, Read, Update, Delete).

## Công nghệ sử dụng

- **Node.js** với **TypeScript**
- **Express.js** - Web framework
- **MongoDB** với **Mongoose** - Database
- **Zod** - Schema validation
- **Docker & Docker Compose** - Containerization

## Cấu trúc project

```
my-tiny-app/
├── src/
│   ├── config/
│   │   └── database.ts          # MongoDB connection
│   ├── models/
│   │   └── item.model.ts        # Mongoose model và Zod schema
│   ├── controllers/
│   │   └── item.controller.ts   # Business logic
│   ├── routes/
│   │   └── item.routes.ts       # API routes
│   └── index.ts                 # Entry point
├── dist/                         # Compiled JavaScript (auto-generated)
├── docker-compose.yml
├── Dockerfile
├── package.json
└── tsconfig.json
```

## API Endpoints

### Base URL: `http://localhost:3000/api/items`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/items` | Lấy danh sách tất cả items |
| GET | `/api/items/:id` | Lấy chi tiết item theo ID |
| POST | `/api/items` | Tạo item mới |
| PUT | `/api/items/:id` | Cập nhật item theo ID |
| DELETE | `/api/items/:id` | Xóa item theo ID |

### Request/Response Examples

#### 1. Lấy danh sách items

```bash
GET http://localhost:3000/api/items
```

Response:
```json
{
  "success": true,
  "count": 2,
  "data": [
    {
      "_id": "...",
      "name": "Item 1",
      "description": "Description",
      "price": 100,
      "quantity": 10,
      "createdAt": "...",
      "updatedAt": "..."
    }
  ]
}
```

#### 2. Lấy chi tiết item

```bash
GET http://localhost:3000/api/items/:id
```

#### 3. Tạo item mới

```bash
POST http://localhost:3000/api/items
Content-Type: application/json

{
  "name": "New Item",
  "description": "Item description",
  "price": 99.99,
  "quantity": 5
}
```

#### 4. Cập nhật item

```bash
PUT http://localhost:3000/api/items/:id
Content-Type: application/json

{
  "name": "Updated Item",
  "price": 150
}
```

#### 5. Xóa item

```bash
DELETE http://localhost:3000/api/items/:id
```

## Cài đặt và chạy với Docker Compose

### Yêu cầu

- Docker
- Docker Compose

### Các bước

1. Clone hoặc tải project

2. Tạo file `.env` (tùy chọn, mặc định đã có trong docker-compose.yml):
```env
PORT=3000
MONGODB_URI=mongodb://mongodb:27017/my-tiny-app
NODE_ENV=production
```

3. Build và chạy với Docker Compose:
```bash
docker-compose up --build
```

4. Kiểm tra health check:
```bash
curl http://localhost:3000/health
```

5. Dừng services:
```bash
docker-compose down
```

6. Dừng và xóa volumes (xóa data):
```bash
docker-compose down -v
```

## Phát triển local (không dùng Docker)

### Yêu cầu

- Node.js 20+
- MongoDB (chạy local hoặc MongoDB Atlas)

### Các bước

1. Cài đặt dependencies:
```bash
npm install
```

2. Tạo file `.env`:
```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/my-tiny-app
NODE_ENV=development
```

3. Chạy ở chế độ development:
```bash
npm run dev
```

4. Build production:
```bash
npm run build
npm start
```

## Validation

API sử dụng Zod để validate dữ liệu. Schema validation:

- `name`: Bắt buộc, tối đa 100 ký tự
- `description`: Tùy chọn, tối đa 500 ký tự
- `price`: Tùy chọn, phải là số dương
- `quantity`: Tùy chọn, phải là số nguyên không âm

## Scripts

- `npm run dev` - Chạy development server với hot reload
- `npm run build` - Build TypeScript sang JavaScript
- `npm start` - Chạy production server
- `npm run lint` - Chạy linter

## License

ISC

