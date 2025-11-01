import express, { Application } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { connectDatabase } from './config/database';
import { initializeKafkaProducer, disconnectKafkaProducer } from './config/kafka';
import { itemRouter } from './presentation/routes/item.routes';
import { healthRouter } from './presentation/routes/health.routes';
import { DIContainer } from './infrastructure/di/container';

dotenv.config();

const app: Application = express();
const PORT = process.env.PORT || 3000;

// Dependency Injection - Initialize DI container
const diContainer = new DIContainer();

// Make use cases available to controllers via app.locals
app.locals.getAllItemsUseCase = diContainer.getAllItemsUseCase;
app.locals.getItemByIdUseCase = diContainer.getItemByIdUseCase;
app.locals.getItemByNameUseCase = diContainer.getItemByNameUseCase;
app.locals.createItemUseCase = diContainer.createItemUseCase;
app.locals.updateItemUseCase = diContainer.updateItemUseCase;
app.locals.deleteItemUseCase = diContainer.deleteItemUseCase;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/items', itemRouter);
app.use('/health', healthRouter);

// Start server
const startServer = async (): Promise<void> => {
  try {
    await connectDatabase();
    await initializeKafkaProducer();
    app.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM signal received: closing HTTP server');
  await disconnectKafkaProducer();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('SIGINT signal received: closing HTTP server');
  await disconnectKafkaProducer();
  process.exit(0);
});

startServer();

