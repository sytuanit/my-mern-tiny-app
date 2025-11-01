import { IExternalApiService } from '../../domain/interfaces/external-api.interface';
import { ItemFromApiEntity } from '../../domain/entities/consumed-item.entity';

interface ApiResponse {
  success: boolean;
  data?: ItemFromApiEntity;
  message?: string;
  error?: string;
}

/**
 * Implementation of ExternalApiService for calling my-tiny-app API
 */
export class ItemApiService implements IExternalApiService {
  /**
   * Call my-tiny-app search API to get item by name
   */
  async searchItemByName(name: string): Promise<ItemFromApiEntity | null> {
    const apiUrl = process.env.MY_TINY_APP_API_URL || 'http://app:3000';
    const searchEndpoint = `${apiUrl}/api/items/search`;

    try {
      const response = await fetch(searchEndpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ name }),
      });

      if (!response.ok) {
        if (response.status === 404) {
          return null; // Item not found
        }
        throw new Error(`API call failed with status ${response.status}`);
      }

      const result = (await response.json()) as ApiResponse;

      if (!result.success || !result.data) {
        return null;
      }

      return {
        name: result.data.name,
        description: result.data.description,
        price: result.data.price,
        quantity: result.data.quantity,
      };
    } catch (error) {
      console.error('Error calling my-tiny-app API:', error);
      throw error;
    }
  }
}

