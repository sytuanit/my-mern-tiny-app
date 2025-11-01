# Libraries Usage Overview - my-tiny-app-consumer

This document analyzes which libraries and dependencies declared in `package.json` are **actually used** in the codebase.

---

## 📦 1. Dependency Summary

### Web / API Frameworks

| Library / Module | Purpose | Where Used (files or packages) | Key Functions / Imports | Notes |
|------------------|---------|--------------------------------|-------------------------|-------|
| express v4.18.2 | HTTP server framework for Node.js | `src/index.ts` | `Application`, `express()`, `app.use()`, `app.get()`, `app.listen()`, `express.json()`, `express.urlencoded()` | **Core** - Used for HTTP server and health check endpoint |
| cors v2.8.5 | Cross-Origin Resource Sharing middleware | `src/index.ts` | `cors()` | **Peripheral** - Used as middleware for enabling CORS |

### Database / ORM

| Library / Module | Purpose | Where Used (files or packages) | Key Functions / Imports | Notes |
|------------------|---------|--------------------------------|-------------------------|-------|
| mongoose v8.0.3 | MongoDB object modeling for Node.js | `src/config/database.ts`, `src/models/consumed-item.model.ts` | `mongoose.connect()`, `mongoose.model()`, `Document`, `Schema`, `model.findOneAndUpdate()`, `model.findOneAndDelete()` | **Core** - Essential for MongoDB connection and data modeling. Used for syncing consumed items to MongoDB |

### Messaging / Queue

| Library / Module | Purpose | Where Used (files or packages) | Key Functions / Imports | Notes |
|------------------|---------|--------------------------------|-------------------------|-------|
| kafkajs v2.2.4 | Kafka client for Node.js | `src/config/kafka.ts` | `Kafka`, `Consumer`, `EachMessagePayload`, `kafka.consumer()`, `consumer.connect()`, `consumer.subscribe()`, `consumer.run()`, `consumer.disconnect()` | **Core** - Essential for consuming item events from Kafka topic. Primary purpose of this service |

### Configuration / Utilities

| Library / Module | Purpose | Where Used (files or packages) | Key Functions / Imports | Notes |
|------------------|---------|--------------------------------|-------------------------|-------|
| dotenv v16.3.1 | Loads environment variables from .env file | `src/index.ts` | `dotenv.config()` | **Core** - Used for loading environment variables (MONGODB_URI, KAFKA_BROKER, etc.) |
| zod v3.22.4 | TypeScript-first schema validation library | `src/config/kafka.ts`, `src/models/consumed-item.model.ts` | `z.object()`, `z.enum()`, `z.string()`, `z.record()`, `z.unknown()`, `z.number()`, `z.date()`, `z.union()`, `z.transform()`, `z.infer()`, `safeParse()` | **Core** - Used for runtime validation of Kafka event payloads and type inference. Critical for data validation |

### Unused Dependencies

| Library / Module | Listed in package.json | Actually Used | Recommendation |
|------------------|------------------------|---------------|----------------|
| lodash v4.17.21 | ✅ Yes | ❌ No | **Should be removed** - Not imported or used anywhere in the codebase |

---

## 🧭 2. Core vs Peripheral Libraries

| Category | Libraries | Used In Packages | Comment |
|----------|-----------|-------------------|---------|
| **Core** | `mongoose`, `kafkajs`, `zod`, `dotenv`, `express` | `src/config/`, `src/models/`, `src/services/`, `src/index.ts` | These form the essential runtime stack. `mongoose` for MongoDB operations, `kafkajs` for event consumption (primary purpose), `zod` for event validation, `express` for HTTP health checks, `dotenv` for configuration |
| **Peripheral** | `cors` | `src/index.ts` | Optional middleware for CORS support. Could be removed if health checks don't need cross-origin access |
| **Unused** | `lodash` | None | Should be removed from dependencies to reduce bundle size |

---

## 🔍 3. Observations

### Core Tech Stack
- **Messaging**: `kafkajs` - The primary purpose of this service is consuming Kafka events
- **Database**: `mongoose` - Used for MongoDB operations on `consumed-items` collection
- **Validation**: `zod` - Critical for validating Kafka event payloads at runtime
- **HTTP Server**: `express` - Minimal usage, only for health check endpoint (`/health`)

### Unused / Redundant Libraries
- **`lodash`** - Declared in dependencies but never imported or used. **Recommendation**: Remove from `package.json` to reduce bundle size and dependency count.

### Version Status
- All libraries are using recent stable versions:
  - `mongoose v8.0.3` - Latest major version
  - `kafkajs v2.2.4` - Stable version
  - `zod v3.22.4` - Current major version
  - `express v4.18.2` - Latest stable 4.x version

### Potential Simplifications

1. **Remove `lodash`**: Not used anywhere. Safe to remove.
2. **Consider removing `cors`**: If health check endpoint doesn't need CORS (typically accessed internally), this dependency could be removed.
3. **Minimal Express usage**: Only used for a single health check endpoint. Consider if this is necessary or if a simpler approach would suffice (though Express overhead is minimal).

### Dev Dependencies Analysis

| Dev Dependency | Purpose | Used In |
|----------------|---------|---------|
| `typescript v5.3.3` | TypeScript compiler | Build process (`npm run build`) |
| `ts-node-dev v2.0.0` | Development server with hot-reload | Development script (`npm run dev`) |
| `@types/express v4.17.21` | TypeScript definitions for Express | Compile-time type checking |
| `@types/node v20.10.5` | TypeScript definitions for Node.js | Compile-time type checking |
| `@types/cors v2.8.17` | TypeScript definitions for CORS | Compile-time type checking |
| `@types/lodash v4.14.202` | TypeScript definitions for Lodash | **NOT NEEDED** - Should be removed since `lodash` is unused |

### Dependency Usage Summary

**Total Runtime Dependencies**: 7  
**Actually Used**: 6 (86%)  
**Unused**: 1 (`lodash`)  

**Total Dev Dependencies**: 6  
**Actually Used**: 5  
**Unused**: 1 (`@types/lodash`)  

---

## 📊 4. Recommended Actions

1. ✅ **Remove `lodash`** from `dependencies`
2. ✅ **Remove `@types/lodash`** from `devDependencies`
3. ⚠️ **Consider removing `cors`** if health checks don't require CORS (optional)
4. ✅ **Run `npm install`** after removing unused dependencies to update `package-lock.json`

### Cleanup Command
```bash
npm uninstall lodash @types/lodash
```

---

**Report Generated**: Based on actual source code analysis of `my-tiny-app-consumer`  
**Analysis Date**: Based on codebase structure  
**Total Source Files Analyzed**: 5 TypeScript files in `src/` directory

