const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const sharp = require('sharp');
const path = require('path');
const fs = require('fs').promises;
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const authenticateToken = require('../middleware/auth');

const router = express.Router();

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, '..', 'uploads', 'profiles');
fs.mkdir(uploadsDir, { recursive: true }).catch(console.error);

// Configure multer for profile picture uploads
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit for profile pictures
  },
  fileFilter: (req, file, cb) => {
    console.log('ðŸ” Multer Debug: File filter called');
    console.log('ðŸ” Multer Debug: File details:', {
      fieldname: file.fieldname,
      originalname: file.originalname,
      mimetype: file.mimetype,
      encoding: file.encoding
    });
    
    // Check file type - accept proper image MIME types or octet-stream with image extensions
    const isImageMimeType = file.mimetype.startsWith('image/');
    const isOctetStreamWithImageExt = file.mimetype === 'application/octet-stream' && 
      file.originalname && /\.(jpg|jpeg|png|gif|webp)$/i.test(file.originalname);
    
    if (isImageMimeType || isOctetStreamWithImageExt) {
      console.log('âœ… Multer Debug: File accepted as image');
      cb(null, true);
    } else {
      console.log('âŒ Multer Debug: File rejected - not an image');
      console.log('âŒ Multer Debug: MIME type:', file.mimetype);
      console.log('âŒ Multer Debug: Original name:', file.originalname);
      cb(new Error('Only image files are allowed'), false);
    }
  }
});console.log('ðŸ” Auth Routes Debug: Auth routes module loaded');
console.log('ðŸ” Auth Routes Debug: User model imported successfully');

// Helper function to generate JWT token
const generateToken = (userId) => {
  return jwt.sign(
    { userId },
    process.env.JWT_SECRET || 'fallback_secret',
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
};



// Validation rules
const signupValidation = [
  body('name')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Name must be between 2 and 50 characters'),
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('password')
    .isLength({ min: 5 })
    .withMessage('Password must be at least 5 characters long')
    .matches(/^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{5,}$/)
    .withMessage('Password must include upper, lower, and a number (min 5 chars)')
];

const loginValidation = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('password')
    .notEmpty()
    .withMessage('Password is required')
];

// @route   POST /api/auth/signup
// @desc    Register a new user
// @access  Public
router.post('/signup', signupValidation, async (req, res) => {
  console.log('ðŸ” Auth Debug: Signup request received');
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log('âŒ Auth Debug: Validation errors:', errors.array());
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { name, email, password } = req.body;
    console.log('ðŸ” Auth Debug: Signup attempt for email:', email);

    // Check if user already exists
    console.log('ðŸ” Auth Debug: Checking if user exists...');
    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      console.log('âŒ Auth Debug: User already exists with email:', email);
      return res.status(400).json({
        success: false,
        message: 'User with this email already exists'
      });
    }
    console.log('âœ… Auth Debug: Email is available');

    // Create new user (password will be hashed by pre-save middleware)
    console.log('ðŸ” Auth Debug: Creating new user...');
    const newUser = new User({
      name,
      email,
      password
    });

    console.log('ðŸ” Auth Debug: Saving user to database...');
    const savedUser = await newUser.save();
    console.log('âœ… Auth Debug: User saved successfully with ID:', savedUser._id);

    // Generate token
    console.log('ðŸ” Auth Debug: Generating JWT token...');
    const token = generateToken(savedUser._id);
    console.log('âœ… Auth Debug: Token generated successfully');

    // Return user data (password excluded by toJSON method)
    console.log('âœ… Auth Debug: Signup completed successfully for:', email);
    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      user: savedUser.toJSON(),
      token
    });
  } catch (error) {
    console.error('âŒ Auth Debug: Signup error:', error.message);
    console.error('âŒ Auth Debug: Full error:', error);
    
    // Check for specific MongoDB errors
    if (error.name === 'ValidationError') {
      console.log('âŒ Auth Debug: MongoDB validation error');
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: Object.values(error.errors).map(err => err.message)
      });
    }
    
    if (error.code === 11000) {
      console.log('âŒ Auth Debug: MongoDB duplicate key error');
      return res.status(400).json({
        success: false,
        message: 'User with this email already exists'
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Using MongoDB database for user storage

// @route   POST /api/auth/login
// @desc    Login user
// @access  Public
router.post('/login', loginValidation, async (req, res) => {
  console.log('ðŸ” Auth Debug: Login request received');
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log('âŒ Auth Debug: Login validation errors:', errors.array());
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { email, password } = req.body;
    console.log('ðŸ” Auth Debug: Login attempt for email:', email);

    // Find user in MongoDB database
    console.log('ðŸ” Auth Debug: Searching for user in MongoDB database...');
    const user = await User.findByEmail(email);
    if (!user) {
      console.log('âŒ Auth Debug: User not found with email:', email);
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }
    console.log('âœ… Auth Debug: User found:', user._id);

    // Check password using the user's comparePassword method
    console.log('ðŸ” Auth Debug: Verifying password...');
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      console.log('âŒ Auth Debug: Invalid password for user:', email);
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }
    console.log('âœ… Auth Debug: Password verified successfully');

    // Generate token
    console.log('ðŸ” Auth Debug: Generating JWT token...');
    const token = generateToken(user._id);
    console.log('âœ… Auth Debug: Token generated successfully');

    // Return user data (password excluded by toJSON method)
    console.log('âœ… Auth Debug: Login completed successfully for:', email);
    res.json({
      success: true,
      message: 'Login successful',
      user: user.toJSON(),
      token
    });
  } catch (error) {
    console.error('âŒ Auth Debug: Login error:', error.message);
    console.error('âŒ Auth Debug: Full error:', error);
    
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// @route   GET /api/auth/me
// @desc    Get current user
// @access  Private
router.get('/me', async (req, res) => {
  console.log('ðŸ” Auth Debug: Get current user request');
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      console.log('âŒ Auth Debug: No token provided');
      return res.status(401).json({
        success: false,
        message: 'Access token required'
      });
    }

    // Verify token
    const jwt = require('jsonwebtoken');
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret');
    console.log('ðŸ” Auth Debug: Token decoded, userId:', decoded.userId);
    
    // Find user in MongoDB database
    const user = await User.findById(decoded.userId);
    if (!user) {
      console.log('âŒ Auth Debug: User not found in database for userId:', decoded.userId);
      return res.status(403).json({
        success: false,
        message: 'User not found'
      });
    }
    
    console.log('âœ… Auth Debug: Returning user data from database');
    res.json({
      success: true,
      user: user.toJSON()
    });
  } catch (error) {
    console.error('âŒ Auth Debug: Get user error:', error.message);
    console.error('âŒ Auth Debug: Full error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// @route   POST /api/auth/logout
// @desc    Logout user (client-side token removal)
// @access  Private
router.post('/logout', authenticateToken, (req, res) => {
  res.json({
    success: true,
    message: 'Logout successful'
  });
});

// @route   GET /api/auth/validate
// @desc    Validate token
// @access  Private
router.get('/validate', authenticateToken, (req, res) => {
  res.json({
    success: true,
    message: 'Token is valid',
    userId: req.userId
  });
});

const nodemailer = require('nodemailer');

router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findByEmail(email);
    const message = 'If an account exists for this email, a reset link has been sent.';

    if (!process.env.SMTP_HOST || !process.env.SMTP_USER || !process.env.SMTP_PASS) {
      return res.status(200).json({ success: true, message });
    }

    if (user) {
      const token = Math.random().toString(36).slice(2) + Math.random().toString(36).slice(2);
      const transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: parseInt(process.env.SMTP_PORT || '587', 10),
        secure: false,
        auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS }
      });

      const resetUrl = `${process.env.FRONTEND_URL || ''}/reset-password?token=${token}`;
      await transporter.sendMail({
        from: process.env.SMTP_FROM || process.env.SMTP_USER,
        to: email,
        subject: 'Password Reset',
        text: `Reset your password using this link: ${resetUrl}`
      });
    }

    res.status(200).json({ success: true, message });
  } catch (error) {
    res.status(200).json({ success: true, message: 'If an account exists for this email, a reset link has been sent.' });
  }
});

// Two-step password reset: check email exists
router.post('/forgot-password-check', [
  body('email').isEmail().normalizeEmail().withMessage('Please provide a valid email')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, message: 'Validation failed', errors: errors.array() });
    }
    const { email } = req.body;
    const user = await User.findByEmail(email);
    if (!user) {
      return res.status(404).json({ success: false, message: 'Invalid email' });
    }
    return res.status(200).json({ success: true, message: 'Email exists' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Two-step password reset: set new password by email
router.post('/reset-password', [
  body('email').isEmail().normalizeEmail().withMessage('Please provide a valid email'),
  body('newPassword')
    .isLength({ min: 5 })
    .withMessage('Password must be at least 5 characters long')
    .matches(/^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{5,}$/)
    .withMessage('Password must include upper, lower, and a number (min 5 chars)')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, message: 'Validation failed', errors: errors.array() });
    }
    const { email, newPassword } = req.body;
    const user = await User.findByEmail(email);
    if (!user) {
      return res.status(404).json({ success: false, message: 'Invalid email' });
    }
    user.password = newPassword;
    await user.save();
    return res.status(200).json({ success: true, message: 'Password updated successfully' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// @route   PUT /api/auth/profile
// @desc    Update user profile
// @access  Private
router.put('/profile', authenticateToken, upload.single('profileImage'), async (req, res) => {
  console.log('ðŸ” Auth Debug: Profile update request for userId:', req.userId);
  try {
    const { name, email } = req.body;
    console.log('ðŸ” Auth Debug: Profile update data:', { name, email, hasFile: !!req.file });

    // Get the current user
    const user = req.user;
    
    // Update fields if provided
    if (name !== undefined) {
      user.name = name.trim();
    }
    if (email !== undefined) {
      // Check if email is already taken by another user
      if (email !== user.email) {
        const existingUser = await User.findByEmail(email);
        if (existingUser && existingUser._id.toString() !== user._id.toString()) {
          console.log('âŒ Auth Debug: Email already taken:', email);
          return res.status(400).json({
            success: false,
            message: 'Email is already taken by another user'
          });
        }
      }
      user.email = email.trim();
    }
    
    // Handle profile image upload
    if (req.file) {
      console.log('ðŸ” Auth Debug: Processing profile image upload...');
      console.log('ðŸ” Auth Debug: File details:', {
        originalname: req.file.originalname,
        mimetype: req.file.mimetype,
        size: req.file.size,
        bufferLength: req.file.buffer?.length
      });
      
      try {
        // Process and optimize image
        console.log('ðŸ” Auth Debug: Starting image processing with Sharp...');
        const processedImageBuffer = await sharp(req.file.buffer)
          .resize(300, 300) // Resize to 300x300 for profile pictures
          .jpeg({ quality: 85 })
          .toBuffer();
        console.log('ðŸ” Auth Debug: Image processing completed');

        // Generate unique filename
        const filename = `profile_${user._id}_${Date.now()}.jpg`;
        const filepath = path.join(uploadsDir, filename);
        console.log('ðŸ” Auth Debug: Generated filename:', filename);
        console.log('ðŸ” Auth Debug: File path:', filepath);
        
        // Save processed image
        console.log('ðŸ” Auth Debug: Saving image to disk...');
        await fs.writeFile(filepath, processedImageBuffer);
        console.log('ðŸ” Auth Debug: Image saved successfully');
        
        // Delete old profile image if it exists
        if (user.profileImage) {
          const oldImagePath = path.join(uploadsDir, path.basename(user.profileImage));
          try {
            await fs.unlink(oldImagePath);
            console.log('ðŸ” Auth Debug: Deleted old profile image');
          } catch (err) {
            console.log('ðŸ” Auth Debug: Could not delete old profile image:', err.message);
          }
        }
        
        // Update user profile image path
        user.profileImage = filename;
        console.log('âœ… Auth Debug: Profile image processed and saved');
      } catch (imageError) {
        console.error('âŒ Auth Debug: Image processing error:', imageError.message);
        console.error('âŒ Auth Debug: Full image error:', imageError);
        throw imageError;
      }
    }

    // Save the updated user
    console.log('ðŸ” Auth Debug: Saving updated user...');
    const updatedUser = await user.save();
    console.log('âœ… Auth Debug: User profile updated successfully');

    res.json({
      success: true,
      message: 'Profile updated successfully',
      user: updatedUser.toJSON()
    });
  } catch (error) {
    console.error('âŒ Auth Debug: Profile update error:', error.message);
    console.error('âŒ Auth Debug: Full error:', error);
    
    // Check for validation errors
    if (error.name === 'ValidationError') {
      console.log('âŒ Auth Debug: MongoDB validation error');
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: Object.values(error.errors).map(err => err.message)
      });
    }
    
    // Check for duplicate key errors
    if (error.code === 11000) {
      console.log('âŒ Auth Debug: MongoDB duplicate key error');
      return res.status(400).json({
        success: false,
        message: 'Email is already taken by another user'
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

module.exports = router;
