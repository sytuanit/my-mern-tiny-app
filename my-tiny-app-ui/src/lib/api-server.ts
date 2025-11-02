import { Item, ApiResponse } from '@/types/item';

/**
 * Server-side API utility for fetching data
 * Uses native fetch (works on server)
 */
const getApiUrl = (): string => {
  // On server, use environment variable without NEXT_PUBLIC prefix if available
  // or fallback to NEXT_PUBLIC_API_URL
  return process.env.API_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';
};

const getBaseUrl = (): string => {
  return `${getApiUrl()}/api/items`;
};

/**
 * Fetch all items (server-side)
 */
export async function getAllItems(): Promise<Item[]> {
  try {
    const response = await fetch(`${getBaseUrl()}/`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
      // Add cache configuration
      cache: 'no-store', // Always fetch fresh data on server
    });

    if (!response.ok) {
      throw new Error(`Failed to fetch items: ${response.statusText}`);
    }

    const data: ApiResponse<Item[]> = await response.json();
    return data.data || [];
  } catch (error) {
    console.error('Error fetching items:', error);
    return [];
  }
}

/**
 * Get item by ID (server-side)
 */
export async function getItemById(id: string): Promise<Item | null> {
  try {
    const response = await fetch(`${getBaseUrl()}/${id}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
      cache: 'no-store',
    });

    if (response.status === 404) {
      return null;
    }

    if (!response.ok) {
      throw new Error(`Failed to fetch item: ${response.statusText}`);
    }

    const data: ApiResponse<Item> = await response.json();
    return data.data || null;
  } catch (error) {
    console.error('Error fetching item:', error);
    return null;
  }
}

