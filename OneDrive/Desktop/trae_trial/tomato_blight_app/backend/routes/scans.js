const express = require('express');
const { body, validationResult } = require('express-validator');
const authenticateToken = require('../middleware/auth');
const router = express.Router();

// Mock scan data for demonstration
let scanHistory = [];

// Validation middleware
const scanValidation = [
  body('imagePath').notEmpty().withMessage('Image path is required'),
  body('scanDate').isISO8601().withMessage('Valid scan date is required'),
  body('detections').isArray().withMessage('Detections must be an array')
];

// @route   GET /api/scans/history
// @desc    Get scan history for authenticated user
// @access  Private
router.get('/history', authenticateToken, async (req, res) => {
  try {
    // In a real implementation, this would fetch from database
    // For now, return empty array or mock data
    const userScans = scanHistory.filter(scan => scan.userId === req.user.userId);
    
    res.json({
      success: true,
      scans: userScans,
      total: userScans.length
    });
  } catch (error) {
    console.error('Scan history error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve scan history'
    });
  }
});

// @route   POST /api/scans
// @desc    Save a new scan result
// @access  Private
router.post('/', authenticateToken, scanValidation, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { id, imagePath, scanDate, detections, confidence, metadata } = req.body;
    
    const newScan = {
      id: id || `scan_${Date.now()}`,
      userId: req.user.userId,
      imagePath,
      scanDate,
      detections,
      confidence,
      metadata,
      createdAt: new Date().toISOString()
    };

    // In a real implementation, this would save to database
    scanHistory.push(newScan);
    
    res.status(201).json({
      success: true,
      message: 'Scan result saved successfully',
      scan: newScan
    });
  } catch (error) {
    console.error('Save scan error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to save scan result'
    });
  }
});

// @route   DELETE /api/scans/:id
// @desc    Delete a scan result
// @access  Private
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;
    
    // Find scan index
    const scanIndex = scanHistory.findIndex(scan => 
      scan.id === id && scan.userId === userId
    );
    
    if (scanIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'Scan not found or unauthorized'
      });
    }
    
    // Remove scan
    scanHistory.splice(scanIndex, 1);
    
    res.json({
      success: true,
      message: 'Scan deleted successfully'
    });
  } catch (error) {
    console.error('Delete scan error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete scan'
    });
  }
});

// @route   GET /api/scans/:id
// @desc    Get a specific scan result
// @access  Private
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;
    
    const scan = scanHistory.find(scan => 
      scan.id === id && scan.userId === userId
    );
    
    if (!scan) {
      return res.status(404).json({
        success: false,
        message: 'Scan not found'
      });
    }
    
    res.json({
      success: true,
      scan
    });
  } catch (error) {
    console.error('Get scan error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve scan'
    });
  }
});

module.exports = router;