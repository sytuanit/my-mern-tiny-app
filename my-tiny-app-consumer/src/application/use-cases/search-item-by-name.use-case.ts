import { IConsumedItemRepository } from '../../domain/interfaces/consumed-item.repository.interface';
import { IExternalApiService } from '../../domain/interfaces/external-api.interface';
import { ItemComparisonService } from '../../domain/services/item-comparison.service';
import { ConsumedItemEntity } from '../../domain/entities/consumed-item.entity';

export interface SearchItemResult {
  success: boolean;
  item?: ConsumedItemEntity;
  error?: string;
  details?: {
    consumedItem: {
      name: string;
      description?: string;
      price?: number;
      quantity?: number;
    };
    apiItem: {
      name: string;
      description?: string;
      price?: number;
      quantity?: number;
    };
  };
}

/**
 * Use case: Search item by name
 * 1. Find in consumer DB
 * 2. Call my-tiny-app API
 * 3. Compare fields
 * 4. Return result
 */
export class SearchItemByNameUseCase {
  private readonly comparisonService: ItemComparisonService;

  constructor(
    private readonly consumedItemRepository: IConsumedItemRepository,
    private readonly externalApiService: IExternalApiService
  ) {
    this.comparisonService = new ItemComparisonService();
  }

  async execute(name: string): Promise<SearchItemResult> {
    // Step 1: Find item in consumer database
    const consumedItem = await this.consumedItemRepository.findByName(name);

    if (!consumedItem) {
      return {
        success: false,
        error: 'Item not found in consumer database',
      };
    }

    // Step 2: Call my-tiny-app API
    let apiItem;
    try {
      apiItem = await this.externalApiService.searchItemByName(name);
    } catch (error) {
      return {
        success: false,
        error: `Error calling my-tiny-app API: ${error instanceof Error ? error.message : 'Unknown error'}`,
      };
    }

    if (!apiItem) {
      return {
        success: false,
        error: 'Item not found in my-tiny-app database',
      };
    }

    // Step 3: Compare fields
    const fieldsMatch = this.comparisonService.compareItems(
      {
        name: consumedItem.name,
        description: consumedItem.description,
        price: consumedItem.price,
        quantity: consumedItem.quantity,
      },
      apiItem
    );

    if (!fieldsMatch) {
      return {
        success: false,
        error: 'Item information does not match between consumer database and my-tiny-app database',
        details: {
          consumedItem: {
            name: consumedItem.name,
            description: consumedItem.description,
            price: consumedItem.price,
            quantity: consumedItem.quantity,
          },
          apiItem: {
            name: apiItem.name,
            description: apiItem.description,
            price: apiItem.price,
            quantity: apiItem.quantity,
          },
        },
      };
    }

    // Step 4: Return item if all fields match
    return {
      success: true,
      item: consumedItem,
    };
  }
}

