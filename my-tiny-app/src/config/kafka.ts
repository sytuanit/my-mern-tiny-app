import { Kafka, Producer } from 'kafkajs';
import { z } from 'zod';

/**
 * Zod schema for item event payload
 */
export const itemEventSchemaZod = z.object({
  eventType: z.enum(['ITEM_CREATED', 'ITEM_UPDATED', 'ITEM_DELETED']),
  itemId: z.string(),
  data: z.record(z.unknown()).optional(),
  timestamp: z.string(),
});

export type ItemEvent = z.infer<typeof itemEventSchemaZod>;

/**
 * Kafka client configuration
 */
const kafka = new Kafka({
  clientId: 'my-tiny-app-producer',
  brokers: [process.env.KAFKA_BROKER || 'localhost:9092'],
});

let producer: Producer | null = null;

/**
 * Initializes Kafka producer
 * @throws {Error} If initialization fails
 */
export const initializeKafkaProducer = async (): Promise<void> => {
  try {
    producer = kafka.producer();
    await producer.connect();
    console.log('Kafka producer connected successfully');
  } catch (error) {
    console.error('Kafka producer connection error:', error);
    throw error;
  }
};

/**
 * Publishes an item event to Kafka topic
 * @param event - The item event to publish
 * @throws {Error} If publishing fails
 */
export const publishItemEvent = async (event: ItemEvent): Promise<void> => {
  if (!producer) {
    throw new Error('Kafka producer not initialized');
  }

  try {
    const validationResult = itemEventSchemaZod.safeParse(event);
    if (!validationResult.success) {
      throw new Error(`Invalid event format: ${validationResult.error.message}`);
    }

    const topic = process.env.KAFKA_TOPIC || 'item-events';
    await producer.send({
      topic,
      messages: [
        {
          key: event.itemId,
          value: JSON.stringify(event),
        },
      ],
    });

    console.log(`Item event published: ${event.eventType} for item ${event.itemId}`);
  } catch (error) {
    console.error('Error publishing item event:', error);
    throw error;
  }
};

/**
 * Disconnects Kafka producer
 */
export const disconnectKafkaProducer = async (): Promise<void> => {
  if (producer) {
    await producer.disconnect();
    producer = null;
    console.log('Kafka producer disconnected');
  }
};

