'use client';

import { useState, useEffect } from 'react';
import { apiService } from '@/services/api';
import { Item, ItemInput } from '@/types/item';
import ItemForm from '@/components/ItemForm';
import ItemCard from '@/components/ItemCard';
import SearchForm from '@/components/SearchForm';

interface ItemsClientProps {
  initialItems: Item[];
}

export default function ItemsClient({ initialItems }: ItemsClientProps) {
  const [items, setItems] = useState<Item[]>(initialItems);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error' | 'info'; text: string } | null>(null);
  const [editingItem, setEditingItem] = useState<Item | null>(null);
  const [searchResult, setSearchResult] = useState<Item | null>(null);

  // Sync with initialItems when they change (e.g., after server-side refresh)
  useEffect(() => {
    setItems(initialItems);
  }, [initialItems]);

  const loadItems = async () => {
    try {
      setLoading(true);
      const data = await apiService.getAllItems();
      setItems(data);
      setMessage(null);
    } catch (error: any) {
      setMessage({
        type: 'error',
        text: `Failed to load items: ${error.response?.data?.message || error.message}`,
      });
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = async (itemData: ItemInput) => {
    try {
      const newItem = await apiService.createItem(itemData);
      setItems([newItem, ...items]);
      setMessage({ type: 'success', text: 'Item created successfully!' });
      setEditingItem(null);
    } catch (error: any) {
      setMessage({
        type: 'error',
        text: `Failed to create item: ${error.response?.data?.message || error.message}`,
      });
    }
  };

  const handleUpdate = async (id: string, itemData: Partial<ItemInput>) => {
    try {
      const updatedItem = await apiService.updateItem(id, itemData);
      if (updatedItem) {
        setItems(items.map((item) => (item.id === id ? updatedItem : item)));
        setMessage({ type: 'success', text: 'Item updated successfully!' });
        setEditingItem(null);
      } else {
        setMessage({ type: 'error', text: 'Item not found' });
      }
    } catch (error: any) {
      setMessage({
        type: 'error',
        text: `Failed to update item: ${error.response?.data?.message || error.message}`,
      });
    }
  };

  const handleFormSubmit = (data: ItemInput | Partial<ItemInput>) => {
    if (editingItem) {
      return handleUpdate(editingItem.id!, data as Partial<ItemInput>);
    } else {
      return handleCreate(data as ItemInput);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this item?')) {
      return;
    }

    try {
      const deletedItem = await apiService.deleteItem(id);
      if (deletedItem) {
        setItems(items.filter((item) => item.id !== id));
        setMessage({ type: 'success', text: 'Item deleted successfully!' });
      } else {
        setMessage({ type: 'error', text: 'Item not found' });
      }
    } catch (error: any) {
      setMessage({
        type: 'error',
        text: `Failed to delete item: ${error.response?.data?.message || error.message}`,
      });
    }
  };

  const handleSearch = async (name: string) => {
    try {
      const result = await apiService.searchItemByName(name);
      if (result) {
        setSearchResult(result);
        setMessage({ type: 'info', text: `Found item: ${result.name}` });
      } else {
        setSearchResult(null);
        setMessage({ type: 'info', text: 'Item not found' });
      }
    } catch (error: any) {
      setMessage({
        type: 'error',
        text: `Search failed: ${error.response?.data?.message || error.message}`,
      });
      setSearchResult(null);
    }
  };

  const clearMessage = () => {
    setMessage(null);
  };

  useEffect(() => {
    if (message) {
      const timer = setTimeout(clearMessage, 5000);
      return () => clearTimeout(timer);
    }
  }, [message]);

  return (
    <>
      {message && (
        <div className={`message message-${message.type}`}>
          {message.text}
          <button
            onClick={clearMessage}
            style={{ float: 'right', background: 'none', border: 'none', cursor: 'pointer', fontSize: '1.2rem' }}
          >
            ×
          </button>
        </div>
      )}

      <div className="section">
        <h2 className="section-title">🔍 Search Item by Name</h2>
        <SearchForm onSearch={handleSearch} />
        {searchResult && (
          <div style={{ marginTop: '20px' }}>
            <ItemCard
              item={searchResult}
              onEdit={setEditingItem}
              onDelete={handleDelete}
            />
          </div>
        )}
      </div>

      <div className="section">
        <h2 className="section-title">
          {editingItem ? '✏️ Edit Item' : '➕ Create New Item'}
        </h2>
        <ItemForm
          item={editingItem}
          onSubmit={handleFormSubmit}
          onCancel={() => setEditingItem(null)}
        />
      </div>

      <div className="section">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
          <h2 className="section-title" style={{ margin: 0 }}>
            📋 All Items ({items.length})
          </h2>
          <button className="button button-secondary" onClick={loadItems}>
            🔄 Refresh
          </button>
        </div>

        {loading ? (
          <div className="loading">Loading items...</div>
        ) : items.length === 0 ? (
          <div className="empty-state">No items found. Create your first item above!</div>
        ) : (
          <div className="items-grid">
            {items.map((item) => (
              <ItemCard
                key={item.id}
                item={item}
                onEdit={setEditingItem}
                onDelete={handleDelete}
              />
            ))}
          </div>
        )}
      </div>
    </>
  );
}

