import { ItemEvent } from '../config/kafka';
import { ConsumedItem } from '../models/consumed-item.model';

/**
 * Handles item events from Kafka
 * @param event - The item event to handle
 */
export const handleItemEvent = async (event: ItemEvent): Promise<void> => {
  try {
    switch (event.eventType) {
      case 'ITEM_CREATED':
      case 'ITEM_UPDATED':
        await handleItemCreatedOrUpdated(event);
        break;
      case 'ITEM_DELETED':
        await handleItemDeleted(event);
        break;
      default:
        console.warn(`Unknown event type: ${event.eventType}`);
    }
  } catch (error) {
    console.error(`Error handling ${event.eventType} event for item ${event.itemId}:`, error);
    throw error;
  }
};

/**
 * Handles ITEM_CREATED or ITEM_UPDATED events
 * Creates or updates the consumed item in MongoDB
 */
const handleItemCreatedOrUpdated = async (event: ItemEvent): Promise<void> => {
  if (!event.data) {
    throw new Error('Event data is missing');
  }

  const itemData = event.data;
  const updateData = {
    name: itemData.name as string,
    description: itemData.description as string | undefined,
    price: itemData.price as number | undefined,
    quantity: itemData.quantity as number | undefined,
    originalItemId: event.itemId,
    lastSyncedAt: new Date(event.timestamp),
  };

  await ConsumedItem.findOneAndUpdate(
    { originalItemId: event.itemId },
    updateData,
    {
      upsert: true,
      new: true,
      runValidators: true,
    }
  );

  console.log(`Synced item ${event.itemId} to consumed-items collection`);
};

/**
 * Handles ITEM_DELETED events
 * Removes the consumed item from MongoDB
 */
const handleItemDeleted = async (event: ItemEvent): Promise<void> => {
  const result = await ConsumedItem.findOneAndDelete({ originalItemId: event.itemId });

  if (result) {
    console.log(`Deleted item ${event.itemId} from consumed-items collection`);
  } else {
    console.warn(`Item ${event.itemId} not found in consumed-items collection`);
  }
};

