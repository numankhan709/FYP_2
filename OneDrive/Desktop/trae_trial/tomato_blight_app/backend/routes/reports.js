const express = require('express');
const { body, validationResult } = require('express-validator');
const router = express.Router();

// In-memory storage for reports (replace with database in production)
let reports = [];
let reportIdCounter = 1;

// Helper function to generate report summary
const generateReportSummary = (analysisData, weatherData) => {
  const { detection, diseaseInfo } = analysisData;
  const { weather, riskAssessment } = weatherData;
  
  let summary = `Analysis Report - ${new Date().toLocaleDateString()}\n\n`;
  
  // Disease Detection Summary
  summary += `DISEASE DETECTION RESULTS:\n`;
  summary += `- Detected Condition: ${diseaseInfo.name}\n`;
  summary += `- Confidence Level: ${detection.confidence}%\n\n`;
  
  // Weather Conditions
  if (weather) {
    summary += `WEATHER CONDITIONS:\n`;
    summary += `- Temperature: ${weather.temperature}°C (Feels like ${weather.feelsLike}°C)\n`;
    summary += `- Humidity: ${weather.humidity}%\n`;
    summary += `- Conditions: ${weather.description}\n`;
    summary += `- Location: ${weather.location.name}, ${weather.location.country}\n\n`;
  }
  
  // Risk Assessment
  if (riskAssessment) {
    summary += `RISK ASSESSMENT:\n`;
    summary += `- Risk Level: ${riskAssessment.risk_level}\n`;
    summary += `- Assessment: ${riskAssessment.description}\n\n`;
  }
  
  // Recommendations
  if (diseaseInfo.treatment && diseaseInfo.treatment.length > 0) {
    summary += `IMMEDIATE TREATMENT RECOMMENDATIONS:\n`;
    diseaseInfo.treatment.slice(0, 5).forEach((treatment, index) => {
      summary += `${index + 1}. ${treatment}\n`;
    });
    summary += `\n`;
  }
  
  if (diseaseInfo.prevention && diseaseInfo.prevention.length > 0) {
    summary += `PREVENTION MEASURES:\n`;
    diseaseInfo.prevention.slice(0, 5).forEach((prevention, index) => {
      summary += `${index + 1}. ${prevention}\n`;
    });
    summary += `\n`;
  }
  
  summary += `Report generated on: ${new Date().toLocaleString()}\n`;
  summary += `Tomato Care App - Disease Detection System`;
  
  return summary;
};

// Validation rules
const reportValidation = [
  body('analysisData')
    .isObject()
    .withMessage('Analysis data is required'),
  body('analysisData.detection')
    .isObject()
    .withMessage('Detection data is required'),
  body('analysisData.diseaseInfo')
    .isObject()
    .withMessage('Disease information is required')
];

// @route   POST /api/reports/generate
// @desc    Generate a new analysis report
// @access  Public
router.post('/generate', reportValidation, (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Invalid report data',
        errors: errors.array()
      });
    }

    const { analysisData, weatherData, userNotes } = req.body;
    
    // Generate report summary
    const summary = generateReportSummary(analysisData, weatherData || {});
    
    // Create new report
    const newReport = {
      id: reportIdCounter++,
      analysisData,
      weatherData: weatherData || null,
      userNotes: userNotes || '',
      summary,
      createdAt: new Date().toISOString(),
      type: 'disease_analysis',
      status: 'completed'
    };
    
    reports.push(newReport);
    
    res.status(201).json({
      success: true,
      message: 'Report generated successfully',
      report: {
        id: newReport.id,
        summary: newReport.summary,
        createdAt: newReport.createdAt,
        type: newReport.type,
        status: newReport.status
      }
    });
  } catch (error) {
    console.error('Report generation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to generate report'
    });
  }
});

// @route   GET /api/reports
// @desc    Get list of all reports
// @access  Public
router.get('/', (req, res) => {
  try {
    const { page = 1, limit = 10, type } = req.query;
    
    let filteredReports = reports;
    
    // Filter by type if specified
    if (type) {
      filteredReports = reports.filter(report => report.type === type);
    }
    
    // Sort by creation date (newest first)
    filteredReports.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    
    // Pagination
    const startIndex = (page - 1) * limit;
    const endIndex = startIndex + parseInt(limit);
    const paginatedReports = filteredReports.slice(startIndex, endIndex);
    
    // Return summary data only
    const reportSummaries = paginatedReports.map(report => ({
      id: report.id,
      type: report.type,
      status: report.status,
      createdAt: report.createdAt,
      diseaseDetected: report.analysisData?.diseaseInfo?.name || 'Unknown',
      confidence: report.analysisData?.detection?.confidence || 0,
      riskLevel: report.weatherData?.riskAssessment?.risk_level || 'Unknown'
    }));
    
    res.json({
      success: true,
      reports: reportSummaries,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(filteredReports.length / limit),
        totalReports: filteredReports.length,
        hasNext: endIndex < filteredReports.length,
        hasPrev: startIndex > 0
      }
    });
  } catch (error) {
    console.error('Get reports error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve reports'
    });
  }
});

// @route   GET /api/reports/:id
// @desc    Get detailed report by ID
// @access  Public
router.get('/:id', (req, res) => {
  try {
    const reportId = parseInt(req.params.id);
    
    const report = reports.find(r => r.id === reportId);
    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Report not found'
      });
    }
    
    res.json({
      success: true,
      report
    });
  } catch (error) {
    console.error('Get report error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve report'
    });
  }
});

// @route   GET /api/reports/:id/download
// @desc    Download report as text file
// @access  Public
router.get('/:id/download', (req, res) => {
  try {
    const reportId = parseInt(req.params.id);
    
    const report = reports.find(r => r.id === reportId);
    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Report not found'
      });
    }
    
    // Set headers for file download
    const filename = `tomato_analysis_report_${reportId}_${new Date().toISOString().split('T')[0]}.txt`;
    res.setHeader('Content-Type', 'text/plain');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    
    // Send report summary as downloadable text file
    res.send(report.summary);
  } catch (error) {
    console.error('Download report error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to download report'
    });
  }
});

// @route   DELETE /api/reports/:id
// @desc    Delete a report
// @access  Public
router.delete('/:id', (req, res) => {
  try {
    const reportId = parseInt(req.params.id);
    
    const reportIndex = reports.findIndex(r => r.id === reportId);
    if (reportIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'Report not found'
      });
    }
    
    reports.splice(reportIndex, 1);
    
    res.json({
      success: true,
      message: 'Report deleted successfully'
    });
  } catch (error) {
    console.error('Delete report error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete report'
    });
  }
});

// @route   GET /api/reports/stats/summary
// @desc    Get reports statistics summary
// @access  Public
router.get('/stats/summary', (req, res) => {
  try {
    const totalReports = reports.length;
    
    // Count by disease type
    const diseaseStats = {};
    const riskStats = { 'High Risk': 0, 'Medium Risk': 0, 'Low Risk': 0 };
    
    reports.forEach(report => {
      // Disease statistics
      const diseaseName = report.analysisData?.diseaseInfo?.name || 'Unknown';
      diseaseStats[diseaseName] = (diseaseStats[diseaseName] || 0) + 1;
      
      // Risk level statistics
      const riskLevel = report.weatherData?.riskAssessment?.risk_level || 'Unknown';
      if (riskStats.hasOwnProperty(riskLevel)) {
        riskStats[riskLevel]++;
      }
    });
    
    // Recent activity (last 7 days)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    const recentReports = reports.filter(report => 
      new Date(report.createdAt) >= sevenDaysAgo
    ).length;
    
    res.json({
      success: true,
      stats: {
        totalReports,
        recentReports,
        diseaseDistribution: diseaseStats,
        riskDistribution: riskStats,
        generatedAt: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('Get stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve statistics'
    });
  }
});

module.exports = router;