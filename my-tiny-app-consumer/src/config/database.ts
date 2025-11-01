import mongoose from 'mongoose';

/**
 * Connects to MongoDB database
 * @throws {Error} If connection fails
 */
export const connectDatabase = async (): Promise<void> => {
  const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/my-tiny-app';

  try {
    await mongoose.connect(mongoUri);
    console.log('Connected to MongoDB successfully');
  } catch (error) {
    console.error('MongoDB connection error:', error);
    throw error;
  }
};

