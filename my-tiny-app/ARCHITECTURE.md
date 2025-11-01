# Clean Architecture Overview

This project follows **Clean Architecture** principles, making it a solid base for future projects.

## 📁 Directory Structure

```
src/
├── domain/              # Core Business Logic (Innermost Layer)
│   ├── entities/        # Business entities (pure objects, no dependencies)
│   └── interfaces/      # Repository and service interfaces (contracts)
│
├── application/         # Application Business Logic
│   └── use-cases/       # Application-specific business rules
│
├── infrastructure/      # Framework & Drivers (Outermost Layer)
│   ├── repositories/    # Database implementations
│   ├── messaging/       # External services (Kafka, etc.)
│   └── di/             # Dependency Injection container
│
├── presentation/        # Interface Adapters
│   ├── controllers/     # HTTP request/response handling
│   ├── routes/          # Express routes
│   └── dtos/           # Data Transfer Objects (validation)
│
├── models/             # Mongoose models (framework-specific)
└── config/              # Configuration (database, kafka, etc.)
```

## 🏗️ Layer Dependencies

The dependency rule: **Dependencies point inward**

```
presentation → application → domain
infrastructure → application → domain
```

- **Domain** has **NO dependencies** (pure TypeScript)
- **Application** depends only on **Domain**
- **Infrastructure** implements **Domain interfaces**
- **Presentation** uses **Application use cases**

## 📦 Components Explained

### 1. Domain Layer (`domain/`)

**Purpose**: Pure business logic, framework-independent

- **Entities**: Business objects with no external dependencies
- **Interfaces**: Contracts that infrastructure must implement

Example:
```typescript
// domain/entities/item.entity.ts
export interface ItemEntity {
  id: string;
  name: string;
  // ... business properties
}

// domain/interfaces/item.repository.interface.ts
export interface IItemRepository {
  findById(id: string): Promise<ItemEntity | null>;
  // ... other methods
}
```

### 2. Application Layer (`application/`)

**Purpose**: Application-specific business rules (Use Cases)

- Each use case represents a single business operation
- Uses domain entities and interfaces
- Orchestrates domain logic

Example:
```typescript
// application/use-cases/create-item.use-case.ts
export class CreateItemUseCase {
  constructor(
    private readonly itemRepository: IItemRepository,
    private readonly eventPublisher: IEventPublisher
  ) {}

  async execute(itemData: CreateItemInput): Promise<ItemEntity> {
    // Business logic here
  }
}
```

### 3. Infrastructure Layer (`infrastructure/`)

**Purpose**: Framework and external service implementations

- **Repositories**: MongoDB/Mongoose implementations
- **Messaging**: Kafka, RabbitMQ, etc.
- **DI Container**: Wires dependencies together

Example:
```typescript
// infrastructure/repositories/item.repository.ts
export class ItemRepository implements IItemRepository {
  // MongoDB implementation
}
```

### 4. Presentation Layer (`presentation/`)

**Purpose**: HTTP interface adapters

- **Controllers**: Handle HTTP requests/responses
- **Routes**: Express route definitions
- **DTOs**: Request/response validation with Zod

Example:
```typescript
// presentation/controllers/item.controller.ts
export const createItem = async (req: Request, res: Response) => {
  const useCase = req.app.locals.createItemUseCase;
  const item = await useCase.execute(req.body);
  // Return response
}
```

## 🔄 Data Flow

```
HTTP Request
  ↓
Routes (presentation/routes/)
  ↓
Controllers (presentation/controllers/)
  ↓
Use Cases (application/use-cases/)
  ↓
Repositories (infrastructure/repositories/)
  ↓
Database (MongoDB)
```

## ✅ Benefits

1. **Testability**: Easy to unit test (mock interfaces)
2. **Independence**: Framework-agnostic domain layer
3. **Scalability**: Add new features without breaking existing code
4. **Maintainability**: Clear separation of concerns
5. **Reusability**: Domain logic can be reused across projects

## 🚀 Adding New Features

1. **Add Entity** → `domain/entities/`
2. **Add Repository Interface** → `domain/interfaces/`
3. **Implement Repository** → `infrastructure/repositories/`
4. **Create Use Case** → `application/use-cases/`
5. **Create Controller** → `presentation/controllers/`
6. **Create Routes** → `presentation/routes/`
7. **Update DI Container** → `infrastructure/di/container.ts`

## 📝 Example: Adding a New Feature

Let's say you want to add a "Category" feature:

1. **Domain Entity**: `domain/entities/category.entity.ts`
2. **Repository Interface**: `domain/interfaces/category.repository.interface.ts`
3. **Repository Implementation**: `infrastructure/repositories/category.repository.ts`
4. **Use Cases**: `application/use-cases/create-category.use-case.ts`
5. **Controller**: `presentation/controllers/category.controller.ts`
6. **Routes**: `presentation/routes/category.routes.ts`
7. **Update DI Container**: Add category use cases to `container.ts`

## 🔧 Dependency Injection

All dependencies are wired in `infrastructure/di/container.ts`:

```typescript
export class DIContainer {
  private readonly itemRepository: ItemRepository;
  public readonly createItemUseCase: CreateItemUseCase;
  
  constructor() {
    this.itemRepository = new ItemRepository();
    this.createItemUseCase = new CreateItemUseCase(
      this.itemRepository,
      this.eventPublisher
    );
  }
}
```

Use cases are injected into controllers via `app.locals` in `index.ts`.

## 📚 Best Practices

1. **Keep domain pure**: No framework dependencies
2. **One use case per file**: Single responsibility
3. **Use interfaces**: Abstract implementations
4. **Validate in DTOs**: Keep validation at presentation layer
5. **Error handling**: Handle in controllers, let use cases throw

## 🎯 This is Your Base Project

This architecture is designed to be:
- **Scalable**: Easy to add new features
- **Testable**: Mock-friendly interfaces
- **Maintainable**: Clear structure
- **Reusable**: Copy structure for new projects

