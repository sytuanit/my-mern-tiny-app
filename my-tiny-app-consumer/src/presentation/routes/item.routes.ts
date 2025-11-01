import { Router } from 'express';
import { searchItemByName } from '../controllers/item.controller';

export const itemRouter = Router();

/**
 * @route POST /api/items/search
 * @desc Search item by name in consumer DB, compare with my-tiny-app API
 * @access Public
 * @body { name: string }
 */
itemRouter.post('/search', searchItemByName);

