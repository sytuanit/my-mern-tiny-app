import axios, { AxiosInstance } from 'axios';
import { Item, ItemInput, ApiResponse } from '@/types/item';

/**
 * API client for my-tiny-app backend
 */
class ApiService {
  private client: AxiosInstance;

  constructor() {
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';
    this.client = axios.create({
      baseURL: `${apiUrl}/api/items`,
      headers: {
        'Content-Type': 'application/json',
      },
    });
  }

  /**
   * Get all items
   */
  async getAllItems(): Promise<Item[]> {
    const response = await this.client.get<ApiResponse<Item[]>>('/');
    return response.data.data || [];
  }

  /**
   * Get item by ID
   */
  async getItemById(id: string): Promise<Item | null> {
    try {
      const response = await this.client.get<ApiResponse<Item>>(`/${id}`);
      return response.data.data || null;
    } catch (error: any) {
      if (error.response?.status === 404) {
        return null;
      }
      throw error;
    }
  }

  /**
   * Search item by name (POST request)
   */
  async searchItemByName(name: string): Promise<Item | null> {
    try {
      const response = await this.client.post<ApiResponse<Item>>('/search', { name });
      return response.data.data || null;
    } catch (error: any) {
      if (error.response?.status === 404) {
        return null;
      }
      throw error;
    }
  }

  /**
   * Create new item
   */
  async createItem(item: ItemInput): Promise<Item> {
    const response = await this.client.post<ApiResponse<Item>>('/', item);
    if (!response.data.data) {
      throw new Error('Failed to create item');
    }
    return response.data.data;
  }

  /**
   * Update item by ID
   */
  async updateItem(id: string, item: Partial<ItemInput>): Promise<Item | null> {
    try {
      const response = await this.client.put<ApiResponse<Item>>(`/${id}`, item);
      return response.data.data || null;
    } catch (error: any) {
      if (error.response?.status === 404) {
        return null;
      }
      throw error;
    }
  }

  /**
   * Delete item by ID
   */
  async deleteItem(id: string): Promise<Item | null> {
    try {
      const response = await this.client.delete<ApiResponse<Item>>(`/${id}`);
      return response.data.data || null;
    } catch (error: any) {
      if (error.response?.status === 404) {
        return null;
      }
      throw error;
    }
  }
}

export const apiService = new ApiService();

