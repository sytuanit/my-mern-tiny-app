/**
 * Domain Entity - Pure business logic, no framework dependencies
 */

export interface ConsumedItemEntity {
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

export interface ItemFromApiEntity {
  name: string;
  description?: string;
  price?: number;
  quantity?: number;
}

