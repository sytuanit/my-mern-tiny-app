/**
 * Dependency Injection Container
 * Instantiates and wires up all dependencies
 */
import { ItemRepository } from '../repositories/item.repository';
import { KafkaEventPublisher } from '../messaging/kafka-event-publisher';
import { GetAllItemsUseCase } from '../../application/use-cases/get-all-items.use-case';
import { GetItemByIdUseCase } from '../../application/use-cases/get-item-by-id.use-case';
import { GetItemByNameUseCase } from '../../application/use-cases/get-item-by-name.use-case';
import { CreateItemUseCase } from '../../application/use-cases/create-item.use-case';
import { UpdateItemUseCase } from '../../application/use-cases/update-item.use-case';
import { DeleteItemUseCase } from '../../application/use-cases/delete-item.use-case';

/**
 * Dependency Injection Container
 */
export class DIContainer {
  // Infrastructure layer
  private readonly itemRepository: ItemRepository;
  private readonly eventPublisher: KafkaEventPublisher;

  // Application layer (use cases)
  public readonly getAllItemsUseCase: GetAllItemsUseCase;
  public readonly getItemByIdUseCase: GetItemByIdUseCase;
  public readonly getItemByNameUseCase: GetItemByNameUseCase;
  public readonly createItemUseCase: CreateItemUseCase;
  public readonly updateItemUseCase: UpdateItemUseCase;
  public readonly deleteItemUseCase: DeleteItemUseCase;

  constructor() {
    // Initialize infrastructure
    this.itemRepository = new ItemRepository();
    this.eventPublisher = new KafkaEventPublisher();

    // Initialize use cases with dependencies
    this.getAllItemsUseCase = new GetAllItemsUseCase(this.itemRepository);
    this.getItemByIdUseCase = new GetItemByIdUseCase(this.itemRepository);
    this.getItemByNameUseCase = new GetItemByNameUseCase(this.itemRepository);
    this.createItemUseCase = new CreateItemUseCase(this.itemRepository, this.eventPublisher);
    this.updateItemUseCase = new UpdateItemUseCase(this.itemRepository, this.eventPublisher);
    this.deleteItemUseCase = new DeleteItemUseCase(this.itemRepository, this.eventPublisher);
  }
}

