const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Middleware to verify JWT token
const authenticateToken = async (req, res, next) => {
  console.log('🔍 Auth Debug: Authenticating token...');
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    console.log('❌ Auth Debug: No token provided');
    return res.status(401).json({
      success: false,
      message: 'Access token required'
    });
  }

  try {
    console.log('🔍 Auth Debug: Verifying JWT token...');
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret');
    console.log('🔍 Auth Debug: Token decoded, userId:', decoded.userId);
    
    // Verify user exists in database
    const user = await User.findById(decoded.userId);
    if (!user) {
      console.log('❌ Auth Debug: User not found in database for userId:', decoded.userId);
      return res.status(403).json({
        success: false,
        message: 'User not found'
      });
    }
    
    console.log('✅ Auth Debug: User authenticated successfully:', user.email);
    req.userId = decoded.userId;
    req.user = user;
    next();
  } catch (err) {
    console.log('❌ Auth Debug: Token verification failed:', err.message);
    return res.status(403).json({
      success: false,
      message: 'Invalid or expired token'
    });
  }
};

module.exports = authenticateToken;