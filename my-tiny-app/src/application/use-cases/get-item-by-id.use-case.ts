import { IItemRepository } from '../../domain/interfaces/item.repository.interface';
import { ItemEntity } from '../../domain/entities/item.entity';

/**
 * Use case: Get item by ID
 */
export class GetItemByIdUseCase {
  constructor(private readonly itemRepository: IItemRepository) {}

  async execute(id: string): Promise<ItemEntity> {
    const item = await this.itemRepository.findById(id);

    if (!item) {
      throw new Error('Item not found');
    }

    return item;
  }
}

