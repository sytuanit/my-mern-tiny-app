'use client';

import { Item } from '@/types/item';

interface ItemCardProps {
  item: Item;
  onEdit: (item: Item) => void;
  onDelete: (id: string) => void;
}

export default function ItemCard({ item, onEdit, onDelete }: ItemCardProps) {
  const formatDate = (dateString?: string) => {
    if (!dateString) return 'N/A';
    return new Date(dateString).toLocaleString();
  };

  return (
    <div className="item-card">
      <h3>{item.name}</h3>
      {item.description && <p>{item.description}</p>}
      {item.price !== undefined && (
        <p>
          <span className="price">Price: ${item.price.toFixed(2)}</span>
        </p>
      )}
      {item.quantity !== undefined && (
        <p>
          <span className="quantity">Quantity: {item.quantity}</span>
        </p>
      )}
      <p style={{ fontSize: '0.8rem', color: '#999', marginTop: '10px' }}>
        Created: {formatDate(item.createdAt)}
      </p>
      {item.updatedAt && item.updatedAt !== item.createdAt && (
        <p style={{ fontSize: '0.8rem', color: '#999' }}>
          Updated: {formatDate(item.updatedAt)}
        </p>
      )}
      <div className="actions">
        <button className="button button-primary" onClick={() => onEdit(item)}>
          ✏️ Edit
        </button>
        <button className="button button-danger" onClick={() => onDelete(item.id!)}>
          🗑️ Delete
        </button>
      </div>
    </div>
  );
}

