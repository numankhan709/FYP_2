import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/disease_provider.dart';
import '../models/scan_result_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../constants/app_colors.dart';
import '../widgets/tomato_gradient_scaffold.dart';
import '../widgets/back_arrow.dart';
import '../services/pdf_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    // Load scan history when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DiseaseProvider>(context, listen: false).loadScanHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LightTomatoGradientScaffold(
      body: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Content
          Expanded(
            child: Consumer<DiseaseProvider>(
              builder: (context, diseaseProvider, child) {
                if (diseaseProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final scanHistory = diseaseProvider.scanHistory;
                
                if (scanHistory.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildReportsList(scanHistory);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: isDark 
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDark,
                AppColors.primaryDark.withOpacity(0.8),
                AppColors.secondaryDark.withOpacity(0.6),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(UIConstants.borderRadiusLarge),
              bottomRight: Radius.circular(UIConstants.borderRadiusLarge),
            ),
          )
        : BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryLight,
                AppColors.accentGoldLight.withOpacity(0.8),
                AppColors.secondaryLight.withOpacity(0.6),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(UIConstants.borderRadiusLarge),
              bottomRight: Radius.circular(UIConstants.borderRadiusLarge),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
      padding: const EdgeInsets.all(UIConstants.paddingLarge),
      child: Column(
        children: [
          const SizedBox(height: UIConstants.paddingLarge),
          Row(
            children: [
              BackArrow(
                onPressed: () => context.go(RouteConstants.home),
              ),
              const SizedBox(width: UIConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'View and download your scan reports',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              // Add filter/sort icon for better functionality
              IconButton(
                onPressed: _showFilterOptions,
                icon: const Icon(
                  Icons.filter_list,
                  color: Colors.white,
                ),
                tooltip: 'Filter Reports',
              ),
            ],
          ),
          const SizedBox(height: UIConstants.paddingMedium),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: UIConstants.paddingLarge),
            Text(
              'No Reports Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            Text(
              'Start scanning your tomato plants to generate reports',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: UIConstants.paddingLarge),
            ElevatedButton.icon(
              onPressed: () => context.go(RouteConstants.scan),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Start Scanning'),
              style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed, // Using green instead of red
                foregroundColor: AppColors.neutralWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: UIConstants.paddingLarge,
                  vertical: UIConstants.paddingMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsList(List<ScanResult> scanHistory) {
    return ListView.builder(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      itemCount: scanHistory.length,
      itemBuilder: (context, index) {
        final scan = scanHistory[index];
        return _buildReportCard(scan);
      },
    );
  }

  Widget _buildReportCard(ScanResult scan) {
    final primaryDetection = scan.primaryDetection;
    final diseaseType = primaryDetection?.diseaseName ?? 'Unknown';
    final diseaseColor = _getDiseaseColor(diseaseType);
    final confidenceColor = _getConfidenceColor(scan.confidence);
    
    return Card(
      margin: const EdgeInsets.only(bottom: UIConstants.paddingMedium),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
        onTap: () => _showReportDetails(scan),
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with date and confidence
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateTimeHelper.formatDate(scan.scanDate),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: UIConstants.paddingSmall,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: confidenceColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(UIConstants.borderRadiusSmall),
                      border: Border.all(color: confidenceColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      '${scan.confidence.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: confidenceColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: UIConstants.paddingMedium),
              
              // Disease information
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: diseaseColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: UIConstants.paddingSmall),
                  Expanded(
                    child: Text(
                    diseaseType,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ),
                ],
              ),
              
              if (scan.notes != null && scan.notes!.isNotEmpty) ...[
                const SizedBox(height: UIConstants.paddingSmall),
                Text(
                  scan.notes!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: UIConstants.paddingMedium),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showReportDetails(scan),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryRed, // Using green instead of red
                    ),
                  ),
                  const SizedBox(width: UIConstants.paddingSmall),
                  ElevatedButton.icon(
                    onPressed: () => _downloadReport(scan),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('PDF'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed, // Using green instead of red
                      foregroundColor: AppColors.neutralWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: UIConstants.paddingMedium,
                        vertical: UIConstants.paddingSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDetails(ScanResult scan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildReportDetailsModal(scan),
    );
  }

  Widget _buildReportDetailsModal(ScanResult scan) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(UIConstants.borderRadiusLarge),
          topRight: Radius.circular(UIConstants.borderRadiusLarge),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: UIConstants.paddingSmall),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutralLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(UIConstants.paddingLarge),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Report Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: UIConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scan image if available
                  if (scan.imagePath.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
                      child: Image.network(
                        scan.imagePath,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: AppColors.neutralLight,
                          child: const Icon(Icons.image_not_supported, size: 50),
                        ),
                      ),
                    ),
                    const SizedBox(height: UIConstants.paddingLarge),
                  ],
                  
                  // Disease information
                  _buildDetailSection('Disease Detected', scan.primaryDetection?.diseaseName ?? 'Unknown'),
                  _buildDetailSection('Confidence Level', '${(scan.confidence * 100).toStringAsFixed(1)}%'),
                  _buildDetailSection('Scan Date', DateTimeHelper.formatDateTime(scan.scanDate)),
                  
                  if (scan.notes != null && scan.notes!.isNotEmpty)
                    _buildDetailSection('Notes', scan.notes!),
                  
                  const SizedBox(height: UIConstants.paddingLarge),
                  
                  // Download button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _downloadReport(scan);
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download PDF Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed, // Using green instead of red
                        foregroundColor: AppColors.neutralWhite,
                        padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingMedium),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: UIConstants.paddingLarge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UIConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Future<void> _downloadReport(ScanResult scan) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generating PDF...'),
          ],
        ),
      ),
    );

    try {
      // Generate PDF using the PDF service
      final pdfPath = await PDFService.generateScanReport(scan);
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show options dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 8),
                Text('PDF Generated!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your scan report has been saved successfully.'),
                SizedBox(height: 8),
                Text(
                  'Location: Downloads/TomatoCare/',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _shareReport(pdfPath);
                },
                icon: Icon(Icons.share),
                label: Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.neutralWhite,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show error message
        ErrorHelper.showErrorSnackBar(
          context,
          'Failed to generate PDF report. Please try again.',
        );
      }
    }
  }

  Future<void> _shareReport(String pdfPath) async {
    try {
      await PDFService.sharePDF(pdfPath);
    } catch (e) {
      if (mounted) {
        ErrorHelper.showErrorSnackBar(
          context,
          'Failed to share report. Please try again.',
        );
      }
    }
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(UIConstants.borderRadiusLarge),
            topRight: Radius.circular(UIConstants.borderRadiusLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: UIConstants.paddingSmall),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutralMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(UIConstants.paddingLarge),
              child: Text(
                'Filter & Sort Reports',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Filter options
            ListTile(
              leading: const Icon(Icons.sort),
              title: const Text('Sort by Date'),
              subtitle: const Text('Newest first'),
              onTap: () {
                Navigator.pop(context);
                // Implement sorting logic
              },
            ),
            ListTile(
              leading: const Icon(Icons.filter_alt),
              title: const Text('Filter by Disease'),
              subtitle: const Text('Show specific diseases'),
              onTap: () {
                Navigator.pop(context);
                // Implement disease filtering
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Filter by Date Range'),
              subtitle: const Text('Select date range'),
              onTap: () {
                Navigator.pop(context);
                // Implement date range filtering
              },
            ),
            
            const SizedBox(height: UIConstants.paddingLarge),
          ],
        ),
      ),
    );
  }

  Color _getDiseaseColor(String diseaseType) {
    if (diseaseType.toLowerCase().contains('healthy')) {
      return Colors.green;
    } else if (diseaseType.toLowerCase().contains('blight')) {
      return AppColors.primaryRed; // Using app's primary green color
    } else if (diseaseType.toLowerCase().contains('spot')) {
      return Colors.orange;
    } else if (diseaseType.toLowerCase().contains('wilt')) {
      return Colors.purple;
    } else {
      return AppColors.textSecondary;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.6) {
      return Colors.orange;
    } else {
      return AppColors.primaryRed; // Using app's primary green color
    }
  }
}