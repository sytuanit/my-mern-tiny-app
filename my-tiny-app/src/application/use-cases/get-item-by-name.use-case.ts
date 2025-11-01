import { IItemRepository } from '../../domain/interfaces/item.repository.interface';
import { ItemEntity } from '../../domain/entities/item.entity';

/**
 * Use case: Get item by name
 */
export class GetItemByNameUseCase {
  constructor(private readonly itemRepository: IItemRepository) {}

  async execute(name: string): Promise<ItemEntity> {
    const item = await this.itemRepository.findByName(name);

    if (!item) {
      throw new Error('Item not found');
    }

    return item;
  }
}

