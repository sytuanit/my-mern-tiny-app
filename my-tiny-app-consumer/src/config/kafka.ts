import { Kafka, Consumer, EachMessagePayload } from 'kafkajs';
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
  clientId: 'my-tiny-app-consumer',
  brokers: [process.env.KAFKA_BROKER || 'localhost:9092'],
});

let consumer: Consumer | null = null;

/**
 * Initializes Kafka consumer
 * @throws {Error} If initialization fails
 */
export const initializeKafkaConsumer = async (
  onMessage: (event: ItemEvent) => Promise<void>
): Promise<void> => {
  try {
    const groupId = process.env.KAFKA_GROUP_ID || 'my-tiny-app-consumer-group';
    consumer = kafka.consumer({ groupId });
    await consumer.connect();
    console.log('Kafka consumer connected successfully');

    const topic = process.env.KAFKA_TOPIC || 'item-events';
    await consumer.subscribe({ topic, fromBeginning: false });
    console.log(`Subscribed to topic: ${topic}`);

    await consumer.run({
      eachMessage: async (payload: EachMessagePayload) => {
        try {
          const message = payload.message.value?.toString();
          if (!message) {
            console.warn('Received empty message');
            return;
          }

          const eventData = JSON.parse(message);
          const validationResult = itemEventSchemaZod.safeParse(eventData);

          if (!validationResult.success) {
            console.error('Invalid event format:', validationResult.error);
            return;
          }

          const event = validationResult.data;
          console.log(`Received event: ${event.eventType} for item ${event.itemId}`);

          await onMessage(event);
        } catch (error) {
          console.error('Error processing message:', error);
        }
      },
    });
  } catch (error) {
    console.error('Kafka consumer connection error:', error);
    throw error;
  }
};

/**
 * Disconnects Kafka consumer
 */
export const disconnectKafkaConsumer = async (): Promise<void> => {
  if (consumer) {
    await consumer.disconnect();
    consumer = null;
    console.log('Kafka consumer disconnected');
  }
};

