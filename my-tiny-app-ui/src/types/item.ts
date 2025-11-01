/**
 * Item type matching the API response
 */
export interface Item {
  id?: string;
  name: string;
  description?: string;
  price?: number;
  quantity?: number;
  createdAt?: string;
  updatedAt?: string;
}

/**
 * Item creation/update input
 */
export interface ItemInput {
  name: string;
  description?: string;
  price?: number;
  quantity?: number;
}

/**
 * API Response types
 */
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  count?: number;
  message?: string;
  error?: string;
}

