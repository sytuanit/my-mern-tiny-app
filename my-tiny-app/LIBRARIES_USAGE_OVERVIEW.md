# Libraries Usage Overview

# 📦 1. Dependency Summary

## Web / API Frameworks

| Library / Module | Purpose | Where Used (files or packages) | Key Functions / Imports | Notes |
|------------------|---------|-------------------------------|------------------------|-------|
| express v4.18.2 | Web framework for building REST API endpoints and middleware | `src/index.ts`, `src/routes/item.routes.ts`, `src/controllers/item.controller.ts` | `express()`, `Application`, `Router()`, `Request`, `Response`, `app.use()`, `app.get()`, `router.get()`, `router.post()`, `router.put()`, `router.delete()`, `express.json()`, `express.urlencoded()` | **Core** - Essential for all HTTP routing and request handling. Used throughout the application for API endpoints |
| cors v2.8.5 | Cross-Origin Resource Sharing middleware to enable API access from different domains | `src/index.ts` | `cors()`, `app.use(cors())` | **Core** - Required for web frontend integration. Applied globally to all routes |

## Database / ORM

| Library / Module | Purpose | Where Used (files or packages) | Key Functions / Imports | Notes |
|------------------|---------|-------------------------------|------------------------|-------|
| mongoose v8.0.3 | MongoDB ODM (Object Document Mapper) for schema definition, validation, and queries | `src/config/database.ts`, `src/models/item.model.ts` | `mongoose.connect()`, `mongoose.model()`, `Schema`, `Document`, `model.find()`, `model.findById()`, `model.findByIdAndUpdate()`, `model.findByIdAndDelete()`, `new model().save()` | **Core** - Central to all data persistence. Used for connection management, schema definition, and all database operations (CRUD) |

## Configuration / Utilities

| Library / Module | Purpose | Where Used (files or packages) | Key Functions / Imports | Notes |
|------------------|---------|-------------------------------|------------------------|-------|
| dotenv v16.3.1 | Loads environment variables from .env file into process.env | `src/index.ts` | `dotenv.config()` | **Peripheral** - Used once at application startup to load configuration (PORT, MONGODB_URI) |
| zod v3.22.4 | Runtime TypeScript-first schema validation library for input validation | `src/models/item.model.ts`, `src/controllers/item.controller.ts` | `z.object()`, `z.string()`, `z.number()`, `z.infer<>`, `.safeParse()`, `.partial()` | **Core** - Critical for input validation on POST and PUT endpoints. Prevents invalid data from reaching database |

## Unused Dependencies

| Library / Module | Purpose | Where Used (files or packages) | Key Functions / Imports | Notes |
|------------------|---------|-------------------------------|------------------------|-------|
| lodash v4.17.21 | Utility library for array, object, and function manipulation | **Not imported anywhere** | N/A | **Unused** - Listed in dependencies but never imported. Can be safely removed to reduce bundle size |

## Development Dependencies

| Library / Module | Purpose | Where Used (files or packages) | Key Functions / Imports | Notes |
|------------------|---------|-------------------------------|------------------------|-------|
| typescript v5.3.3 | TypeScript compiler for type checking and transpilation | Build-time (`npm run build`) | Compiler configuration via `tsconfig.json` | **Build Tool** - Compiles TypeScript to JavaScript during build process |
| ts-node-dev v2.0.0 | TypeScript execution and hot-reload for development | Development scripts (`npm run dev`) | Runs `src/index.ts` directly with auto-restart on file changes | **Dev Tool** - Development-only, not included in production build |
| @types/express v4.17.21 | TypeScript type definitions for Express | Type checking in `src/index.ts`, `src/routes/item.routes.ts`, `src/controllers/item.controller.ts` | Provides types: `Application`, `Request`, `Response`, `Router` | **Type Definitions** - Enables TypeScript intellisense and type checking for Express |
| @types/node v20.10.5 | TypeScript type definitions for Node.js built-in modules | Type checking globally | Provides types for Node.js APIs (e.g., `process.env`) | **Type Definitions** - Required for TypeScript compilation |
| @types/cors v2.8.17 | TypeScript type definitions for CORS | Type checking in `src/index.ts` | Provides types for `cors()` middleware | **Type Definitions** - Enables TypeScript support for cors library |
| @types/lodash v4.14.202 | TypeScript type definitions for lodash | **Not used** (lodash is not imported) | N/A | **Unused** - Can be removed along with lodash dependency |

# 🧭 2. Core vs Peripheral Libraries

| Category | Libraries | Used In Packages | Comment |
|----------|-----------|-----------------|---------|
| **Core** | express, mongoose, zod | `src/index.ts`, `src/routes/`, `src/controllers/`, `src/models/`, `src/config/` | **Essential for runtime** - Application cannot function without these. Express handles HTTP, Mongoose handles data persistence, Zod handles input validation. Tightly coupled to application architecture |
| **Core** | cors | `src/index.ts` | **Required for web integration** - Necessary for frontend applications to access the API from different origins |
| **Peripheral** | dotenv | `src/index.ts` | **Configuration utility** - Loads environment variables at startup. Could be replaced with direct process.env access but improves maintainability |
| **Unused** | lodash, @types/lodash | None | **Removable** - No imports found. Safe to remove from dependencies |
| **Build Tools** | typescript, ts-node-dev | Build and development scripts | **Development only** - Not bundled in production. Required for TypeScript compilation and dev workflow |
| **Type Definitions** | @types/express, @types/node, @types/cors | Type checking globally | **Compile-time only** - Not included in runtime bundle. Required for TypeScript type safety |

# 🔍 3. Observations

## Core Tech Stack

- **express + mongoose + zod** form the primary runtime stack:
  - Express provides HTTP server and routing
  - Mongoose provides MongoDB data layer
  - Zod provides runtime validation
  - These three libraries are tightly integrated throughout the codebase

## Redundant or Unused Libraries

- **lodash v4.17.21** - Listed in dependencies but never imported in any source file
  - **Recommendation**: Remove from `package.json` to reduce bundle size and dependency overhead
  - **@types/lodash v4.14.202** - Also unused, should be removed with lodash

## Version Status

- All used dependencies are on recent, stable versions:
  - express v4.18.2 (latest v4.x)
  - mongoose v8.0.3 (latest major version)
  - zod v3.22.4 (latest v3.x)
  - dotenv v16.3.1 (latest)
  - cors v2.8.5 (latest)
- No deprecated libraries detected in the used dependencies

## Potential Simplifications

- **Remove lodash**: Since it's not used anywhere, removing it will:
  - Reduce `node_modules` size
  - Faster `npm install` times
  - Clearer dependency footprint
  - Remove security maintenance burden for unused code

- **Dependency consolidation**: Current dependencies are minimal and well-focused. No obvious consolidation opportunities without losing functionality.

## Architecture Notes

- **Clean dependency footprint**: Only 5 runtime dependencies (excluding unused lodash)
- **Type safety**: Full TypeScript coverage with proper type definitions for all external libraries
- **No over-engineering**: Each dependency serves a specific, necessary purpose
- **Build separation**: Development tools are properly separated from runtime dependencies

