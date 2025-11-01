/**
 * Domain Entity - Pure business logic, no framework dependencies
 */

export interface ItemEntity {
  id: string;
  name: string;
  description?: string;
  price?: number;
  quantity?: number;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Create item input (business rules)
 */
export interface CreateItemInput {
  name: string;
  description?: string;
  price?: number;
  quantity?: number;
}

/**
 * Update item input (business rules)
 */
export interface UpdateItemInput {
  name?: string;
  description?: string;
  price?: number;
  quantity?: number;
}

