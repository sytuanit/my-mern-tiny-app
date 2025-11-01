import { IConsumedItemRepository } from '../../domain/interfaces/consumed-item.repository.interface';
import { ConsumedItemEntity } from '../../domain/entities/consumed-item.entity';
import { ConsumedItem, IConsumedItem } from '../../models/consumed-item.model';

/**
 * MongoDB implementation of ConsumedItemRepository
 */
export class ConsumedItemRepository implements IConsumedItemRepository {
  /**
   * Map Mongoose document to domain entity
   */
  private toDomainEntity(doc: IConsumedItem): ConsumedItemEntity {
    return {
      id: String(doc._id),
      name: doc.name,
      description: doc.description,
      price: doc.price,
      quantity: doc.quantity,
      originalItemId: doc.originalItemId,
      lastSyncedAt: doc.lastSyncedAt,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  async findByName(name: string): Promise<ConsumedItemEntity | null> {
    const item = await ConsumedItem.findOne({ name }).sort({ createdAt: -1 });
    return item ? this.toDomainEntity(item) : null;
  }
}

