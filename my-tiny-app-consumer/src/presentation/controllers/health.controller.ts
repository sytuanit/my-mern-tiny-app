import { Request, Response } from 'express';
import mongoose from 'mongoose';

/**
 * Health check controller
 * Returns status of service, database, and external API
 */
export const healthCheck = async (_req: Request, res: Response): Promise<void> => {
  const health = {
    status: 'ok',
    service: 'my-tiny-app-consumer',
    timestamp: new Date().toISOString(),
    checks: {
      database: 'unknown',
      externalApi: 'unknown',
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

  // Check external API availability
  try {
    const apiUrl = process.env.MY_TINY_APP_API_URL || 'http://app:3000';
    const healthEndpoint = `${apiUrl}/health`;

    const response = await fetch(healthEndpoint, {
      method: 'GET',
      signal: AbortSignal.timeout(5000), // 5 second timeout
    });

    if (response.ok) {
      health.checks.externalApi = 'available';
    } else {
      health.checks.externalApi = 'unavailable';
      health.status = 'degraded';
    }
  } catch (error) {
    health.checks.externalApi = 'error';
    health.status = 'degraded';
  }

  const statusCode = health.status === 'ok' ? 200 : 503;
  res.status(statusCode).json(health);
};

