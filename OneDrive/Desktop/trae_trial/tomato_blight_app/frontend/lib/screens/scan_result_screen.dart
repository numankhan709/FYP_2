import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/disease_provider.dart';
import '../models/scan_result_model.dart';
import '../models/disease_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/back_arrow.dart';
import '../constants/app_colors.dart';

class ScanResultScreen extends StatefulWidget {
  final String scanId;
  
  const ScanResultScreen({
    super.key,
    required this.scanId,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen>
    with SingleTickerProviderStateMixin {
  ScanResult? _scanResult;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadScanResult();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadScanResult() async {
    try {
      final diseaseProvider = Provider.of<DiseaseProvider>(context, listen: false);
      final result = await diseaseProvider.getScanResult(widget.scanId);
      
      if (mounted) {
        setState(() {
          _scanResult = result;
          _isLoading = false;
        });
        
        if (result != null) {
          _animationController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ErrorHelper.showErrorSnackBar(
          context,
          'Failed to load scan result. Please try again.',
        );
      }
    }
  }

  Future<void> _generateReport() async {
    if (_scanResult == null) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating PDF report...'),
            ],
          ),
        ),
      );

      final diseaseProvider = Provider.of<DiseaseProvider>(context, listen: false);
      final pdfPath = await diseaseProvider.generatePDFReport(_scanResult!);

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success dialog with options
      _showReportGeneratedDialog(pdfPath);
        } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ErrorHelper.showErrorSnackBar(
          context,
          ErrorHelper.getErrorMessage(e),
        );
      }
    }
  }

  void _showReportGeneratedDialog(String pdfPath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.accentGreen),
            SizedBox(width: 8),
            Text('Report Generated'),
          ],
        ),
        content: const Text(
          'Your scan report has been generated successfully. '
          'You can share it or view it in your device\'s file manager.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _shareReport(pdfPath);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareReport(String pdfPath) async {
    try {
      await Share.shareXFiles(
        [XFile(pdfPath)],
        text: 'Tomato Disease Scan Report - ${DateTimeHelper.formatDate(_scanResult!.scanDate)}',
      );
    } catch (e) {
      if (mounted) {
        ErrorHelper.showErrorSnackBar(
          context,
          'Failed to share report. Please try again.',
        );
      }
    }
  }

  void _retakeScan() {
    context.go(RouteConstants.scan);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan Results',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        leading: const BackArrow(),
        actions: [
          if (_scanResult != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _generateReport(),
              tooltip: 'Generate & Share Report',
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _scanResult == null
              ? _buildErrorState()
              : _buildResultContent(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Colors.white,
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading scan results...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: UIConstants.paddingMedium),
              const Text(
                'Scan Result Not Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: UIConstants.paddingSmall),
              const Text(
                'The scan result could not be loaded.',
                style: TextStyle(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: UIConstants.paddingLarge),
              ElevatedButton(
                onPressed: _retakeScan,
                child: const Text('Take New Scan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Colors.white,
          ],
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(UIConstants.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Preview
                _buildImagePreview(),
                
                const SizedBox(height: UIConstants.paddingLarge),
                
                // Detection Results
                _buildDetectionResults(),
                
                const SizedBox(height: UIConstants.paddingLarge),
                
                // Disease Information
                if (_scanResult!.hasDisease)
                  _buildDiseaseInformation(),
                
                const SizedBox(height: UIConstants.paddingLarge),
                
                // Recommendations
                _buildRecommendations(),
                
                const SizedBox(height: UIConstants.paddingLarge),
                
                // Action Buttons
                _buildActionButtons(),
                

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusLarge),
        child: kIsWeb
            ? Container(
                width: double.infinity,
                height: 200,
                color: AppColors.neutralLight,
                child: const Icon(
                  Icons.image,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
              )
            : Image.file(
                File(_scanResult!.imagePath),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
      ),
    );
  }

  Widget _buildDetectionResults() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _scanResult!.hasDisease ? Icons.warning : Icons.check_circle,
                  color: _scanResult!.hasDisease ? Colors.orange : AppColors.accentGreen,
                ),
                const SizedBox(width: UIConstants.paddingSmall),
                Text(
                  'Detection Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            
            // Overall Status
            Container(
              padding: const EdgeInsets.all(UIConstants.paddingMedium),
              decoration: BoxDecoration(
                color: _scanResult!.hasDisease
                    ? Colors.orange.shade50
                    : AppColors.accentGreenLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusSmall),
                border: Border.all(
                  color: _scanResult!.hasDisease
                      ? Colors.orange.shade200
                      : AppColors.accentGreenLight,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _scanResult!.hasDisease ? Icons.warning : Icons.check_circle,
                    color: _scanResult!.hasDisease ? Colors.orange : AppColors.accentGreen,
                  ),
                  const SizedBox(width: UIConstants.paddingSmall),
                  Expanded(
                    child: Text(
                      _scanResult!.hasDisease
                          ? 'Disease detected in plant'
                          : 'Plant appears healthy',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _scanResult!.hasDisease
                            ? Colors.orange.shade700
                      : AppColors.accentGreenDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            if (_scanResult!.detections.isNotEmpty) ...[
              const SizedBox(height: UIConstants.paddingMedium),
              const Text(
                'Detected Issues:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: UIConstants.paddingSmall),
              
              // Detection List
              ...(_scanResult!.detections.map((detection) => Padding(
                padding: const EdgeInsets.only(bottom: UIConstants.paddingSmall),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(detection.confidence),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: UIConstants.paddingSmall),
                    Expanded(
                      child: Text(
                        detection.diseaseId,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${(detection.confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: _getConfidenceColor(detection.confidence),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ))),
            ],
            
            const SizedBox(height: UIConstants.paddingMedium),
            
            // Scan Info
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Scanned: ${DateTimeHelper.formatDateTime(_scanResult!.scanDate)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseInformation() {
    final primaryDetection = _scanResult!.primaryDetection;
    if (primaryDetection == null) return const SizedBox.shrink();

    // Get plant type from scan result metadata
    final plantType = _scanResult!.metadata?['plant_type'] as String? ?? 'tomato';
    final disease = DiseaseDatabase.getById(primaryDetection.diseaseId);
    if (disease == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                   Icons.local_hospital,
                   color: AppColors.primaryRed, // Using green instead of red
                 ),
                const SizedBox(width: UIConstants.paddingSmall),
                Text(
                  disease.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            
            Text(
              disease.description,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            

          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _scanResult!.hasDisease
        ? [
            'Remove affected plant parts immediately',
            'Apply appropriate fungicide treatment',
            'Improve air circulation around plants',
            'Avoid overhead watering',
            'Monitor other plants for similar symptoms',
          ]
        : [
            'Continue regular plant care routine',
            'Monitor for any changes in plant health',
            'Maintain proper watering schedule',
            'Ensure adequate nutrition',
            'Regular inspection for early detection',
          ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: UIConstants.paddingSmall),
                Text(
                  'Recommendations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            
            ...recommendations.map((recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: UIConstants.paddingSmall),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: UIConstants.paddingSmall),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Generate Report Button
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _generateReport,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text(
              'Generate PDF Report',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
              ),
              elevation: 2,
            ),
          ),
        ),
        
        const SizedBox(height: UIConstants.paddingMedium),
        
        // Secondary Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _retakeScan,
                icon: const Icon(Icons.camera_alt),
                label: const Text('New Scan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
                  ),
                ),
              ),
            ),
            const SizedBox(width: UIConstants.paddingMedium),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go(RouteConstants.home),
                icon: const Icon(Icons.home),
                label: const Text('Home'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  side: BorderSide(color: Colors.grey[400]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return AppColors.primaryRed; // Using green instead of red
    if (confidence >= 0.6) return AppColors.warningLight;
    return AppColors.tertiaryLight;
  }


}