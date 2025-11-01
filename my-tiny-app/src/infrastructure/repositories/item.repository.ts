import mongoose from 'mongoose';
import { IItemRepository } from '../../domain/interfaces/item.repository.interface';
import { ItemEntity, CreateItemInput, UpdateItemInput } from '../../domain/entities/item.entity';
import { Item, IItem, itemSchemaZod } from '../../models/item.model';

/**
 * MongoDB implementation of ItemRepository
 */
export class ItemRepository implements IItemRepository {
  /**
   * Map Mongoose document to domain entity
   */
  private toDomainEntity(doc: IItem): ItemEntity {
    return {
      id: String(doc._id),
      name: doc.name,
      description: doc.description,
      price: doc.price,
      quantity: doc.quantity,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  async findAll(): Promise<ItemEntity[]> {
    const items = await Item.find().sort({ createdAt: -1 });
    return items.map((item) => this.toDomainEntity(item));
  }

  async findById(id: string): Promise<ItemEntity | null> {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw new Error('Invalid item ID format');
    }

    const item = await Item.findById(id);
    return item ? this.toDomainEntity(item) : null;
  }

  async findByName(name: string): Promise<ItemEntity | null> {
    const item = await Item.findOne({ name }).sort({ createdAt: -1 });
    return item ? this.toDomainEntity(item) : null;
  }

  async create(itemData: CreateItemInput): Promise<ItemEntity> {
    // Validate input
    const validationResult = itemSchemaZod.safeParse(itemData);
    if (!validationResult.success) {
      const errorMessages = validationResult.error.errors.map((e) => `${e.path.join('.')}: ${e.message}`).join('; ');
      throw new Error(`Validation error: ${errorMessages}`);
    }

    const validatedData = validationResult.data;
    const newItem = new Item(validatedData);
    const savedItem = await newItem.save();
    return this.toDomainEntity(savedItem);
  }

  async update(id: string, updateData: UpdateItemInput): Promise<ItemEntity | null> {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw new Error('Invalid item ID format');
    }

    // Validate input
    const validationResult = itemSchemaZod.partial().safeParse(updateData);
    if (!validationResult.success) {
      const errorMessages = validationResult.error.errors.map((e) => `${e.path.join('.')}: ${e.message}`).join('; ');
      throw new Error(`Validation error: ${errorMessages}`);
    }

    const validatedData = validationResult.data;
    const updatedItem = await Item.findByIdAndUpdate(id, validatedData, {
      new: true,
      runValidators: true,
    });

    return updatedItem ? this.toDomainEntity(updatedItem) : null;
  }

  async delete(id: string): Promise<ItemEntity | null> {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw new Error('Invalid item ID format');
    }

    const deletedItem = await Item.findByIdAndDelete(id);
    return deletedItem ? this.toDomainEntity(deletedItem) : null;
  }
}

