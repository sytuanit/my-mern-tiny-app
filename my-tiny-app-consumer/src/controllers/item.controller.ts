import { Request, Response } from 'express';
import { ConsumedItem } from '../models/consumed-item.model';
import { searchItemFromApi } from '../services/item-api.service';

/**
 * Compare two items by their fields (name, description, price, quantity)
 * @param consumedItem - Item from consumer database
 * @param apiItem - Item from my-tiny-app API
 * @returns true if all fields match, false otherwise
 */
function compareItems(
  consumedItem: {
    name: string;
    description?: string;
    price?: number;
    quantity?: number;
  },
  apiItem: {
    name: string;
    description?: string;
    price?: number;
    quantity?: number;
  }
): boolean {
  // Compare name (required field)
  if (consumedItem.name !== apiItem.name) {
    return false;
  }

  // Compare description (optional field)
  const consumedDescription = consumedItem.description?.trim() || '';
  const apiDescription = apiItem.description?.trim() || '';
  if (consumedDescription !== apiDescription) {
    return false;
  }

  // Compare price (optional field)
  const consumedPrice = consumedItem.price ?? null;
  const apiPrice = apiItem.price ?? null;
  if (consumedPrice !== apiPrice) {
    return false;
  }

  // Compare quantity (optional field)
  const consumedQuantity = consumedItem.quantity ?? null;
  const apiQuantity = apiItem.quantity ?? null;
  if (consumedQuantity !== apiQuantity) {
    return false;
  }

  return true;
}

/**
 * Search item by name:
 * 1. Find in consumer DB
 * 2. Call my-tiny-app API
 * 3. Compare fields
 * 4. Return result
 */
export const searchItemByName = async (req: Request, res: Response): Promise<void> => {
  try {
    const { name } = req.body;

    if (!name || typeof name !== 'string') {
      res.status(400).json({
        success: false,
        message: 'Name field is required in request body',
      });
      return;
    }

    // Step 1: Find item in consumer database (first match only)
    const consumedItem = await ConsumedItem.findOne({ name }).sort({ createdAt: -1 });

    if (!consumedItem) {
      res.status(404).json({
        success: false,
        message: 'Item not found in consumer database',
      });
      return;
    }

    // Step 2: Call my-tiny-app API
    let apiItem;
    try {
      apiItem = await searchItemFromApi(name);
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error calling my-tiny-app API',
        error: error instanceof Error ? error.message : 'Unknown error',
      });
      return;
    }

    if (!apiItem) {
      res.status(404).json({
        success: false,
        message: 'Item not found in my-tiny-app database',
      });
      return;
    }

    // Step 3: Compare fields
    const fieldsMatch = compareItems(
      {
        name: consumedItem.name,
        description: consumedItem.description,
        price: consumedItem.price,
        quantity: consumedItem.quantity,
      },
      {
        name: apiItem.name,
        description: apiItem.description,
        price: apiItem.price,
        quantity: apiItem.quantity,
      }
    );

    if (!fieldsMatch) {
      res.status(404).json({
        success: false,
        message: 'Item information does not match between consumer database and my-tiny-app database',
        details: {
          consumedItem: {
            name: consumedItem.name,
            description: consumedItem.description,
            price: consumedItem.price,
            quantity: consumedItem.quantity,
          },
          apiItem: {
            name: apiItem.name,
            description: apiItem.description,
            price: apiItem.price,
            quantity: apiItem.quantity,
          },
        },
      });
      return;
    }

    // Step 4: Return item if all fields match
    res.status(200).json({
      success: true,
      message: 'Item found and fields match',
      data: {
        name: consumedItem.name,
        description: consumedItem.description,
        price: consumedItem.price,
        quantity: consumedItem.quantity,
        originalItemId: consumedItem.originalItemId,
        lastSyncedAt: consumedItem.lastSyncedAt,
        createdAt: consumedItem.createdAt,
        updatedAt: consumedItem.updatedAt,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error searching item',
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }
};

