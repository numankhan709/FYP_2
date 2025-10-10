import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/tomato_logo.dart';
import '../widgets/back_arrow.dart';
import '../constants/app_colors.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _animationController.forward();
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

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ErrorHelper.showErrorSnackBar(
          context,
          'Could not open the link. Please try again.',
        );
      }
    }
  }

  void _showLicenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Source Licenses'),
        content: const SingleChildScrollView(
          child: Text(
            'This app uses the following open source packages:\n\n'
            '• Flutter SDK - BSD 3-Clause License\n'
            '• Provider - MIT License\n'
            '• HTTP - BSD 3-Clause License\n'
            '• Shared Preferences - BSD 3-Clause License\n'
            '• Image Picker - Apache 2.0 License\n'
            '• Permission Handler - MIT License\n'
            '• Geolocator - MIT License\n'
            '• Go Router - BSD 3-Clause License\n'
            '• PDF - Apache 2.0 License\n'
            '• Share Plus - BSD 3-Clause License\n'
            '• URL Launcher - BSD 3-Clause License\n\n'
            'Full license texts are available in the app repository.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark 
              ? const Color(0xFFE0E0E0) 
              : Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: isDark 
          ? const Color(0xFFE0E0E0) 
          : Colors.white,
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
              isDark 
                ? const Color(0xFF1E1E1E) 
                : Colors.white,
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App Logo and Name
                  _buildAppHeader(),
                  
                  const SizedBox(height: UIConstants.paddingLarge),
                  
                  // App Description
                  _buildAppDescription(),
                  
                  const SizedBox(height: UIConstants.paddingLarge),
                  
                  // Features Section
                  _buildFeaturesSection(),
                  
                  const SizedBox(height: UIConstants.paddingLarge),
                  
                  // Technology Stack
                  _buildTechnologySection(),
                  
                  const SizedBox(height: UIConstants.paddingLarge),
                  
                  // Contact and Links
                  _buildContactSection(),
                  
                  const SizedBox(height: UIConstants.paddingLarge),
                  
                  // App Info
                  _buildAppInfo(),
                  

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppHeader() {
    return Column(
      children: [
        // App Icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const TomatoIconFallback(
            size: 50,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: UIConstants.paddingMedium),
        
        // App Name
        Text(
          AppConstants.appName,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: UIConstants.paddingSmall),
        
        // App Tagline
        Text(
          AppConstants.appTagline,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAppDescription() {
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
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: UIConstants.paddingSmall),
                Text(
                  'About the App',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            Text(
              'TomatoCare is an advanced mobile application designed to help farmers, '
              'gardeners, and agricultural enthusiasts detect and manage tomato plant diseases. '
              'Using cutting-edge image recognition technology combined with real-time weather data, '
              'our app provides comprehensive plant health analysis and actionable recommendations.\n\n'
              'Whether you\'re a professional farmer managing large crops or a home gardener '
              'caring for a few plants, TomatoCare empowers you with the knowledge and tools '
              'needed to maintain healthy tomato plants and maximize your harvest.',
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.6,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.camera_alt,
        'title': 'Smart Disease Detection',
        'description': 'Capture or upload plant images for instant AI-powered disease analysis',
        'color': Colors.blue,
      },
      {
        'icon': Icons.cloud,
        'title': 'Weather Integration',
        'description': 'Real-time weather data and location-based disease risk assessment',
        'color': Colors.orange,
      },
      {
        'icon': Icons.local_hospital,
        'title': 'Disease Database',
        'description': 'Comprehensive information on tomato diseases, symptoms, and treatments',
        'color': AppColors.primaryRed, // Using green instead of red
      },
      {
        'icon': Icons.picture_as_pdf,
        'title': 'PDF Reports',
        'description': 'Generate detailed reports of your plant health assessments',
        'color': Colors.green,
      },
      {
        'icon': Icons.history,
        'title': 'Scan History',
        'description': 'Track your plant health over time with detailed scan history',
        'color': Colors.purple,
      },
      {
        'icon': Icons.security,
        'title': 'Secure & Private',
        'description': 'Your data is protected with industry-standard security measures',
        'color': Colors.teal,
      },
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
                  Icons.star,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: UIConstants.paddingSmall),
                Text(
                  'Key Features',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: UIConstants.paddingMedium),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (feature['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      color: feature['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: UIConstants.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature['title'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feature['description'] as String,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
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

  Widget _buildTechnologySection() {
    final technologies = [
      {'name': 'Flutter', 'description': 'Cross-platform mobile development'},
      {'name': 'Node.js', 'description': 'Backend server and API'},
      {'name': 'AI/ML', 'description': 'Image recognition and disease detection'},
      {'name': 'OpenWeather API', 'description': 'Real-time weather data'},
      {'name': 'GPS Location', 'description': 'Location-based services'},
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
                  Icons.code,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: UIConstants.paddingSmall),
                Text(
                  'Technology Stack',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            
            ...technologies.map((tech) => Padding(
              padding: const EdgeInsets.only(bottom: UIConstants.paddingSmall),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: UIConstants.paddingSmall),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                        children: [
                          TextSpan(
                            text: '${tech['name']}: ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: tech['description']),
                        ],
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

  Widget _buildContactSection() {
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
                  Icons.contact_support,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: UIConstants.paddingSmall),
                Text(
                  'Contact & Support',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            
            // Contact Options
            _buildContactItem(
              Icons.email,
              'Email Support',
              'support@tomatocare.app',
              () => _launchUrl('mailto:support@tomatocare.app'),
            ),
            
            _buildContactItem(
              Icons.web,
              'Website',
              'www.tomatocare.app',
              () => _launchUrl('https://www.tomatocare.app'),
            ),
            
            _buildContactItem(
              Icons.code,
              'Source Code',
              'GitHub Repository',
              () => _launchUrl('https://github.com/tomatocare/app'),
            ),
            
            _buildContactItem(
              Icons.gavel,
              'Open Source Licenses',
              'View licenses',
              _showLicenseDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(UIConstants.borderRadiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: UIConstants.paddingSmall,
          horizontal: UIConstants.paddingSmall,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: UIConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Version',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  AppConstants.appVersion,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Build',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${AppConstants.appVersion}.${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Platform',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Flutter',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}