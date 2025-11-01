import { ItemEntity, CreateItemInput, UpdateItemInput } from '../entities/item.entity';

/**
 * Repository interface - defines data access contract
 * Implementation will be in infrastructure layer
 */
export interface IItemRepository {
  /**
   * Find all items, sorted by creation date (newest first)
   */
  findAll(): Promise<ItemEntity[]>;

  /**
   * Find item by ID
   */
  findById(id: string): Promise<ItemEntity | null>;

  /**
   * Find item by name (first match only)
   */
  findByName(name: string): Promise<ItemEntity | null>;

  /**
   * Create a new item
   */
  create(itemData: CreateItemInput): Promise<ItemEntity>;

  /**
   * Update an existing item
   */
  update(id: string, updateData: UpdateItemInput): Promise<ItemEntity | null>;

  /**
   * Delete an item
   */
  delete(id: string): Promise<ItemEntity | null>;
}

