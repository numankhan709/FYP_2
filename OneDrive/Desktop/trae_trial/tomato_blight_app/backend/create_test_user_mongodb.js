const mongoose = require('mongoose');
const User = require('./models/User');
require('dotenv').config();

async function createTestUser() {
  try {
    console.log('🔍 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Check if test user already exists
    const existingUser = await User.findByEmail('test@example.com');
    if (existingUser) {
      console.log('✅ Test user already exists:', existingUser.email);
      return;
    }

    // Create test user
    console.log('🔍 Creating test user...');
    const testUser = new User({
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123' // Will be hashed by pre-save middleware
    });

    const savedUser = await testUser.save();
    console.log('✅ Test user created successfully:', savedUser.email);
    console.log('✅ User ID:', savedUser._id);

  } catch (error) {
    console.error('❌ Error creating test user:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔍 Disconnected from MongoDB');
  }
}

createTestUser();