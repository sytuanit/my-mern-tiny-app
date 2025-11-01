import { z } from 'zod';

/**
 * Request DTOs for validation
 */
export const createItemRequestSchema = z.object({
  name: z.string().min(1, 'Name is required').max(100, 'Name must be less than 100 characters'),
  description: z.string().max(500, 'Description must be less than 500 characters').optional(),
  price: z.number().positive('Price must be a positive number').optional(),
  quantity: z.number().int().nonnegative('Quantity must be a non-negative integer').optional(),
});

export const updateItemRequestSchema = createItemRequestSchema.partial();

export const searchItemRequestSchema = z.object({
  name: z.string().min(1, 'Name is required'),
});

export type CreateItemRequestDto = z.infer<typeof createItemRequestSchema>;
export type UpdateItemRequestDto = z.infer<typeof updateItemRequestSchema>;
export type SearchItemRequestDto = z.infer<typeof searchItemRequestSchema>;

/**
 * Response DTOs
 */
export interface ItemResponseDto {
  id: string;
  name: string;
  description?: string;
  price?: number;
  quantity?: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface ApiResponseDto<T> {
  success: boolean;
  message?: string;
  data?: T;
  count?: number;
  error?: string;
}

