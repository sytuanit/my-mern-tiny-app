import mongoose, { Document, Schema } from 'mongoose';
import { z } from 'zod';

/**
 * Zod schema for consumed item validation
 */
export const consumedItemSchemaZod = z.object({
  name: z.string().min(1, 'Name is required').max(100, 'Name must be less than 100 characters'),
  description: z.string().max(500, 'Description must be less than 500 characters').optional(),
  price: z.number().positive('Price must be a positive number').optional(),
  quantity: z.number().int().nonnegative('Quantity must be a non-negative integer').optional(),
  originalItemId: z.string(),
  lastSyncedAt: z.union([z.date(), z.string()]).transform((val) => (val instanceof Date ? val : new Date(val))),
});

export type ConsumedItemInput = z.infer<typeof consumedItemSchemaZod>;

export interface IConsumedItem extends Document {
  name: string;
  description?: string;
  price?: number;
  quantity?: number;
  originalItemId: string;
  lastSyncedAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Mongoose schema for ConsumedItem
 */
const consumedItemSchema = new Schema<IConsumedItem>(
  {
    name: {
      type: String,
      required: true,
      trim: true,
      maxlength: 100,
    },
    description: {
      type: String,
      trim: true,
      maxlength: 500,
    },
    price: {
      type: Number,
      min: 0,
    },
    quantity: {
      type: Number,
      min: 0,
      default: 0,
    },
    originalItemId: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    lastSyncedAt: {
      type: Date,
      required: true,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

export const ConsumedItem = mongoose.model<IConsumedItem>('ConsumedItem', consumedItemSchema, 'consumed-items');

