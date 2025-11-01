import mongoose, { Document, Schema } from 'mongoose';
import { z } from 'zod';

/**
 * Zod schema for item validation
 */
export const itemSchemaZod = z.object({
  name: z.string().min(1, 'Name is required').max(100, 'Name must be less than 100 characters'),
  description: z.string().max(500, 'Description must be less than 500 characters').optional(),
  price: z.number().positive('Price must be a positive number').optional(),
  quantity: z.number().int().nonnegative('Quantity must be a non-negative integer').optional(),
});

export type ItemInput = z.infer<typeof itemSchemaZod>;

export interface IItem extends Document {
  name: string;
  description?: string;
  price?: number;
  quantity?: number;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Mongoose schema for Item
 */
const itemSchema = new Schema<IItem>(
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
  },
  {
    timestamps: true,
  }
);

export const Item = mongoose.model<IItem>('Item', itemSchema);

