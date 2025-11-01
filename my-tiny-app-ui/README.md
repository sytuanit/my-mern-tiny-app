# My Tiny App UI

Next.js frontend application for testing CRUD operations of the My Tiny App API.

## Features

- ✅ **Create Items** - Add new items with name, description, price, and quantity
- ✅ **Read Items** - View all items in a beautiful grid layout
- ✅ **Update Items** - Edit existing items
- ✅ **Delete Items** - Remove items with confirmation
- ✅ **Search Items** - Search items by name
- 🔄 **Real-time Updates** - Refresh and see latest data

## Tech Stack

- **Next.js 14** - React framework with App Router
- **TypeScript** - Type-safe development
- **Axios** - HTTP client for API calls
- **CSS Modules** - Styled components with modern design

## Getting Started

### Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Open http://localhost:3000
```

### Production Build

```bash
# Build for production
npm run build

# Start production server
npm start
```

## Docker Deployment

The UI is configured to run with Docker Compose alongside the backend services.

### Environment Variables

- `NEXT_PUBLIC_API_URL` - Backend API URL (default: http://localhost:3000)

### Build and Run with Docker Compose

```bash
# From project root
docker-compose up -d ui

# Or rebuild
docker-compose up -d --build ui
```

The UI will be available at: **http://localhost:3002**

## API Integration

The UI connects to the My Tiny App API running on port 3000. Make sure the backend service is running before starting the UI.

### API Endpoints Used

- `GET /api/items` - Get all items
- `GET /api/items/:id` - Get item by ID
- `POST /api/items/search` - Search item by name
- `POST /api/items` - Create new item
- `PUT /api/items/:id` - Update item
- `DELETE /api/items/:id` - Delete item

## Project Structure

```
my-tiny-app-ui/
├── src/
│   ├── app/              # Next.js App Router pages
│   │   ├── page.tsx      # Main page (Home)
│   │   ├── layout.tsx    # Root layout
│   │   └── globals.css   # Global styles
│   ├── components/       # React components
│   │   ├── ItemCard.tsx  # Item display card
│   │   ├── ItemForm.tsx  # Create/Edit form
│   │   └── SearchForm.tsx # Search component
│   ├── services/         # API services
│   │   └── api.ts        # API client
│   └── types/            # TypeScript types
│       └── item.ts       # Item types
├── Dockerfile            # Docker configuration
├── package.json          # Dependencies
└── tsconfig.json         # TypeScript config
```

## Features Overview

### Home Page

- **Search Section**: Search items by name
- **Create/Edit Form**: Add new items or edit existing ones
- **Items Grid**: Display all items in cards with actions

### Item Card

Each item card displays:
- Name and description
- Price and quantity
- Created and updated timestamps
- Edit and Delete buttons

### Form Validation

- Name is required
- Price must be positive (optional)
- Quantity must be non-negative integer (optional)

## Development Notes

- The UI uses client-side rendering with React hooks
- All API calls are handled through the `apiService` class
- Error handling and user feedback are implemented with message notifications
- The design is responsive and modern with gradient backgrounds

