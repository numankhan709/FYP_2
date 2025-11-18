import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/disease_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/tomato_gradient_scaffold.dart';
import '../widgets/back_arrow.dart';
import '../constants/app_colors.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isAnalyzing = false;
  String _selectedPlantType = 'tomato';
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    final cameraPermission = await Permission.camera.request();
    final storagePermission = await Permission.storage.request();
    
    if (!cameraPermission.isGranted || !storagePermission.isGranted) {
      if (mounted) {
        ErrorHelper.showErrorSnackBar(
          context,
          'Camera and storage permissions are required for scanning.',
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      await _requestPermissions();
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        await _processSelectedImage(file);
      }
    } catch (e) {
      if (mounted) {
        ErrorHelper.showErrorSnackBar(
          context,
          'Failed to capture image. Please try again.',
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      await _requestPermissions();
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        await _processSelectedImage(file);
      }
    } catch (e) {
      if (mounted) {
        ErrorHelper.showErrorSnackBar(
          context,
          'Failed to select image. Please try again.',
        );
      }
    }
  }

  Future<void> _processSelectedImage(File imageFile) async {
    // Validate image file
    if (!FileHelper.isValidImageFile(imageFile)) {
      ErrorHelper.showErrorSnackBar(
        context,
        'Please select a valid image file (JPG, JPEG, PNG).',
      );
      return;
    }

    final isValidSize = await FileHelper.isFileSizeValid(imageFile);
    if (!isValidSize && mounted) {
      ErrorHelper.showErrorSnackBar(
        context,
        'Image file is too large. Please select an image smaller than 10MB.',
      );
      return;
    }

    setState(() {
      _selectedImage = imageFile;
    });
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final diseaseProvider = Provider.of<DiseaseProvider>(context, listen: false);
      final scanResult = await diseaseProvider.scanImage(_selectedImage!, plantType: _selectedPlantType);

      if (!mounted) return;

      if (scanResult != null) {
        // Navigate to scan result screen
        context.go('${RouteConstants.scanResult}?scanId=${scanResult.id}');
      } else {
        ErrorHelper.showErrorSnackBar(
          context,
          'Failed to analyze image. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHelper.showErrorSnackBar(
          context,
          ErrorHelper.getErrorMessage(e),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return LightTomatoGradientScaffold(
      appBar: AppBar(
        title: Text(
          'Scan Plant',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark 
              ? AppColors.textDark 
              : AppColors.neutralWhite,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: isDark 
          ? AppColors.textDark 
          : AppColors.neutralWhite,
        elevation: 0,
        leading: const BackArrow(),
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearImage,
              tooltip: 'Clear image',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
              isDark 
                ? AppColors.backgroundDark 
                : AppColors.backgroundLight,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(UIConstants.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instructions
                _buildInstructions(),
                
                const SizedBox(height: UIConstants.paddingLarge),
                
                // Plant Type Selection
                _buildPlantTypeSelection(),
                
                const SizedBox(height: UIConstants.paddingLarge),
                
                // Image Preview or Placeholder
                SizedBox(
                  height: 260,
                  child: _selectedImage != null
                      ? _buildImagePreview()
                      : _buildImagePlaceholder(),
                ),
                
                const SizedBox(height: UIConstants.paddingLarge),
                
                // Action Buttons
                if (_selectedImage == null)
                  _buildCaptureButtons()
                else
                  _buildAnalyzeButton(),
                
                
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade600,
                size: UIConstants.iconSizeMedium,
              ),
              const SizedBox(width: UIConstants.paddingSmall),
              Text(
                'Scanning Tips',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: UIConstants.paddingSmall),
          Text(
            '• Take clear, well-lit photos of affected plant parts\n'
            '• Focus on leaves showing disease symptoms\n'
            '• Avoid blurry or dark images\n'
            '• Include multiple affected areas if possible',
            style: TextStyle(
              color: Colors.blue.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(UIConstants.borderRadiusLarge),
              border: Border.all(
                color: AppColors.neutralLight,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 80,
                  color: AppColors.neutralMedium,
                ),
                const SizedBox(height: UIConstants.paddingMedium),
                Text(
                  'No Image Selected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: UIConstants.paddingSmall),
                Text(
                  'Capture or select an image to analyze',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePreview() {
    return Container(
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
                _selectedImage!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
      ),
    );
  }

  Widget _buildCaptureButtons() {
    return Column(
      children: [
        // Camera Button
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _pickImageFromCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text(
              'Take Photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: AppColors.neutralWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
              ),
              elevation: 2,
            ),
          ),
        ),
        
        const SizedBox(height: UIConstants.paddingMedium),
        
        // Gallery Button
        SizedBox(
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _pickImageFromGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text(
              'Choose from Gallery',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
              side: BorderSide(color: Theme.of(context).primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return Column(
      children: [
        // Image Info
        Container(
          padding: const EdgeInsets.all(UIConstants.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
          ),
          child: Row(
            children: [
              Icon(
                Icons.image,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: UIConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Image Ready for Analysis',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FutureBuilder<int>(
                      future: _selectedImage!.length(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            'Size: ${FileHelper.formatFileSize(snapshot.data!)}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: UIConstants.paddingMedium),
        
        // Analyze Button
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : _analyzeImage,
            icon: _isAnalyzing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.neutralWhite),
                    ),
                  )
                : const Icon(Icons.analytics),
            label: Text(
              _isAnalyzing ? 'Analyzing...' : 'Analyze Plant',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: AppColors.neutralWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
              ),
              elevation: 2,
            ),
          ),
        ),
        
        const SizedBox(height: UIConstants.paddingMedium),
        
        // Retake Button
        TextButton.icon(
          onPressed: _isAnalyzing ? null : _clearImage,
          icon: const Icon(Icons.refresh),
          label: const Text('Retake Photo'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPlantTypeSelection() {
    return Container(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.primaryRed),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.eco,
                color: AppColors.primaryRed,
                size: UIConstants.iconSizeMedium,
              ),
              const SizedBox(width: UIConstants.paddingSmall),
              Text(
                'Plant Type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: UIConstants.paddingMedium),
          Row(
            children: [
              Expanded(
                child: _buildPlantTypeOption(
                  'tomato',
                  'Tomato',
                  Icons.local_florist,
                  AppColors.primaryRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlantTypeOption(String value, String label, IconData icon, Color color) {
    final isSelected = _selectedPlantType == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlantType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusSmall),
          border: Border.all(
            color: isSelected ? color : AppColors.neutralLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textSecondary,
              size: UIConstants.iconSizeLarge,
            ),
            const SizedBox(height: UIConstants.paddingSmall),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}