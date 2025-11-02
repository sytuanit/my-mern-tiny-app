import { getAllItems } from '@/lib/api-server';
import ItemsClient from '@/components/ItemsClient';

/**
 * Server Component - Fetches initial data on the server
 * All interactions are handled by ItemsClient component
 */
export default async function Home() {
  // Fetch items on the server
  const initialItems = await getAllItems();

  return (
    <div className="container">
      <div className="header">
        <h1>📦 My Tiny App</h1>
        <p>Item Management System - CRUD Operations</p>
      </div>

      <ItemsClient initialItems={initialItems} />
    </div>
  );
}

