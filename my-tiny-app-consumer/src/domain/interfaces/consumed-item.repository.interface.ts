import { ConsumedItemEntity } from '../entities/consumed-item.entity';

/**
 * Repository interface - defines data access contract
 * Implementation will be in infrastructure layer
 */
export interface IConsumedItemRepository {
  /**
   * Find item by name (first match only)
   */
  findByName(name: string): Promise<ConsumedItemEntity | null>;
}

