'use client';

import { useState } from 'react';

interface SearchFormProps {
  onSearch: (name: string) => void;
}

export default function SearchForm({ onSearch }: SearchFormProps) {
  const [searchName, setSearchName] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (searchName.trim()) {
      onSearch(searchName.trim());
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <div className="input-group">
        <input
          type="text"
          value={searchName}
          onChange={(e) => setSearchName(e.target.value)}
          placeholder="Enter item name to search..."
          style={{ flex: 1 }}
        />
        <button type="submit" className="button button-success">
          🔍 Search
        </button>
      </div>
    </form>
  );
}

