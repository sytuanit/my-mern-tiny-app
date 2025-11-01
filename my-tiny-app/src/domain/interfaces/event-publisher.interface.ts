/**
 * Event publisher interface - defines messaging contract
 * Implementation will be in infrastructure layer
 */
export interface IEventPublisher {
  /**
   * Publish ITEM_CREATED event
   */
  publishItemCreated(itemId: string, itemData: Record<string, unknown>): Promise<void>;

  /**
   * Publish ITEM_UPDATED event
   */
  publishItemUpdated(itemId: string, itemData: Record<string, unknown>): Promise<void>;

  /**
   * Publish ITEM_DELETED event
   */
  publishItemDeleted(itemId: string, itemData: Record<string, unknown>): Promise<void>;
}

