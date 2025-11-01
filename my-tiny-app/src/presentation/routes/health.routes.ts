import { Router } from 'express';
import { healthCheck } from '../controllers/health.controller';

export const healthRouter = Router();

/**
 * @route GET /health
 * @desc Health check endpoint
 * @access Public
 */
healthRouter.get('/', healthCheck);

