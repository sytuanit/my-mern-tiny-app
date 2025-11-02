# Architecture Overview: my-tiny-app-ui

## 🧭 1. Business Capabilities

| Capability | Summary | Entry Points |
|------------|---------|--------------|
| Item Management | Provides a web interface for managing items with full CRUD operations (Create, Read, Update, Delete). Users can view all items, create new ones, edit existing items, and delete items. | `/` (Home page), Client-side form submissions, Button clicks |
| Item Search | Enables users to search for items by name. Returns a single matching item if found, or displays a "not found" message. | Search form submission on `/` |
| Item Display | Renders item information in card format with actions (edit, delete). Displays item details including name, description, price, quantity, and timestamps. | Page load, Search results, CRUD operations |

## 🚪 2. Entrypoints

| Type | Identifier | Handler (file#fn) | Capability | Business Intent | Validations | Core logic (file#fn) |
|------|------------|-------------------|-----------|-----------------|-------------|---------------------|
| HTTP (Page) | GET `/` | `src/app/page.tsx`<br>> `#Home` | Item Management | Display item management interface to users with search, create, edit, and list capabilities | None (public page) | `src/app/page.tsx`<br>> `#loadItems`, `#handleCreate`, `#handleUpdate`, `#handleDelete`, `#handleSearch` |
| Client Event | Form Submit (Create) | `src/components/ItemForm.tsx`<br>> `#handleSubmit` | Item Management | Allow users to create new items with name, description, price, and quantity | Required: name field; Optional: description, price (min 0), quantity (min 0) | `src/app/page.tsx`<br>> `#handleCreate` → `src/services/api.ts`<br>> `#createItem` |
| Client Event | Form Submit (Update) | `src/components/ItemForm.tsx`<br>> `#handleSubmit` | Item Management | Allow users to update existing items with modified information | Required: name field; Optional: description, price (min 0), quantity (min 0) | `src/app/page.tsx`<br>> `#handleUpdate` → `src/services/api.ts`<br>> `#updateItem` |
| Client Event | Button Click (Delete) | `src/components/ItemCard.tsx`<br>> `onClick={onDelete}` | Item Management | Allow users to delete items from the system with confirmation | User confirmation dialog | `src/app/page.tsx`<br>> `#handleDelete` → `src/services/api.ts`<br>> `#deleteItem` |
| Client Event | Form Submit (Search) | `src/components/SearchForm.tsx`<br>> `#handleSubmit` | Item Search | Enable users to find items by exact name match | Non-empty search string (trimmed) | `src/app/page.tsx`<br>> `#handleSearch` → `src/services/api.ts`<br>> `#searchItemByName` |
| Client Event | Page Load | `src/app/page.tsx`<br>> `useEffect` | Item Management | Automatically load and display all items when the page is first rendered | None | `src/app/page.tsx`<br>> `#loadItems` → `src/services/api.ts`<br>> `#getAllItems` |
| Client Event | Button Click (Refresh) | `src/app/page.tsx`<br>> `onClick={loadItems}` | Item Management | Allow users to manually refresh the item list | None | `src/app/page.tsx`<br>> `#loadItems` → `src/services/api.ts`<br>> `#getAllItems` |
| Client Event | Button Click (Edit) | `src/components/ItemCard.tsx`<br>> `onClick={onEdit}` | Item Management | Allow users to select an item for editing by populating the form | Item must exist | `src/app/page.tsx`<br>> `setEditingItem` |

## 🗄️ 3. Data Touchpoints

| Entity/Model | Read/Write | Where (file#fn) | Notes |
|--------------|------------|-----------------|-------|
| `Item` | Read | `src/app/page.tsx`<br>> `#loadItems`, `#handleSearch` | Fetched from external API via `apiService.getAllItems()` and `apiService.searchItemByName()`. State stored in React `useState<Item[]>` |
| `Item` | Write (Create) | `src/app/page.tsx`<br>> `#handleCreate` | Created via external API `apiService.createItem()`. New item added to local state array |
| `Item` | Write (Update) | `src/app/page.tsx`<br>> `#handleUpdate` | Updated via external API `apiService.updateItem()`. Local state updated with response |
| `Item` | Write (Delete) | `src/app/page.tsx`<br>> `#handleDelete` | Deleted via external API `apiService.deleteItem()`. Removed from local state array |
| `ItemInput` | Read | `src/components/ItemForm.tsx`<br>> `#handleChange`, `#handleSubmit` | Form input data collected from user input fields. Validated client-side (name required) |
| `ItemInput` | Write | `src/components/ItemForm.tsx`<br>> `useEffect` | Form data initialized from `Item` when editing, or empty when creating. State managed via `useState` |

**Data Flow Notes:**
- All data persistence is handled by the external backend API (`NEXT_PUBLIC_API_URL`)
- Frontend maintains ephemeral state in React components using `useState` hooks
- No local database or persistent storage in the frontend application
- Data models defined in `src/types/item.ts` as TypeScript interfaces

## 🌐 4. External Integrations

| Target | Called From (file#fn) | Payload (brief) | Retries/Timeouts |
|--------|----------------------|-----------------|------------------|
| Backend API `GET /api/items/` | `src/services/api.ts`<br>> `#getAllItems` | None | Axios default (no explicit retry/timeout configured) |
| Backend API `GET /api/items/:id` | `src/services/api.ts`<br>> `#getItemById` | None (ID in URL path) | Axios default; 404 returns null |
| Backend API `POST /api/items/search` | `src/services/api.ts`<br>> `#searchItemByName` | `{ name: string }` | Axios default; 404 returns null |
| Backend API `POST /api/items/` | `src/services/api.ts`<br>> `#createItem` | `ItemInput: { name, description?, price?, quantity? }` | Axios default; throws on failure |
| Backend API `PUT /api/items/:id` | `src/services/api.ts`<br>> `#updateItem` | `Partial<ItemInput>` (ID in URL path) | Axios default; 404 returns null |
| Backend API `DELETE /api/items/:id` | `src/services/api.ts`<br>> `#deleteItem` | None (ID in URL path) | Axios default; 404 returns null |

**Integration Configuration:**
- Base URL: `process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000'`
- API Client: Axios instance configured in `src/services/api.ts` constructor
- Headers: `Content-Type: application/json`
- Error Handling: 404 errors return `null`; other errors are thrown and handled by components
- Response Format: Expects `ApiResponse<T>` wrapper with `{ success, data, message?, error? }`

