import { ItemFromApiEntity } from '../entities/consumed-item.entity';

/**
 * Domain service for comparing items
 * Pure business logic - no dependencies
 */
export class ItemComparisonService {
  /**
   * Compare two items by their fields (name, description, price, quantity)
   * @param consumedItem - Item from consumer database
   * @param apiItem - Item from external API
   * @returns true if all fields match, false otherwise
   */
  compareItems(
    consumedItem: {
      name: string;
      description?: string;
      price?: number;
      quantity?: number;
    },
    apiItem: ItemFromApiEntity
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
}

