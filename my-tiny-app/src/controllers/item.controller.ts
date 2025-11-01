import { Request, Response } from 'express';
import { Item, ItemInput, itemSchemaZod } from '../models/item.model';
import { publishItemEvent } from '../config/kafka';

/**
 * Get all items
 */
export const getAllItems = async (_req: Request, res: Response): Promise<void> => {
  try {
    const items = await Item.find().sort({ createdAt: -1 });
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
 * Get item by name (first match only)
 */
export const getItemByName = async (req: Request, res: Response): Promise<void> => {
  try {
    const { name } = req.query;

    if (!name || typeof name !== 'string') {
      res.status(400).json({
        success: false,
        message: 'Name parameter is required',
      });
      return;
    }

    const item = await Item.findOne({ name }).sort({ createdAt: -1 });

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
      message: 'Error fetching item by name',
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
    const item = await Item.findById(id);

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
    const validationResult = itemSchemaZod.safeParse(req.body);

    if (!validationResult.success) {
      res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: validationResult.error.errors,
      });
      return;
    }

    const itemData: ItemInput = validationResult.data;
    const newItem = new Item(itemData);
    const savedItem = await newItem.save();

    // Publish item created event
    try {
      await publishItemEvent({
        eventType: 'ITEM_CREATED',
        itemId: String(savedItem._id),
        data: savedItem.toObject() as unknown as Record<string, unknown>,
        timestamp: new Date().toISOString(),
      });
    } catch (kafkaError) {
      console.error('Failed to publish ITEM_CREATED event:', kafkaError);
      // Continue even if Kafka publish fails
    }

    res.status(201).json({
      success: true,
      message: 'Item created successfully',
      data: savedItem,
    });
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
    const validationResult = itemSchemaZod.partial().safeParse(req.body);

    if (!validationResult.success) {
      res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: validationResult.error.errors,
      });
      return;
    }

    const updateData = validationResult.data;
    const updatedItem = await Item.findByIdAndUpdate(id, updateData, {
      new: true,
      runValidators: true,
    });

    if (!updatedItem) {
      res.status(404).json({
        success: false,
        message: 'Item not found',
      });
      return;
    }

    // Publish item updated event
    try {
      await publishItemEvent({
        eventType: 'ITEM_UPDATED',
        itemId: String(updatedItem._id),
        data: updatedItem.toObject() as unknown as Record<string, unknown>,
        timestamp: new Date().toISOString(),
      });
    } catch (kafkaError) {
      console.error('Failed to publish ITEM_UPDATED event:', kafkaError);
      // Continue even if Kafka publish fails
    }

    res.status(200).json({
      success: true,
      message: 'Item updated successfully',
      data: updatedItem,
    });
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
    const deletedItem = await Item.findByIdAndDelete(id);

    if (!deletedItem) {
      res.status(404).json({
        success: false,
        message: 'Item not found',
      });
      return;
    }

    // Publish item deleted event
    try {
      await publishItemEvent({
        eventType: 'ITEM_DELETED',
        itemId: String(deletedItem._id),
        data: deletedItem.toObject() as unknown as Record<string, unknown>,
        timestamp: new Date().toISOString(),
      });
    } catch (kafkaError) {
      console.error('Failed to publish ITEM_DELETED event:', kafkaError);
      // Continue even if Kafka publish fails
    }

    res.status(200).json({
      success: true,
      message: 'Item deleted successfully',
      data: deletedItem,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error deleting item',
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }
};

