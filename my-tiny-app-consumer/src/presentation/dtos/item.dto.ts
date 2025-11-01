import { z } from 'zod';

/**
 * Request DTOs for validation
 */
export const searchItemRequestSchema = z.object({
  name: z.string().min(1, 'Name is required'),
});

export type SearchItemRequestDto = z.infer<typeof searchItemRequestSchema>;

/**
 * Response DTOs
 */
export interface ConsumedItemResponseDto {
  id: string;
  name: string;
  description?: string;
  price?: number;
  quantity?: number;
  originalItemId: string;
  lastSyncedAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface ApiResponseDto<T> {
  success: boolean;
  message?: string;
  data?: T;
  error?: string;
  details?: Record<string, unknown>;
}

