const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

console.log('🔍 User Model Debug: Loading User model...');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true,
    minlength: [2, 'Name must be at least 2 characters long'],
    maxlength: [50, 'Name must be less than 50 characters']
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    validate: {
      validator: function(email) {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
      },
      message: 'Please provide a valid email address'
    }
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [6, 'Password must be at least 6 characters long']
  },
  profileImage: {
    type: String,
    default: null
  },
  role: {
    type: String,
    enum: ['user', 'admin'],
    default: 'user'
  },
  isActive: {
    type: Boolean,
    default: true
  },
  lastLogin: {
    type: Date
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Pre-save middleware to hash password
userSchema.pre('save', async function(next) {
  console.log('🔍 User Model Debug: Pre-save middleware triggered for user:', this.email);
  
  // Only hash the password if it has been modified (or is new)
  if (!this.isModified('password')) {
    console.log('🔍 User Model Debug: Password not modified, skipping hash');
    return next();
  }

  try {
    console.log('🔍 User Model Debug: Hashing password...');
    // Hash password with cost of 12
    const saltRounds = 12;
    this.password = await bcrypt.hash(this.password, saltRounds);
    console.log('✅ User Model Debug: Password hashed successfully');
    next();
  } catch (error) {
    console.error('❌ User Model Debug: Error hashing password:', error);
    next(error);
  }
});

// Instance method to check password
userSchema.methods.comparePassword = async function(candidatePassword) {
  console.log('🔍 User Model Debug: Comparing password for user:', this.email);
  try {
    const isMatch = await bcrypt.compare(candidatePassword, this.password);
    console.log('🔍 User Model Debug: Password comparison result:', isMatch ? 'Match' : 'No match');
    return isMatch;
  } catch (error) {
    console.error('❌ User Model Debug: Error comparing password:', error);
    throw error;
  }
};

// Instance method to update last login
userSchema.methods.updateLastLogin = function() {
  console.log('🔍 User Model Debug: Updating last login for user:', this.email);
  this.lastLogin = new Date();
  return this.save();
};

// Static method to find user by email
userSchema.statics.findByEmail = function(email) {
  console.log('🔍 User Model Debug: Finding user by email:', email);
  return this.findOne({ email: email.toLowerCase() });
};

// Remove password from JSON output
userSchema.methods.toJSON = function() {
  const userObject = this.toObject();
  delete userObject.password;
  return userObject;
};

// Create indexes
userSchema.index({ email: 1 }, { unique: true });
userSchema.index({ createdAt: 1 });

console.log('✅ User Model Debug: User schema created successfully');

const User = mongoose.model('User', userSchema);

console.log('✅ User Model Debug: User model exported successfully');

module.exports = User;