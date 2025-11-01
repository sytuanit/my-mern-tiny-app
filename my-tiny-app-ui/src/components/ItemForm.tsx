'use client';

import { useState, useEffect } from 'react';
import { Item, ItemInput } from '@/types/item';

interface ItemFormProps {
  item?: Item | null;
  onSubmit: (data: ItemInput | Partial<ItemInput>) => Promise<void> | void;
  onCancel?: () => void;
}

export default function ItemForm({ item, onSubmit, onCancel }: ItemFormProps) {
  const [formData, setFormData] = useState<{
    name: string;
    description: string;
    price: number | undefined;
    quantity: number | undefined;
  }>({
    name: '',
    description: '',
    price: undefined,
    quantity: undefined,
  });

  useEffect(() => {
    if (item) {
      setFormData({
        name: item.name || '',
        description: item.description || '',
        price: item.price,
        quantity: item.quantity,
      });
    } else {
      setFormData({
        name: '',
        description: '',
        price: undefined,
        quantity: undefined,
      });
    }
  }, [item]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const submitData: ItemInput | Partial<ItemInput> = {
      name: formData.name,
    };

    if (formData.description) {
      submitData.description = formData.description;
    }
    if (formData.price !== undefined) {
      submitData.price = formData.price;
    }
    if (formData.quantity !== undefined) {
      submitData.quantity = formData.quantity;
    }

    onSubmit(submitData);
    if (!item) {
      // Reset form after create
      setFormData({
        name: '',
        description: '',
        price: undefined,
        quantity: undefined,
      });
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => {
      if (name === 'price') {
        return { ...prev, [name]: value === '' ? undefined : parseFloat(value) || undefined };
      } else if (name === 'quantity') {
        return { ...prev, [name]: value === '' ? undefined : parseInt(value, 10) || undefined };
      } else {
        return { ...prev, [name]: value };
      }
    });
  };

  return (
    <form onSubmit={handleSubmit}>
      <div className="form-group">
        <label htmlFor="name">
          Name <span style={{ color: 'red' }}>*</span>
        </label>
        <input
          type="text"
          id="name"
          name="name"
          value={formData.name}
          onChange={handleChange}
          required
          placeholder="Enter item name"
        />
      </div>

      <div className="form-group">
        <label htmlFor="description">Description</label>
        <textarea
          id="description"
          name="description"
          value={formData.description || ''}
          onChange={handleChange}
          placeholder="Enter item description (optional)"
        />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
        <div className="form-group">
          <label htmlFor="price">Price</label>
          <input
            type="number"
            id="price"
            name="price"
            value={formData.price || ''}
            onChange={handleChange}
            min="0"
            step="0.01"
            placeholder="0.00"
          />
        </div>

        <div className="form-group">
          <label htmlFor="quantity">Quantity</label>
          <input
            type="number"
            id="quantity"
            name="quantity"
            value={formData.quantity || ''}
            onChange={handleChange}
            min="0"
            step="1"
            placeholder="0"
          />
        </div>
      </div>

      <div style={{ display: 'flex', gap: '10px', marginTop: '20px' }}>
        <button type="submit" className="button button-primary">
          {item ? '💾 Update Item' : '➕ Create Item'}
        </button>
        {onCancel && (
          <button type="button" onClick={onCancel} className="button button-secondary">
            Cancel
          </button>
        )}
      </div>
    </form>
  );
}

