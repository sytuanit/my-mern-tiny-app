# Architecture Overview

# 🧭 1. Business Capabilities

| Capability | Summary | Entry Points |
|------------|---------|--------------|
| Item Management | Manage inventory items with CRUD operations. Allows users to create, read, update, and delete items with validation. | `GET /api/items`, `GET /api/items/:id`, `POST /api/items`, `PUT /api/items/:id`, `DELETE /api/items/:id` |
| Health Monitoring | System health check endpoint for monitoring and load balancer health checks. | `GET /health` |

# 🚪 2. Entrypoints

| Type | Identifier | Handler (file#fn) | Capability | Business Intent | Validations | Core logic (file#fn) |
|------|------------|-------------------|------------|------------------|-------------|----------------------|
| HTTP | GET /api/items | src/routes/item.routes.ts<br>> `#itemRouter.get('/', getAllItems)` | Item Management | Retrieve all items from inventory, sorted by creation date (newest first) for user browsing | None (public endpoint) | src/controllers/item.controller.ts<br>> `#getAllItems` |
| HTTP | GET /api/items/:id | src/routes/item.routes.ts<br>> `#itemRouter.get('/:id', getItemById)` | Item Management | Get detailed information about a specific item by ID for user viewing | MongoDB ObjectId format validation (implicit via mongoose) | src/controllers/item.controller.ts<br>> `#getItemById` |
| HTTP | POST /api/items | src/routes/item.routes.ts<br>> `#itemRouter.post('/', createItem)` | Item Management | Create a new item in inventory with validated data | Zod schema validation: name (required, 1-100 chars), description (optional, max 500 chars), price (optional, positive number), quantity (optional, non-negative integer) | src/controllers/item.controller.ts<br>> `#createItem` |
| HTTP | PUT /api/items/:id | src/routes/item.routes.ts<br>> `#itemRouter.put('/:id', updateItem)` | Item Management | Update existing item information, supports partial updates | Zod schema validation (partial): same as POST but all fields optional, MongoDB ObjectId format | src/controllers/item.controller.ts<br>> `#updateItem` |
| HTTP | DELETE /api/items/:id | src/routes/item.routes.ts<br>> `#itemRouter.delete('/:id', deleteItem)` | Item Management | Remove item from inventory by ID | MongoDB ObjectId format validation (implicit via mongoose) | src/controllers/item.controller.ts<br>> `#deleteItem` |
| HTTP | GET /health | src/index.ts<br>> `#app.get('/health', (_req, res) => {...})` | Health Monitoring | Provide server health status for monitoring systems and load balancers | None | src/index.ts<br>> `#app.get('/health', ...)` |

# 🗄️ 3. Data Touchpoints

| Entity/Model | Read/Write | Where (file#fn) | Notes |
|--------------|------------|----------------|-------|
| Item (items collection) | Read | src/controllers/item.controller.ts<br>> `#getAllItems`<br>src/controllers/item.controller.ts<br>> `#getItemById` | Mongoose query: `Item.find().sort({ createdAt: -1 })` - Retrieves all items sorted by creation date descending |
| Item (items collection) | Read | src/controllers/item.controller.ts<br>> `#getItemById` | Mongoose query: `Item.findById(id)` - Retrieves single item by MongoDB ObjectId |
| Item (items collection) | Write | src/controllers/item.controller.ts<br>> `#createItem` | Mongoose operation: `new Item(itemData).save()` - Creates new document with timestamps (createdAt, updatedAt) |
| Item (items collection) | Write | src/controllers/item.controller.ts<br>> `#updateItem` | Mongoose operation: `Item.findByIdAndUpdate(id, updateData, { new: true, runValidators: true })` - Updates document and returns updated version, automatically updates updatedAt timestamp |
| Item (items collection) | Write | src/controllers/item.controller.ts<br>> `#deleteItem` | Mongoose operation: `Item.findByIdAndDelete(id)` - Permanently removes document from collection |

# 🌐 4. External Integrations

| Target | Called From (file#fn) | Payload (brief) | Retries/Timeouts |
|--------|----------------------|-----------------|------------------|
| MongoDB Database | src/config/database.ts<br>> `#connectDatabase` | Connection string: `mongodb://mongodb:27017/my-tiny-app` (or from env MONGODB_URI) | No explicit retry mechanism, throws error on connection failure. Default Mongoose connection timeout applies |
| MongoDB Database (items collection) | src/controllers/item.controller.ts<br>> `#getAllItems` | Query: `Item.find().sort({ createdAt: -1 })` | Mongoose default query timeout (30s) |
| MongoDB Database (items collection) | src/controllers/item.controller.ts<br>> `#getItemById` | Query: `Item.findById(id)` | Mongoose default query timeout (30s) |
| MongoDB Database (items collection) | src/controllers/item.controller.ts<br>> `#createItem` | Write: `new Item(itemData).save()` | Mongoose default write timeout (30s) |
| MongoDB Database (items collection) | src/controllers/item.controller.ts<br>> `#updateItem` | Write: `Item.findByIdAndUpdate(id, updateData, { new: true, runValidators: true })` | Mongoose default write timeout (30s) |
| MongoDB Database (items collection) | src/controllers/item.controller.ts<br>> `#deleteItem` | Write: `Item.findByIdAndDelete(id)` | Mongoose default write timeout (30s) |

