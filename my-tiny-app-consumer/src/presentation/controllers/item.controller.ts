import { Request, Response } from 'express';
import { SearchItemByNameUseCase } from '../../application/use-cases/search-item-by-name.use-case';
import { searchItemRequestSchema, ConsumedItemResponseDto, ApiResponseDto } from '../dtos/item.dto';

/**
 * Search item by name controller
 */
export const searchItemByName = async (req: Request, res: Response): Promise<void> => {
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

    const useCase = req.app.locals.searchItemByNameUseCase as SearchItemByNameUseCase;
    const result = await useCase.execute(validationResult.data.name);

    if (!result.success) {
      // Determine status code based on error type
      let statusCode = 500;
      if (result.error?.includes('not found in consumer database')) {
        statusCode = 404;
      } else if (result.error?.includes('not found in my-tiny-app database')) {
        statusCode = 404;
      } else if (result.error?.includes('does not match')) {
        statusCode = 404;
      } else if (result.error?.includes('Error calling')) {
        statusCode = 500;
      }

      const response: ApiResponseDto<never> = {
        success: false,
        message: result.error || 'Error searching item',
        details: result.details,
      };
      res.status(statusCode).json(response);
      return;
    }

    // Success - return item
    const item = result.item!;
    const response: ApiResponseDto<ConsumedItemResponseDto> = {
      success: true,
      message: 'Item found and fields match',
      data: {
        id: item.id,
        name: item.name,
        description: item.description,
        price: item.price,
        quantity: item.quantity,
        originalItemId: item.originalItemId,
        lastSyncedAt: item.lastSyncedAt,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      },
    };

    res.status(200).json(response);
  } catch (error) {
    const response: ApiResponseDto<never> = {
      success: false,
      message: 'Error searching item',
      error: error instanceof Error ? error.message : 'Unknown error',
    };
    res.status(500).json(response);
  }
};

