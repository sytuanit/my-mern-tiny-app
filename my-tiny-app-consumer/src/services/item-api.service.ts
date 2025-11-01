/**
 * Service for calling my-tiny-app API
 */

interface ItemFromApi {
  name: string;
  description?: string;
  price?: number;
  quantity?: number;
  _id?: string;
  createdAt?: string;
  updatedAt?: string;
}

interface ApiResponse {
  success: boolean;
  data?: ItemFromApi;
  message?: string;
  error?: string;
}

/**
 * Call my-tiny-app search API to get item by name
 * @param name - Item name to search
 * @returns Item from my-tiny-app API or null if not found
 */
export async function searchItemFromApi(name: string): Promise<ItemFromApi | null> {
  const apiUrl = process.env.MY_TINY_APP_API_URL || 'http://my-tiny-app:3000';
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

    return result.data;
  } catch (error) {
    console.error('Error calling my-tiny-app API:', error);
    throw error;
  }
}

