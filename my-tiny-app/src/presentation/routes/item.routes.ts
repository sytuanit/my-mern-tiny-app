import { Router } from 'express';
import {
  getAllItems,
  getItemById,
  getItemByName,
  createItem,
  updateItem,
  deleteItem,
} from '../controllers/item.controller';

export const itemRouter = Router();

/**
 * @route GET /api/items
 * @desc Get all items
 * @access Public
 */
itemRouter.get('/', getAllItems);

/**
 * @route POST /api/items/search
 * @desc Search item by name (first match only)
 * @access Public
 * @body { name: string }
 * @note Must be defined before POST / to avoid route conflict
 */
itemRouter.post('/search', getItemByName);

/**
 * @route POST /api/items
 * @desc Create new item
 * @access Public
 * @note Must be defined after /search route
 */
itemRouter.post('/', createItem);

/**
 * @route GET /api/items/:id
 * @desc Get item by ID
 * @access Public
 */
itemRouter.get('/:id', getItemById);

/**
 * @route PUT /api/items/:id
 * @desc Update item by ID
 * @access Public
 */
itemRouter.put('/:id', updateItem);

/**
 * @route DELETE /api/items/:id
 * @desc Delete item by ID
 * @access Public
 */
itemRouter.delete('/:id', deleteItem);

