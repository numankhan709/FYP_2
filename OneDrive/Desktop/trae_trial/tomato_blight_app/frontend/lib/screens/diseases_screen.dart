import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/disease_provider.dart';
import '../models/disease_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/back_arrow.dart';
import '../constants/app_colors.dart';

class DiseasesScreen extends StatefulWidget {
  const DiseasesScreen({super.key});

  @override
  State<DiseasesScreen> createState() => _DiseasesScreenState();
}

class _DiseasesScreenState extends State<DiseasesScreen>
    with SingleTickerProviderStateMixin {
  List<Disease> _diseases = [];
  List<Disease> _filteredDiseases = [];
  bool _isLoading = true;
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDiseases();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
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

  Future<void> _loadDiseases() async {
    try {
      final diseaseProvider = Provider.of<DiseaseProvider>(context, listen: false);
      await diseaseProvider.loadDiseases();
      
      if (mounted) {
        setState(() {
          _diseases = diseaseProvider.diseases;
          _filteredDiseases = _diseases;
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
          'Failed to load diseases information. Please try again.',
        );
      }
    }
  }

  void _filterDiseases() {
    setState(() {
      _filteredDiseases = _diseases.where((disease) {
        final matchesSearch = disease.name
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()) ||
            disease.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            disease.symptoms.any((symptom) =>
                symptom.toLowerCase().contains(_searchQuery.toLowerCase())) ||
            disease.treatments.any((treatment) =>
                treatment.toLowerCase().contains(_searchQuery.toLowerCase()));

        return matchesSearch;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterDiseases();
  }



  void _showDiseaseDetails(Disease disease) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DiseaseDetailSheet(disease: disease),
    );
  }

  Widget _buildDiseaseImage(String assetPath) {
    final lower = assetPath.toLowerCase();
    final isSvg = lower.endsWith('.svg');
    final isRaster = lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.webp');

    if (isSvg) {
      return SvgPicture.asset(
        assetPath,
        height: 120,
        width: 120,
        fit: BoxFit.contain,
      );
    }

    if (isRaster) {
      return Image.asset(
        assetPath,
        height: 120,
        width: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 48, color: Colors.grey);
        },
      );
    }

    // Fallback: try loading as raster first, else show placeholder
    return Image.asset(
      assetPath,
      height: 120,
      width: 120,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.image_not_supported, size: 48, color: Colors.grey);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tomato Diseases',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: const BackArrow(),
      ),
      body: Container(
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
        child: _isLoading
            ? _buildLoadingState()
            : _buildContent(),
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
            'Loading diseases information...',
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
          // Search and Filter Section
          _buildSearchAndFilter(),
          
          // Results Count
          _buildResultsCount(),
          
          // Diseases List
          Expanded(
            child: _filteredDiseases.isEmpty
                ? _buildEmptyState()
                : _buildDiseasesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search diseases, symptoms, treatments...',
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
                borderSide: BorderSide(color: AppColors.neutralLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          
          const SizedBox(height: UIConstants.paddingMedium),
          

        ],
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
            '${_filteredDiseases.length} disease${_filteredDiseases.length != 1 ? 's' : ''} found',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
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
              Icons.search_off,
              size: 80,
              color: AppColors.neutralMedium,
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            const Text(
              'No Diseases Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: UIConstants.paddingSmall),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms or filters'
                  : 'No diseases match the selected criteria',
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.paddingLarge),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
                _filterDiseases();
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseasesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      itemCount: _filteredDiseases.length,
      itemBuilder: (context, index) {
        final disease = _filteredDiseases[index];
        return _buildDiseaseCard(disease, index);
      },
    );
  }

  Widget _buildDiseaseCard(Disease disease, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      margin: const EdgeInsets.only(bottom: UIConstants.paddingMedium),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
        ),
        child: InkWell(
          onTap: () => _showDiseaseDetails(disease),
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Disease Image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(UIConstants.borderRadiusMedium),
                  topRight: Radius.circular(UIConstants.borderRadiusMedium),
                ),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green.shade50,
                        Colors.green.shade100,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: _buildDiseaseImage(disease.imageUrl),
                      ),
                      // Disease name overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(UIConstants.paddingMedium),
                          child: Text(
                            disease.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(UIConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      disease.description,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: UIConstants.paddingMedium),
                    
                    // Quick Info
                    Row(
                      children: [
                        _buildQuickInfo(
                          Icons.visibility,
                          '${disease.symptoms.length} symptoms',
                          Colors.blue,
                        ),
                        const SizedBox(width: UIConstants.paddingMedium),
                        _buildQuickInfo(
                          Icons.healing,
                          '${disease.treatments.length} treatments',
                          Colors.green,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: UIConstants.paddingSmall),
                    
                    // View Details Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showDiseaseDetails(disease),
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('View Details'),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInfo(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }


}

class DiseaseDetailSheet extends StatelessWidget {
  final Disease disease;
  
  const DiseaseDetailSheet({
    super.key,
    required this.disease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutralLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(UIConstants.paddingMedium),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    disease.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(UIConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  _buildDescriptionSection(context, disease),
                  
                  const SizedBox(height: UIConstants.paddingLarge),
                  
                  // Symptoms
                  _buildSection(
                    'Symptoms',
                    Icons.visibility,
                    disease.symptoms,
                  ),
                  
                  const SizedBox(height: UIConstants.paddingLarge),
                  
                  // Treatments
                  _buildSection(
                    'Treatments',
                    Icons.healing,
                    disease.treatments,
                  ),
                  
                  const SizedBox(height: UIConstants.paddingLarge),
                  
                  // Prevention
                  if (disease.prevention.isNotEmpty)
                    _buildSection(
                      'Prevention',
                      Icons.shield,
                      disease.prevention,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.blue.shade600,
            ),
            const SizedBox(width: UIConstants.paddingSmall),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: UIConstants.paddingMedium),
        
        if (items.length == 1 && title == 'Description')
          Text(
            items.first,
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
              fontSize: 16,
            ),
          )
        else
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: UIConstants.paddingSmall),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
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
                    item,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          )),
      ],
    );
  }


}

// Update method signature to accept BuildContext and use dynamic height
Widget _buildDescriptionSection(BuildContext context, Disease disease) {
  final double imageHeight = MediaQuery.of(context).size.height * 0.30; // 30% of screen height
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(
            Icons.description,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: UIConstants.paddingSmall),
          Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      const SizedBox(height: UIConstants.paddingMedium),
      // Disease image from assets, full width and dynamic height
      ClipRRect(
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
        child: _buildDiseaseAssetImage(disease.imageUrl, imageHeight),
      ),
      const SizedBox(height: UIConstants.paddingMedium),
      Text(
        disease.description,
        style: TextStyle(
          color: AppColors.textSecondary,
          height: 1.5,
          fontSize: 16,
        ),
      ),
    ],
  );
}

// Helper to load raster or svg disease image with given height
Widget _buildDiseaseAssetImage(String assetPath, double height) {
  final lower = assetPath.toLowerCase();
  if (lower.endsWith('.svg')) {
    return SvgPicture.asset(
      assetPath,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
  return Image.asset(
    assetPath,
    height: height,
    width: double.infinity,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
      return Container(
        height: height,
        width: double.infinity,
        color: AppColors.neutralLight,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, color: Colors.grey, size: 48),
      );
    },
  );
}