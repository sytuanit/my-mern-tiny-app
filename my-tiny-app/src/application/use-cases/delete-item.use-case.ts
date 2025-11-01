import { IItemRepository } from '../../domain/interfaces/item.repository.interface';
import { IEventPublisher } from '../../domain/interfaces/event-publisher.interface';
import { ItemEntity } from '../../domain/entities/item.entity';

/**
 * Use case: Delete item
 */
export class DeleteItemUseCase {
  constructor(
    private readonly itemRepository: IItemRepository,
    private readonly eventPublisher: IEventPublisher
  ) {}

  async execute(id: string): Promise<ItemEntity> {
    // Delete item
    const deletedItem = await this.itemRepository.delete(id);

    if (!deletedItem) {
      throw new Error('Item not found');
    }

    // Publish event (non-blocking)
    await this.eventPublisher.publishItemDeleted(deletedItem.id, {
      name: deletedItem.name,
      description: deletedItem.description,
      price: deletedItem.price,
      quantity: deletedItem.quantity,
    });

    return deletedItem;
  }
}

