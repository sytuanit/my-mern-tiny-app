import express, { Application } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { connectDatabase } from './config/database';
import { initializeKafkaConsumer, disconnectKafkaConsumer } from './config/kafka';
import { handleItemEvent } from './services/item-event-handler';
import { itemRouter } from './presentation/routes/item.routes';
import { healthRouter } from './presentation/routes/health.routes';
import { DIContainer } from './infrastructure/di/container';

dotenv.config();

const app: Application = express();
const PORT = process.env.PORT || 3001;

// Dependency Injection - Initialize DI container
const diContainer = new DIContainer();

// Make use cases available to controllers via app.locals
app.locals.searchItemByNameUseCase = diContainer.searchItemByNameUseCase;

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
    await initializeKafkaConsumer(handleItemEvent);
    app.listen(PORT, () => {
      console.log(`Consumer service is running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start consumer service:', error);
    process.exit(1);
  }
};

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM signal received: closing HTTP server');
  await disconnectKafkaConsumer();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('SIGINT signal received: closing HTTP server');
  await disconnectKafkaConsumer();
  process.exit(0);
});

startServer();

