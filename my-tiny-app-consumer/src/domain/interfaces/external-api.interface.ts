import { ItemFromApiEntity } from '../entities/consumed-item.entity';

/**
 * External API interface - defines contract for calling external services
 * Implementation will be in infrastructure layer
 */
export interface IExternalApiService {
  /**
   * Search item by name from external API (my-tiny-app)
   */
  searchItemByName(name: string): Promise<ItemFromApiEntity | null>;
}

