import { IEventPublisher } from '../../domain/interfaces/event-publisher.interface';
import { publishItemEvent } from '../../config/kafka';

/**
 * Kafka implementation of EventPublisher
 */
export class KafkaEventPublisher implements IEventPublisher {
  async publishItemCreated(itemId: string, itemData: Record<string, unknown>): Promise<void> {
    try {
      await publishItemEvent({
        eventType: 'ITEM_CREATED',
        itemId,
        data: itemData,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      console.error('Failed to publish ITEM_CREATED event:', error);
      // Don't throw - continue even if Kafka fails
    }
  }

  async publishItemUpdated(itemId: string, itemData: Record<string, unknown>): Promise<void> {
    try {
      await publishItemEvent({
        eventType: 'ITEM_UPDATED',
        itemId,
        data: itemData,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      console.error('Failed to publish ITEM_UPDATED event:', error);
      // Don't throw - continue even if Kafka fails
    }
  }

  async publishItemDeleted(itemId: string, itemData: Record<string, unknown>): Promise<void> {
    try {
      await publishItemEvent({
        eventType: 'ITEM_DELETED',
        itemId,
        data: itemData,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      console.error('Failed to publish ITEM_DELETED event:', error);
      // Don't throw - continue even if Kafka fails
    }
  }
}

