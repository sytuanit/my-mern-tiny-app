import { Request, Response } from 'express';
import mongoose from 'mongoose';
import { Kafka } from 'kafkajs';

/**
 * Health check controller
 * Returns status of service, database, and Kafka
 */
export const healthCheck = async (_req: Request, res: Response): Promise<void> => {
  const health = {
    status: 'ok',
    service: 'my-tiny-app',
    timestamp: new Date().toISOString(),
    checks: {
      database: 'unknown',
      kafka: 'unknown',
    },
  };

  // Check database connection
  try {
    if (mongoose.connection.readyState === 1) {
      health.checks.database = 'connected';
    } else {
      health.checks.database = 'disconnected';
      health.status = 'degraded';
    }
  } catch (error) {
    health.checks.database = 'error';
    health.status = 'degraded';
  }

  // Check Kafka connection
  try {
    const kafkaBroker = process.env.KAFKA_BROKER || 'localhost:9092';
    const kafka = new Kafka({
      clientId: 'health-check-client',
      brokers: [kafkaBroker],
    });

    const admin = kafka.admin();
    await admin.connect();

    // Try to list topics (lightweight operation)
    await admin.listTopics();

    await admin.disconnect();
    health.checks.kafka = 'connected';
  } catch (error) {
    health.checks.kafka = 'error';
    health.status = 'degraded';
  }

  const statusCode = health.status === 'ok' ? 200 : 503;
  res.status(statusCode).json(health);
};

