import { IItemRepository } from '../../domain/interfaces/item.repository.interface';
import { ItemEntity } from '../../domain/entities/item.entity';

/**
 * Use case: Get all items
 */
export class GetAllItemsUseCase {
  constructor(private readonly itemRepository: IItemRepository) {}

  async execute(): Promise<ItemEntity[]> {
    return await this.itemRepository.findAll();
  }
}

