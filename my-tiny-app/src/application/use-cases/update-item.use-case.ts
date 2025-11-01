import { IItemRepository } from '../../domain/interfaces/item.repository.interface';
import { IEventPublisher } from '../../domain/interfaces/event-publisher.interface';
import { ItemEntity, UpdateItemInput } from '../../domain/entities/item.entity';

/**
 * Use case: Update item
 */
export class UpdateItemUseCase {
  constructor(
    private readonly itemRepository: IItemRepository,
    private readonly eventPublisher: IEventPublisher
  ) {}

  async execute(id: string, updateData: UpdateItemInput): Promise<ItemEntity> {
    // Update item
    const updatedItem = await this.itemRepository.update(id, updateData);

    if (!updatedItem) {
      throw new Error('Item not found');
    }

    // Publish event (non-blocking)
    await this.eventPublisher.publishItemUpdated(updatedItem.id, {
      name: updatedItem.name,
      description: updatedItem.description,
      price: updatedItem.price,
      quantity: updatedItem.quantity,
    });

    return updatedItem;
  }
}

