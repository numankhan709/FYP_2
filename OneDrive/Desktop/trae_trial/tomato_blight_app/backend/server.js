const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const mongoose = require('mongoose');
const path = require('path');

// Load environment variables with debugging
console.log('🔍 Debug: Loading .env file from:', path.resolve('.env'));
const dotenvResult = require('dotenv').config();
if (dotenvResult.error) {
  console.error('❌ Debug: Error loading .env file:', dotenvResult.error);
} else {
  console.log('✅ Debug: .env file loaded successfully');
  console.log('🔍 Debug: Environment variables loaded:', Object.keys(dotenvResult.parsed || {}));
}

const app = express();
const PORT = process.env.PORT || 3000;

// MongoDB Connection with Debug Messages
console.log('🔍 MongoDB Debug: Starting database connection...');
console.log('🔍 MongoDB Debug: Connection string:', process.env.MONGODB_URI ? 'Found' : 'Missing');
console.log('🔍 MongoDB Debug: Actual URI (first 50 chars):', process.env.MONGODB_URI ? process.env.MONGODB_URI.substring(0, 50) + '...' : 'Not found');

if (!process.env.MONGODB_URI) {
  console.error('❌ MongoDB Debug: MONGODB_URI environment variable is not set!');
  console.error('❌ MongoDB Debug: Please check your .env file');
  process.exit(1);
}

// Connect to MongoDB with improved connection options
console.log('🔍 MongoDB Debug: About to connect with URI:', process.env.MONGODB_URI);
mongoose.connect(process.env.MONGODB_URI, {
  maxPoolSize: 10, // Maintain up to 10 socket connections
  serverSelectionTimeoutMS: 5000, // Keep trying to send operations for 5 seconds
  socketTimeoutMS: 45000, // Close sockets after 45 seconds of inactivity
})
.then(() => {
  console.log('✅ MongoDB Debug: Successfully connected to MongoDB');
  console.log('✅ MongoDB Debug: Database name:', mongoose.connection.name);
  console.log('✅ MongoDB Debug: Connection state:', mongoose.connection.readyState);
})
.catch((error) => {
  console.error('❌ MongoDB Debug: Failed to connect to MongoDB');
  console.error('❌ MongoDB Debug: Error details:', error.message);
  console.error('❌ MongoDB Debug: Full error:', error);
  process.exit(1);
});

// MongoDB connection event listeners
mongoose.connection.on('connected', () => {
  console.log('🔗 MongoDB Debug: Mongoose connected to MongoDB');
});

mongoose.connection.on('error', (err) => {
  console.error('❌ MongoDB Debug: Mongoose connection error:', err);
});

mongoose.connection.on('disconnected', () => {
  console.log('⚠️ MongoDB Debug: Mongoose disconnected from MongoDB');
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('🛑 MongoDB Debug: Received SIGINT, closing MongoDB connection...');
  await mongoose.connection.close();
  console.log('✅ MongoDB Debug: MongoDB connection closed');
  process.exit(0);
});

// Middleware
app.use(helmet());
app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    
    // Allow any localhost origin during development
    if (process.env.NODE_ENV === 'development' && origin.includes('localhost')) {
      return callback(null, true);
    }
    
    // Allow any 127.0.0.1 origin during development
    if (process.env.NODE_ENV === 'development' && origin.includes('127.0.0.1')) {
      return callback(null, true);
    }
    
    // Allow the specific frontend URL from environment
    if (origin === process.env.FRONTEND_URL) {
      return callback(null, true);
    }
    
    // Reject other origins
    callback(new Error('Not allowed by CORS'));
  },
  credentials: true
}));
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Serve static files for uploaded images
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/weather', require('./routes/weather'));
app.use('/api/disease', require('./routes/disease'));
app.use('/api/diseases', require('./routes/disease')); // Alias for disease routes
app.use('/api/scans', require('./routes/scans'));
app.use('/api/reports', require('./routes/reports'));

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    message: 'Tomato Blight Detection API is running',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'API endpoint not found'
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Error:', err.stack);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📱 Health check: http://localhost:${PORT}/api/health`);
  console.log(`🌐 Network access: http://172.17.243.50:${PORT}/api/health`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;