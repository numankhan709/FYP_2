import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/disease_provider.dart';
import '../models/scan_result_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../constants/app_colors.dart';
import '../widgets/back_arrow.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;
  List<ScanResult> _scanHistory = [];
  String _searchQuery = '';
  List<ScanResult> _filteredHistory = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadScanHistory();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadScanHistory() async {
    try {
      final diseaseProvider = Provider.of<DiseaseProvider>(context, listen: false);
      await diseaseProvider.loadScanHistory();
      
      if (mounted) {
        setState(() {
          _scanHistory = diseaseProvider.scanHistory;
          _filteredHistory = _scanHistory;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ErrorHelper.showErrorSnackBar(
          context,
          'Failed to load scan history. Please try again.',
        );
      }
    }
  }

  void _filterHistory() {
    setState(() {
      _filteredHistory = _scanHistory.where((scan) {
        final query = _searchQuery.toLowerCase();
        return scan.detections.any((detection) =>
            detection.diseaseName.toLowerCase().contains(query)) ||
            DateTimeHelper.formatDate(scan.scanDate).toLowerCase().contains(query);
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterHistory();
  }

  void _viewScanResult(ScanResult scan) {
    context.go('${RouteConstants.scanResult}?scanId=${scan.id}');
  }

  Future<void> _deleteScan(ScanResult scan) async {
    final diseaseProvider = Provider.of<DiseaseProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scan'),
        content: const Text(
          'Are you sure you want to delete this scan result? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed, // Using green instead of red
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await diseaseProvider.deleteScanResult(scan.id);
        
        setState(() {
          _scanHistory.removeWhere((s) => s.id == scan.id);
          _filterHistory();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Scan deleted successfully'),
              backgroundColor: AppColors.primaryRed,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ErrorHelper.showErrorSnackBar(
            context,
            'Failed to delete scan. Please try again.',
          );
        }
      }
    }
  }

  Future<void> _refreshHistory() async {
    setState(() {
      _isLoading = true;
    });
    await _loadScanHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: const BackArrow(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshHistory,
            tooltip: 'Refresh',
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.8),
                Colors.orange.shade600,
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: _isLoading
            ? _buildLoadingState()
            : _buildContent(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(RouteConstants.scan),
        tooltip: 'New Scan',
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading scan history...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Search Section
          _buildSearchSection(),
          
          // Results Count
          _buildResultsCount(),
          
          // History List
          Expanded(
            child: _filteredHistory.isEmpty
                ? _buildEmptyState()
                : _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search by disease or date...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.paddingMedium,
        vertical: UIConstants.paddingSmall,
      ),
      child: Row(
        children: [
          Text(
            '${_filteredHistory.length} scan${_filteredHistory.length != 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const Text(' • ', style: TextStyle(color: AppColors.textSecondary)),
            Text(
              'filtered from ${_scanHistory.length}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ]
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
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.history,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching scans found'
                  : 'No scan history yet',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: UIConstants.paddingSmall),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'Start by scanning your first plant',
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.paddingLarge),
            ElevatedButton.icon(
              onPressed: () => context.go(RouteConstants.scan),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Start Scanning'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return RefreshIndicator(
      onRefresh: _refreshHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        itemCount: _filteredHistory.length,
        itemBuilder: (context, index) {
          final scan = _filteredHistory[index];
          return _buildScanItem(scan, index);
        },
      ),
    );
  }

  Widget _buildScanItem(ScanResult scan, int index) {
    final primaryDetection = scan.detections.isNotEmpty
        ? scan.detections.first
        : null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: UIConstants.paddingMedium),
      child: InkWell(
        onTap: () => _viewScanResult(scan),
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.paddingMedium),
          child: Row(
            children: [
              // Scan Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(UIConstants.borderRadiusSmall),
                  color: AppColors.neutralLight,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(UIConstants.borderRadiusSmall),
                  child: scan.imagePath.isNotEmpty
                      ? kIsWeb
                          ? const Icon(
                              Icons.image,
                              color: AppColors.textSecondary,
                            )
                          : Image.file(
                              File(scan.imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.image_not_supported,
                                  color: AppColors.textSecondary,
                                );
                              },
                            )
                      : const Icon(
                          Icons.image,
                          color: AppColors.textSecondary,
                        ),
                ),
              ),
              
              const SizedBox(width: UIConstants.paddingMedium),
              
              // Scan Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primaryDetection?.diseaseName ?? 'Unknown Disease',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateTimeHelper.formatDate(scan.scanDate),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${NumberHelper.formatPercentage(scan.confidence)} confidence',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      _viewScanResult(scan);
                      break;
                    case 'delete':
                      _deleteScan(scan);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility),
                        SizedBox(width: 8),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.primaryRed),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.primaryRed)),
                      ],
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
}