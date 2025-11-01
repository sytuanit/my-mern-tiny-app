/**
 * Dependency Injection Container
 * Instantiates and wires up all dependencies
 */
import { ConsumedItemRepository } from '../repositories/consumed-item.repository';
import { ItemApiService } from '../external-services/item-api.service';
import { SearchItemByNameUseCase } from '../../application/use-cases/search-item-by-name.use-case';

/**
 * Dependency Injection Container
 */
export class DIContainer {
  // Infrastructure layer
  private readonly consumedItemRepository: ConsumedItemRepository;
  private readonly externalApiService: ItemApiService;

  // Application layer (use cases)
  public readonly searchItemByNameUseCase: SearchItemByNameUseCase;

  constructor() {
    // Initialize infrastructure
    this.consumedItemRepository = new ConsumedItemRepository();
    this.externalApiService = new ItemApiService();

    // Initialize use cases with dependencies
    this.searchItemByNameUseCase = new SearchItemByNameUseCase(
      this.consumedItemRepository,
      this.externalApiService
    );
  }
}

