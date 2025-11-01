import mongoose from 'mongoose';
import { Item, IItem, itemSchemaZod } from '../models/item.model';

/**
 * Get all items sorted by creation date (newest first)
 * @returns Array of all items
 */
export async function getAllItems(): Promise<IItem[]> {
  return await Item.find().sort({ createdAt: -1 });
}

/**
 * Get item by name (first match only)
 * @param name - Item name to search
 * @returns Item if found, null otherwise
 */
export async function getItemByName(name: string): Promise<IItem | null> {
  return await Item.findOne({ name }).sort({ createdAt: -1 });
}

/**
 * Get item by ID
 * @param id - MongoDB ObjectId string
 * @returns Item if found, null otherwise
 * @throws {Error} If ID format is invalid
 */
export async function getItemById(id: string): Promise<IItem | null> {
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new Error('Invalid item ID format');
  }

  return await Item.findById(id);
}

/**
 * Create a new item
 * @param itemData - Item data to create
 * @returns Created item
 * @throws {Error} If validation fails
 */
export async function createItem(itemData: unknown): Promise<IItem> {
  const validationResult = itemSchemaZod.safeParse(itemData);

  if (!validationResult.success) {
    const errorMessages = validationResult.error.errors.map((e) => `${e.path.join('.')}: ${e.message}`).join('; ');
    throw new Error(`Validation error: ${errorMessages}`);
  }

  const validatedData = validationResult.data;
  const newItem = new Item(validatedData);
  return await newItem.save();
}

/**
 * Update an existing item by ID
 * @param id - MongoDB ObjectId string
 * @param updateData - Partial item data to update
 * @returns Updated item if found, null otherwise
 * @throws {Error} If ID format is invalid or validation fails
 */
export async function updateItem(
  id: string,
  updateData: unknown
): Promise<IItem | null> {
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new Error('Invalid item ID format');
  }

  const validationResult = itemSchemaZod.partial().safeParse(updateData);

  if (!validationResult.success) {
    const errorMessages = validationResult.error.errors.map((e) => `${e.path.join('.')}: ${e.message}`).join('; ');
    throw new Error(`Validation error: ${errorMessages}`);
  }

  const validatedData = validationResult.data;
  return await Item.findByIdAndUpdate(id, validatedData, {
    new: true,
    runValidators: true,
  });
}

/**
 * Delete an item by ID
 * @param id - MongoDB ObjectId string
 * @returns Deleted item if found, null otherwise
 * @throws {Error} If ID format is invalid
 */
export async function deleteItem(id: string): Promise<IItem | null> {
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new Error('Invalid item ID format');
  }

  return await Item.findByIdAndDelete(id);
}

