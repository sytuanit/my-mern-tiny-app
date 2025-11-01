import { IItemRepository } from '../../domain/interfaces/item.repository.interface';
import { IEventPublisher } from '../../domain/interfaces/event-publisher.interface';
import { ItemEntity, CreateItemInput } from '../../domain/entities/item.entity';

/**
 * Use case: Create item
 */
export class CreateItemUseCase {
  constructor(
    private readonly itemRepository: IItemRepository,
    private readonly eventPublisher: IEventPublisher
  ) {}

  async execute(itemData: CreateItemInput): Promise<ItemEntity> {
    // Create item
    const createdItem = await this.itemRepository.create(itemData);

    // Publish event (non-blocking)
    await this.eventPublisher.publishItemCreated(createdItem.id, {
      name: createdItem.name,
      description: createdItem.description,
      price: createdItem.price,
      quantity: createdItem.quantity,
    });

    return createdItem;
  }
}

