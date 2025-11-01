import express, { Application } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { connectDatabase } from './config/database';
import { initializeKafkaProducer, disconnectKafkaProducer } from './config/kafka';
import { itemRouter } from './routes/item.routes';

dotenv.config();

const app: Application = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/items', itemRouter);

// Health check endpoint
app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', message: 'Server is running' });
});

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

