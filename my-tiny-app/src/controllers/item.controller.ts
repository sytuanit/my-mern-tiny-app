import { Request, Response } from 'express';
import * as itemService from '../services/item.service';
import {
  publishItemCreatedEvent,
  publishItemUpdatedEvent,
  publishItemDeletedEvent,
} from '../services/kafka-event.service';

/**
 * Get all items
 */
export const getAllItems = async (_req: Request, res: Response): Promise<void> => {
  try {
    const items = await itemService.getAllItems();
    res.status(200).json({
      success: true,
      count: items.length,
      data: items,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching items',
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }
};

/**
 * Search item by name (first match only)
 */
export const getItemByName = async (req: Request, res: Response): Promise<void> => {
  try {
    const { name } = req.body;

    if (!name || typeof name !== 'string') {
      res.status(400).json({
        success: false,
        message: 'Name field is required in request body',
      });
      return;
    }

    const item = await itemService.getItemByName(name);

    if (!item) {
      res.status(404).json({
        success: false,
        message: 'Item not found',
      });
      return;
    }

    res.status(200).json({
      success: true,
      data: item,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error searching item by name',
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }
};

/**
 * Get item by ID
 */
export const getItemById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    try {
      const item = await itemService.getItemById(id);

      if (!item) {
        res.status(404).json({
          success: false,
          message: 'Item not found',
        });
        return;
      }

      res.status(200).json({
        success: true,
        data: item,
      });
    } catch (error) {
      if (error instanceof Error && error.message === 'Invalid item ID format') {
        res.status(400).json({
          success: false,
          message: 'Invalid item ID format',
        });
        return;
      }
      throw error;
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching item',
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }
};

/**
 * Create new item
 */
export const createItem = async (req: Request, res: Response): Promise<void> => {
  try {
    try {
      const savedItem = await itemService.createItem(req.body);

      // Publish item created event (non-blocking)
      await publishItemCreatedEvent(String(savedItem._id), savedItem.toObject() as unknown as Record<string, unknown>);

      res.status(201).json({
        success: true,
        message: 'Item created successfully',
        data: savedItem,
      });
    } catch (error) {
      if (error instanceof Error && error.message.includes('Validation error')) {
        res.status(400).json({
          success: false,
          message: 'Validation error',
          error: error.message,
        });
        return;
      }
      throw error;
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error creating item',
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }
};

/**
 * Update item by ID
 */
export const updateItem = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    try {
      const updatedItem = await itemService.updateItem(id, req.body);

      if (!updatedItem) {
        res.status(404).json({
          success: false,
          message: 'Item not found',
        });
        return;
      }

      // Publish item updated event (non-blocking)
      await publishItemUpdatedEvent(String(updatedItem._id), updatedItem.toObject() as unknown as Record<string, unknown>);

      res.status(200).json({
        success: true,
        message: 'Item updated successfully',
        data: updatedItem,
      });
    } catch (error) {
      if (error instanceof Error && error.message === 'Invalid item ID format') {
        res.status(400).json({
          success: false,
          message: 'Invalid item ID format',
        });
        return;
      }
      if (error instanceof Error && error.message.includes('Validation error')) {
        res.status(400).json({
          success: false,
          message: 'Validation error',
          error: error.message,
        });
        return;
      }
      throw error;
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating item',
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }
};

/**
 * Delete item by ID
 */
export const deleteItem = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    try {
      const deletedItem = await itemService.deleteItem(id);

      if (!deletedItem) {
        res.status(404).json({
          success: false,
          message: 'Item not found',
        });
        return;
      }

      // Publish item deleted event (non-blocking)
      await publishItemDeletedEvent(String(deletedItem._id), deletedItem.toObject() as unknown as Record<string, unknown>);

      res.status(200).json({
        success: true,
        message: 'Item deleted successfully',
        data: deletedItem,
      });
    } catch (error) {
      if (error instanceof Error && error.message === 'Invalid item ID format') {
        res.status(400).json({
          success: false,
          message: 'Invalid item ID format',
        });
        return;
      }
      throw error;
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error deleting item',
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }
};
