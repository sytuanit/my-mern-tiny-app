import { publishItemEvent } from '../config/kafka';

/**
 * Publish ITEM_CREATED event to Kafka
 * @param itemId - Item ID
 * @param itemData - Item data
 */
export async function publishItemCreatedEvent(
  itemId: string,
  itemData: Record<string, unknown>
): Promise<void> {
  try {
    await publishItemEvent({
      eventType: 'ITEM_CREATED',
      itemId,
      data: itemData,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Failed to publish ITEM_CREATED event:', error);
    // Continue even if Kafka publish fails - don't throw
  }
}

/**
 * Publish ITEM_UPDATED event to Kafka
 * @param itemId - Item ID
 * @param itemData - Updated item data
 */
export async function publishItemUpdatedEvent(
  itemId: string,
  itemData: Record<string, unknown>
): Promise<void> {
  try {
    await publishItemEvent({
      eventType: 'ITEM_UPDATED',
      itemId,
      data: itemData,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Failed to publish ITEM_UPDATED event:', error);
    // Continue even if Kafka publish fails - don't throw
  }
}

/**
 * Publish ITEM_DELETED event to Kafka
 * @param itemId - Item ID
 * @param itemData - Deleted item data
 */
export async function publishItemDeletedEvent(
  itemId: string,
  itemData: Record<string, unknown>
): Promise<void> {
  try {
    await publishItemEvent({
      eventType: 'ITEM_DELETED',
      itemId,
      data: itemData,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Failed to publish ITEM_DELETED event:', error);
    // Continue even if Kafka publish fails - don't throw
  }
}

