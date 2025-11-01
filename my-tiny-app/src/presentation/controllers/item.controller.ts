import { Request, Response } from 'express';
import { GetAllItemsUseCase } from '../../application/use-cases/get-all-items.use-case';
import { GetItemByIdUseCase } from '../../application/use-cases/get-item-by-id.use-case';
import { GetItemByNameUseCase } from '../../application/use-cases/get-item-by-name.use-case';
import { CreateItemUseCase } from '../../application/use-cases/create-item.use-case';
import { UpdateItemUseCase } from '../../application/use-cases/update-item.use-case';
import { DeleteItemUseCase } from '../../application/use-cases/delete-item.use-case';
import {
  createItemRequestSchema,
  updateItemRequestSchema,
  searchItemRequestSchema,
  ItemResponseDto,
  ApiResponseDto,
} from '../dtos/item.dto';

/**
 * Get all items
 */
export const getAllItems = async (req: Request, res: Response): Promise<void> => {
  try {
    const useCase = req.app.locals.getAllItemsUseCase as GetAllItemsUseCase;
    const items = await useCase.execute();

    const response: ApiResponseDto<ItemResponseDto[]> = {
      success: true,
      count: items.length,
      data: items.map((item) => ({
        id: item.id,
        name: item.name,
        description: item.description,
        price: item.price,
        quantity: item.quantity,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      })),
    };

    res.status(200).json(response);
  } catch (error) {
    const response: ApiResponseDto<never> = {
      success: false,
      message: 'Error fetching items',
      error: error instanceof Error ? error.message : 'Unknown error',
    };
    res.status(500).json(response);
  }
};

/**
 * Search item by name
 */
export const getItemByName = async (req: Request, res: Response): Promise<void> => {
  try {
    // Validate request
    const validationResult = searchItemRequestSchema.safeParse(req.body);
    if (!validationResult.success) {
      const response: ApiResponseDto<never> = {
        success: false,
        message: 'Validation error',
        error: validationResult.error.errors.map((e) => `${e.path.join('.')}: ${e.message}`).join('; '),
      };
      res.status(400).json(response);
      return;
    }

    const useCase = req.app.locals.getItemByNameUseCase as GetItemByNameUseCase;
    const item = await useCase.execute(validationResult.data.name);

    const response: ApiResponseDto<ItemResponseDto> = {
      success: true,
      data: {
        id: item.id,
        name: item.name,
        description: item.description,
        price: item.price,
        quantity: item.quantity,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      },
    };

    res.status(200).json(response);
  } catch (error) {
    if (error instanceof Error && error.message === 'Item not found') {
      const response: ApiResponseDto<never> = {
        success: false,
        message: 'Item not found',
      };
      res.status(404).json(response);
      return;
    }

    const response: ApiResponseDto<never> = {
      success: false,
      message: 'Error searching item by name',
      error: error instanceof Error ? error.message : 'Unknown error',
    };
    res.status(500).json(response);
  }
};

/**
 * Get item by ID
 */
export const getItemById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const useCase = req.app.locals.getItemByIdUseCase as GetItemByIdUseCase;
    const item = await useCase.execute(id);

    const response: ApiResponseDto<ItemResponseDto> = {
      success: true,
      data: {
        id: item.id,
        name: item.name,
        description: item.description,
        price: item.price,
        quantity: item.quantity,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      },
    };

    res.status(200).json(response);
  } catch (error) {
    if (error instanceof Error && error.message === 'Item not found') {
      const response: ApiResponseDto<never> = {
        success: false,
        message: 'Item not found',
      };
      res.status(404).json(response);
      return;
    }

    if (error instanceof Error && error.message === 'Invalid item ID format') {
      const response: ApiResponseDto<never> = {
        success: false,
        message: 'Invalid item ID format',
      };
      res.status(400).json(response);
      return;
    }

    const response: ApiResponseDto<never> = {
      success: false,
      message: 'Error fetching item',
      error: error instanceof Error ? error.message : 'Unknown error',
    };
    res.status(500).json(response);
  }
};

/**
 * Create new item
 */
export const createItem = async (req: Request, res: Response): Promise<void> => {
  try {
    // Validate request
    const validationResult = createItemRequestSchema.safeParse(req.body);
    if (!validationResult.success) {
      const response: ApiResponseDto<never> = {
        success: false,
        message: 'Validation error',
        error: validationResult.error.errors.map((e) => `${e.path.join('.')}: ${e.message}`).join('; '),
      };
      res.status(400).json(response);
      return;
    }

    const useCase = req.app.locals.createItemUseCase as CreateItemUseCase;
    const item = await useCase.execute(validationResult.data);

    const response: ApiResponseDto<ItemResponseDto> = {
      success: true,
      message: 'Item created successfully',
      data: {
        id: item.id,
        name: item.name,
        description: item.description,
        price: item.price,
        quantity: item.quantity,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      },
    };

    res.status(201).json(response);
  } catch (error) {
    if (error instanceof Error && error.message.includes('Validation error')) {
      const response: ApiResponseDto<never> = {
        success: false,
        message: 'Validation error',
        error: error.message,
      };
      res.status(400).json(response);
      return;
    }

    const response: ApiResponseDto<never> = {
      success: false,
      message: 'Error creating item',
      error: error instanceof Error ? error.message : 'Unknown error',
    };
    res.status(500).json(response);
  }
};

/**
 * Update item by ID
 */
export const updateItem = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    // Validate request
    const validationResult = updateItemRequestSchema.safeParse(req.body);
    if (!validationResult.success) {
      const response: ApiResponseDto<never> = {
        success: false,
        message: 'Validation error',
        error: validationResult.error.errors.map((e) => `${e.path.join('.')}: ${e.message}`).join('; '),
      };
      res.status(400).json(response);
      return;
    }

    const useCase = req.app.locals.updateItemUseCase as UpdateItemUseCase;
    const item = await useCase.execute(id, validationResult.data);

    const response: ApiResponseDto<ItemResponseDto> = {
      success: true,
      message: 'Item updated successfully',
      data: {
        id: item.id,
        name: item.name,
        description: item.description,
        price: item.price,
        quantity: item.quantity,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      },
    };

    res.status(200).json(response);
  } catch (error) {
    if (error instanceof Error && error.message === 'Item not found') {
      const response: ApiResponseDto<never> = {
        success: false,
        message: 'Item not found',
      };
      res.status(404).json(response);
      return;
    }

    if (error instanceof Error && error.message === 'Invalid item ID format') {
      const response: ApiResponseDto<never> = {
        success: false,
        message: 'Invalid item ID format',
      };
      res.status(400).json(response);
      return;
    }

    if (error instanceof Error && error.message.includes('Validation error')) {
      const response: ApiResponseDto<never> = {
        success: false,
        message: 'Validation error',
        error: error.message,
      };
      res.status(400).json(response);
      return;
    }

    const response: ApiResponseDto<never> = {
      success: false,
      message: 'Error updating item',
      error: error instanceof Error ? error.message : 'Unknown error',
    };
    res.status(500).json(response);
  }
};

/**
 * Delete item by ID
 */
export const deleteItem = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const useCase = req.app.locals.deleteItemUseCase as DeleteItemUseCase;
    const item = await useCase.execute(id);

    const response: ApiResponseDto<ItemResponseDto> = {
      success: true,
      message: 'Item deleted successfully',
      data: {
        id: item.id,
        name: item.name,
        description: item.description,
        price: item.price,
        quantity: item.quantity,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      },
    };

    res.status(200).json(response);
  } catch (error) {
    if (error instanceof Error && error.message === 'Item not found') {
      const response: ApiResponseDto<never> = {
        success: false,
        message: 'Item not found',
      };
      res.status(404).json(response);
      return;
    }

    if (error instanceof Error && error.message === 'Invalid item ID format') {
      const response: ApiResponseDto<never> = {
        success: false,
        message: 'Invalid item ID format',
      };
      res.status(400).json(response);
      return;
    }

    const response: ApiResponseDto<never> = {
      success: false,
      message: 'Error deleting item',
      error: error instanceof Error ? error.message : 'Unknown error',
    };
    res.status(500).json(response);
  }
};

