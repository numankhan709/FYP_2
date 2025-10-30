import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/disease_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/tomato_gradient_scaffold.dart';
import '../widgets/back_arrow.dart';
import '../widgets/location_selection_dialog.dart';
// Removed unused LoadingSplashScreen import as we now use a standard loading dialog
import '../constants/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    final diseaseProvider = Provider.of<DiseaseProvider>(context, listen: false);
    
    // Initialize weather and location
    await weatherProvider.initializeLocation();
    
    // Load diseases and scan history
    await diseaseProvider.loadDiseases();
    await diseaseProvider.loadScanHistory();
  }

  Future<void> _refreshData() async {
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    await weatherProvider.refreshWeatherData();
  }

  String _getProfileImageUrl(String? profileImage) {
    if (profileImage == null) return '';
    // Add timestamp and hash to prevent caching issues
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash = profileImage.hashCode;
    // Use the correct base URL from ApiConstants instead of hardcoded localhost
    final baseUrl = ApiConstants.baseUrl.replaceAll('/api', '');
    return '$baseUrl/uploads/profiles/$profileImage?t=$timestamp&h=$hash';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return LightTomatoGradientScaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Section
              _buildTopHeader(),
              
              // Main Content with padding
              Padding(
                padding: const EdgeInsets.all(UIConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Weather Card
                    _buildWeatherCard(),

              const SizedBox(height: UIConstants.paddingLarge),

              // Quick Actions
              _buildQuickActions(),

              const SizedBox(height: UIConstants.paddingLarge),

              // Weather Alerts
              _buildAlertsSection(),

              const SizedBox(height: UIConstants.paddingLarge),

              // Risk Assessment Card
              _buildRiskAssessmentCard(),
              
              const SizedBox(height: UIConstants.paddingLarge),
              
              // Recent Scans
              _buildRecentScans(),
              
              const SizedBox(height: UIConstants.paddingLarge),
              
                    // Disease Information
                    _buildDiseaseInfo(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: _buildDrawer(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAlertsSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        final alerts = weatherProvider.weatherAlerts;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weather Alerts',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(UIConstants.darkTextColorValue)
                        : const Color(UIConstants.textColorValue),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await Provider.of<WeatherProvider>(context, listen: false)
                        .fetchWeatherAlerts(limit: 20);
                  },
                  child: const Text('Refresh'),
                ),
                if (kDebugMode)
                  PopupMenuButton<String>(
                    tooltip: 'Simulate weather (debug)',
                    onSelected: (value) async {
                      final wp = Provider.of<WeatherProvider>(context, listen: false);
                      switch (value) {
                        case 'cool_rainy':
                          await wp.simulateWeatherConditions(
                            temperature: 17.0,
                            humidity: 96,
                            description: 'moderate rain',
                            cloudiness: 90,
                            windSpeed: 3.0,
                            pressure: 1012.0,
                          );
                          break;
                        case 'warm_humid':
                          await wp.simulateWeatherConditions(
                            temperature: 28.0,
                            humidity: 88,
                            description: 'humid clouds',
                            cloudiness: 65,
                            windSpeed: 2.5,
                            pressure: 1008.0,
                          );
                          break;
                        case 'dry_sunny':
                          await wp.simulateWeatherConditions(
                            temperature: 33.0,
                            humidity: 35,
                            description: 'clear sky',
                            cloudiness: 10,
                            windSpeed: 4.0,
                            pressure: 1015.0,
                          );
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'cool_rainy',
                        child: Text('Simulate: Cool Rainy'),
                      ),
                      const PopupMenuItem(
                        value: 'warm_humid',
                        child: Text('Simulate: Warm Humid'),
                      ),
                      const PopupMenuItem(
                        value: 'dry_sunny',
                        child: Text('Simulate: Dry Sunny'),
                      ),
                    ],
                    child: const Icon(Icons.science, color: Colors.white70),
                  ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            if (alerts.isEmpty)
              _buildEmptyState(
                'No alerts',
                'Weather not favorable for disease spread currently',
                Icons.notifications_none,
                () async {
                  await Provider.of<WeatherProvider>(context, listen: false)
                      .fetchWeatherAlerts(limit: 20);
                },
              )
            else
              ...alerts.take(3).map((alert) => _buildAlertItem(alert)),
          ],
        );
      },
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert) {
    Color severityColor;
    switch ((alert['severity'] ?? 'low').toString().toLowerCase()) {
      case 'high':
        severityColor = Colors.redAccent;
        break;
      case 'medium':
        severityColor = Colors.orangeAccent;
        break;
      default:
        severityColor = Colors.green;
    }

    final createdAtStr = alert['createdAt'] as String?;
    DateTime? createdAt;
    try {
      if (createdAtStr != null) {
        createdAt = DateTime.parse(createdAtStr);
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.paddingSmall),
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            foregroundDecoration: BoxDecoration(color: severityColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: UIConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (alert['message'] as String?) ??
                      "Disease '${alert['diseaseName'] ?? 'Unknown'}' spread, check your plant",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.local_florist,
                      color: severityColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (alert['diseaseName'] as String?) ?? 'Unknown disease',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (createdAt != null)
                      Text(
                        DateTimeHelper.formatRelativeTime(createdAt),
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
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AppBar(
      title: Text(
        AppConstants.appName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark 
            ? const Color(UIConstants.darkTextColorValue) 
            : Colors.white,
          fontSize: 20,
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(UIConstants.primaryColorValue), // Tomato Red
              Color(UIConstants.primaryColorValue).withOpacity(0.8), // Lighter Tomato Red
              Color(UIConstants.accentColorValue).withOpacity(0.3), // Golden Yellow accent
              Color(UIConstants.secondaryColorValue), // Forest Green
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      foregroundColor: isDark 
        ? const Color(UIConstants.darkTextColorValue) 
        : Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false, // Remove hamburger menu

      leading: const BackArrow(),
      actions: [
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.currentUser;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  Scaffold.of(context).openDrawer();
                },
                child: CircleAvatar(
                  backgroundColor: isDark 
                    ? const Color(UIConstants.darkBackgroundColorValue) 
                    : Colors.white,
                  backgroundImage: user?.profileImage != null
                      ? NetworkImage(_getProfileImageUrl(user!.profileImage))
                      : null,
                  onBackgroundImageError: user?.profileImage != null
                      ? (exception, stackTrace) {
                          print('Error loading profile image: $exception');
                        }
                      : null,
                  child: user?.profileImage == null
                      ? Text(
                          (user?.name ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            color: Color(UIConstants.primaryColorValue),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // TODO: Implement notifications
            ErrorHelper.showErrorSnackBar(
              context,
              'Notifications feature coming soon!',
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final firstName = user?.name.split(' ').first ?? 'User';
        
        return SizedBox(
          height: 200,
          child: Stack(
            children: [
              // Curved Background
              ClipPath(
                clipper: CurvedHeaderClipper(),
                child: Container(
                  height: 180,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                       begin: Alignment.topLeft,
                       end: Alignment.bottomRight,
                       colors: [
                         Color(0xFF228B22), // Primary forest green
                         Color(0xFF006400), // Darker forest green  
                         Color(0xFF004000), // Deep forest green
                       ],
                       stops: [0.0, 0.5, 1.0],
                     ),
                  ),
                ),
              ),
              // Content
              Positioned(
                top: 50,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left side - Greeting
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome $firstName',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark 
                                ? const Color(0xFFE0E0E0) 
                                : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Save your tomatoes\nwith us',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark 
                                ? const Color(0xFFB0B0B0) 
                                : Colors.white,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Right side - Profile Icon
                    GestureDetector(
                      onTap: () {
                        // Open the drawer which contains settings options
                        Scaffold.of(context).openDrawer();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark 
                            ? const Color(0xFF2D2D2D).withOpacity(0.4)
                            : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person,
                          color: isDark 
                            ? const Color(0xFFE0E0E0) 
                            : Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        );
      },
    );
  }



  Widget _buildWelcomeCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.secondaryLight,
            AppColors.tertiaryLight.withOpacity(0.8),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDark 
                ? const Color(UIConstants.darkBackgroundColorValue) 
                : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.eco,
              color: Color(UIConstants.secondaryColorValue),
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tomato Disease Classification',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Keep your crops healthy with AI-powered disease detection',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(UIConstants.darkTextColorValue) : const Color(UIConstants.textColorValue),
          ),
        ),
        const SizedBox(height: UIConstants.paddingMedium),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.camera_alt,
                title: 'Scan Plant',
                subtitle: 'Detect diseases',
                color: Color(UIConstants.primaryColorValue), // Tomato Red
                onTap: () => context.push(RouteConstants.scan),
              ),
            ),
            const SizedBox(width: UIConstants.paddingMedium),
            Expanded(
              child: _buildActionCard(
                icon: Icons.history,
                title: 'Scan History',
                subtitle: 'View past scans',
                color: Color(UIConstants.secondaryColorValue), // Forest Green
                onTap: () => context.push(RouteConstants.history),
              ),
            ),
          ],
        ),
        const SizedBox(height: UIConstants.paddingMedium),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.local_hospital,
                title: 'Diseases',
                subtitle: 'Learn about diseases',
                color: Color(UIConstants.accentColorValue), // Golden Yellow
                onTap: () => context.push(RouteConstants.diseases),
              ),
            ),
            const SizedBox(width: UIConstants.paddingMedium),
            Expanded(
              child: _buildActionCard(
                icon: Icons.picture_as_pdf,
                title: 'Reports',
                subtitle: 'Generate PDF reports',
                color: Color(UIConstants.primaryColorValue).withOpacity(0.7), // Light Tomato Red
                onTap: () => context.push(RouteConstants.reports),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    // Use theme color instead of hardcoded color
    final headerColor = AppColors.primaryLight;
    
    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;
        
        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) => setState(() => isPressed = false),
          onTapCancel: () => setState(() => isPressed = false),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(UIConstants.paddingMedium),
            decoration: BoxDecoration(
              color: isPressed ? headerColor : Colors.white,
              borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
              border: Border.all(
                color: headerColor, 
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: headerColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPressed ? Colors.white.withValues(alpha: 0.2) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPressed ? Colors.white : headerColor,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: UIConstants.iconSizeLarge,
                    color: isPressed ? Colors.white : headerColor,
                  ),
                ),
                const SizedBox(height: UIConstants.paddingSmall),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isPressed ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isPressed ? Colors.white.withValues(alpha: 0.9) : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeatherCard() {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        if (weatherProvider.isLoading) {
          return _buildLoadingCard('Loading weather data...');
        }

        final weather = weatherProvider.currentWeather;
        if (weather == null) {
          return _buildErrorCard(
            'Weather data unavailable',
            'Tap to retry',
            () => weatherProvider.refreshWeatherData(),
          );
        }

        return GestureDetector(
          onTap: () => context.push(RouteConstants.weather),
          child: Container(
            padding: const EdgeInsets.all(UIConstants.paddingLarge),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(UIConstants.backgroundColorValue),
                  Color(UIConstants.accentColorValue).withOpacity(0.1),
                  Color(UIConstants.primaryColorValue).withOpacity(0.1),
                  Color(UIConstants.secondaryColorValue).withOpacity(0.1),
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
              borderRadius: BorderRadius.circular(UIConstants.borderRadiusLarge),
              boxShadow: [
                BoxShadow(
                    color: Color(UIConstants.primaryColorValue).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Weather',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(UIConstants.primaryColorValue),
                      ),
                    ),
                    Icon(
                      Icons.wb_sunny,
                      color: Color(UIConstants.accentColorValue),
                      size: UIConstants.iconSizeMedium,
                    ),
                  ],
                ),
                const SizedBox(height: UIConstants.paddingMedium),
                
                // Location row with tap functionality
                GestureDetector(
                  onTap: () => _showLocationSelectionDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Color(UIConstants.primaryColorValue),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            weatherProvider.currentLocation ?? 'Unknown Location',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(UIConstants.primaryColorValue),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit,
                          size: 12,
                          color: Color(UIConstants.primaryColorValue).withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: UIConstants.paddingMedium),
                Row(
                  children: [
                    Text(
                      NumberHelper.formatTemperature(weather.temperature),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(UIConstants.primaryColorValue),
                      ),
                    ),
                    const SizedBox(width: UIConstants.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            StringHelper.capitalizeWords(weather.description),
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.primaryRed, // Using green instead of red
                            ),
                          ),
                          Text(
                            'Humidity: ${NumberHelper.formatHumidity(weather.humidity.toDouble())}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.primaryRed, // Using green instead of red
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRiskAssessmentCard() {
    return Consumer2<WeatherProvider, DiseaseProvider>(
      builder: (context, weatherProvider, diseaseProvider, child) {
        if (weatherProvider.isLoading || diseaseProvider.isLoading) {
          return _buildLoadingCard('Analyzing disease risk...');
        }

        final riskAssessment = weatherProvider.currentRiskAssessment;
        if (riskAssessment == null) {
          return _buildErrorCard(
            'Risk assessment unavailable',
            'Tap to generate',
            () => weatherProvider.assessDiseaseRisk(),
          );
        }

        final riskLevel = riskAssessment['risk_level'] ?? 'Unknown';
        final riskColor = ColorHelper.getRiskLevelColor(riskLevel);

        return GestureDetector(
          onTap: () => context.push(RouteConstants.riskAssessment),
          child: Container(
            padding: const EdgeInsets.all(UIConstants.paddingLarge),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(UIConstants.borderRadiusLarge),
              border: Border.all(color: riskColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Disease Risk Assessment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.warning_amber_rounded,
                      color: riskColor,
                      size: UIConstants.iconSizeMedium,
                    ),
                  ],
                ),
                const SizedBox(height: UIConstants.paddingMedium),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: UIConstants.paddingMedium,
                        vertical: UIConstants.paddingSmall,
                      ),
                      decoration: BoxDecoration(
                        color: riskColor,
                        borderRadius: BorderRadius.circular(
                          UIConstants.borderRadiusSmall,
                        ),
                      ),
                      child: Text(
                        '$riskLevel Risk',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: UIConstants.paddingMedium),
                    const Expanded(
                      child: Text(
                        'Tap for detailed recommendations',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentScans() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Consumer<DiseaseProvider>(
      builder: (context, diseaseProvider, child) {
        final recentScans = diseaseProvider.scanHistory.take(3).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Scans',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(UIConstants.darkTextColorValue) : const Color(UIConstants.textColorValue),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(RouteConstants.history),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            if (recentScans.isEmpty)
              _buildEmptyState(
                'No scans yet',
                'Start by scanning your first plant',
                Icons.camera_alt,
                () => context.push(RouteConstants.scan),
              )
            else
              ...recentScans.map((scan) => _buildScanItem(scan)),
          ],
        );
      },
    );
  }

  Widget _buildScanItem(dynamic scan) {
    // This would be properly typed with ScanResult model
    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.paddingSmall),
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(UIConstants.borderRadiusSmall),
            ),
            child: Icon(
              Icons.local_florist,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: UIConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plant Scan',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateTimeHelper.formatRelativeTime(DateTime.now()),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseInfo() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Disease Information',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            TextButton(
              onPressed: () => context.push(RouteConstants.diseases),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: UIConstants.paddingMedium),
        GestureDetector(
          onTap: () => context.push(RouteConstants.diseases),
          child: Container(
            padding: const EdgeInsets.all(UIConstants.paddingLarge),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade400,
                  Colors.orange.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(UIConstants.borderRadiusLarge),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.menu_book,
                  color: Colors.white,
                  size: UIConstants.iconSizeLarge,
                ),
                const SizedBox(width: UIConstants.paddingMedium),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Learn About Tomato Diseases',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Symptoms, causes, and treatments',
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(String message) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusLarge),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: UIConstants.paddingMedium),
          Text(message),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        decoration: BoxDecoration(
          color: AppColors.accentGreenLight, // Using green instead of red
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusLarge),
          border: Border.all(color: AppColors.accentGreen), // Using green instead of red
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.primaryRed, // Using green instead of red
            ),
            const SizedBox(width: UIConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryRed, // Using green instead of red
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.accentGreenDark, // Using green instead of red
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusLarge),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: UIConstants.iconSizeXLarge,
              color: Colors.grey[400],
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        return Drawer(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
            children: [
              // Drawer Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF228B22), Color(0xFF32CD32)], // Forest green gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                       duration: const Duration(milliseconds: 200),
                       curve: Curves.easeInOut,
                       child: GestureDetector(
                         onTap: () {
                           Navigator.pop(context);
                           _openProfilePage();
                         },
                         child: Builder(
                           builder: (context) {
                             return CircleAvatar(
                               key: ValueKey('drawer_avatar_${user?.profileImage ?? 'default'}'),
                               radius: 35,
                               backgroundColor: Colors.white,
                               backgroundImage: user?.profileImage != null
                                   ? NetworkImage(_getProfileImageUrl(user!.profileImage))
                                   : null,
                               onBackgroundImageError: user?.profileImage != null
                                   ? (exception, stackTrace) {
                                       print('Error loading drawer profile image: $exception');
                                     }
                                   : null,
                               child: user?.profileImage == null
                                   ? Text(
                                       (user?.name ?? 'U')[0].toUpperCase(),
                                       style: TextStyle(
                                         fontSize: 24,
                                         fontWeight: FontWeight.bold,
                                         color: AppColors.primaryLight,
                                       ),
                                     )
                                   : null,
                             );
                           }
                         ),
                       ),
                     ),
                    const SizedBox(height: 15),
                    Text(
                      user?.name ?? 'Guest User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user?.email ?? 'guest@example.com',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Menu Items
               Expanded(
                 child: AnimatedList(
                   padding: EdgeInsets.zero,
                   initialItemCount: 7,
                   itemBuilder: (context, index, animation) {
                     return SlideTransition(
                       position: animation.drive(
                         Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                           .chain(CurveTween(curve: Curves.easeInOut)),
                       ),
                       child: FadeTransition(
                         opacity: animation,
                         child: _getDrawerItem(index),
                       ),
                     );
                   },
                 ),
               ),
             ],
           ),
         ),
         );
       },
     );
   }

   Widget _getDrawerItem(int index) {
     switch (index) {
       case 0:
         return _buildDrawerItem(
           icon: Icons.person,
           title: 'Profile',
           onTap: () {
             Navigator.pop(context);
             _openProfilePage();
           },
         );
       case 1:
         return _buildDrawerItem(
           icon: Icons.home,
           title: 'Home',
           onTap: () {
             Navigator.pop(context);
           },
         );
       case 2:
         return Consumer<ThemeProvider>(
           builder: (context, themeProvider, child) {
             return _buildDrawerItem(
               icon: themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
               title: 'Theme',
               subtitle: themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
               onTap: () {
                 _showThemeSelectionDialog(context);
               },
             );
           },
         );
       case 3:
         return _buildDrawerItem(
           icon: Icons.picture_as_pdf,
           title: 'Report',
           onTap: () {
             Navigator.pop(context);
             context.push(RouteConstants.reports);
           },
         );
       case 4:
         return _buildDrawerItem(
           icon: Icons.info_outline,
           title: 'About',
           onTap: () {
             Navigator.pop(context);
             _showAboutDialog();
           },
         );
       case 5:
         return const Divider();
       case 6:
         return _buildDrawerItem(
           icon: Icons.logout,
           title: 'Logout',
           color: AppColors.primaryRed, // Using green instead of red
           onTap: () async {
             final navigator = Navigator.of(context);
             final goRouter = GoRouter.of(context);
             final authProvider = Provider.of<AuthProvider>(context, listen: false);
             await authProvider.logout();
             if (mounted) {
               navigator.pop();
               goRouter.go(RouteConstants.login);
             }
           },
         );
       default:
         return const SizedBox.shrink();
     }
   }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? const Color(0xFF228B22), // Forest green
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    );
  }

  void _showAboutDialog() {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('About TomatoCare'),
         content: const Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(
               'TomatoCare is an AI-powered mobile application designed to help farmers and gardeners detect and manage tomato plant diseases.',
               style: TextStyle(fontSize: 14),
             ),
             SizedBox(height: 16),
             Text(
               'Features:',
               style: TextStyle(fontWeight: FontWeight.bold),
             ),
             Text('• AI-powered disease detection'),
             Text('• Weather monitoring'),
             Text('• Risk assessment'),
             Text('• Treatment recommendations'),
             Text('• Scan history tracking'),
             SizedBox(height: 16),
             Text(
               'Version: 1.0.0',
               style: TextStyle(fontSize: 12, color: Colors.grey),
             ),
           ],
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

   void _openProfilePage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileEditModal(),
    );
  }

   void _changeProfilePicture() {
     showModalBottomSheet(
       context: context,
       builder: (context) => SafeArea(
         child: Wrap(
           children: [
             ListTile(
               leading: const Icon(Icons.photo_library),
               title: const Text('Choose from Gallery'),
               onTap: () {
                 Navigator.pop(context);
                 // TODO: Implement gallery picker
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Gallery picker coming soon!')),
                 );
               },
             ),
             ListTile(
               leading: const Icon(Icons.photo_camera),
               title: const Text('Take Photo'),
               onTap: () {
                 Navigator.pop(context);
                 // TODO: Implement camera
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Camera coming soon!')),
                 );
               },
             ),
             ListTile(
               leading: const Icon(Icons.delete, color: AppColors.primaryRed), // Using green instead of red
               title: const Text('Remove Photo'),
               onTap: () {
                 Navigator.pop(context);
                 // TODO: Implement remove photo
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Photo removed!')),
                 );
               },
             ),
           ],
         ),
       ),
     );
   }

   void _editProfile() {
     // TODO: Implement profile editing
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('Profile editing coming soon!')),
     );
   }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => context.push(RouteConstants.scan),
      backgroundColor: const Color(0xFF228B22), // Forest green
      child: const Icon(
        Icons.camera_alt,
        color: Colors.white,
      ),
    );
  }

  void _showLocationSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LocationSelectionDialog(),
    );
  }
}

// Custom clipper for curved header
class CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 10);
    
    // Create a smooth curve (flipped direction)
    final firstControlPoint = Offset(size.width * 0.25, size.height - 40);
    final firstEndPoint = Offset(size.width * 0.5, size.height - 20);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    
    final secondControlPoint = Offset(size.width * 0.75, size.height);
    final secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class ProfileEditModal extends StatefulWidget {
  const ProfileEditModal({super.key});

  @override
  _ProfileEditModalState createState() => _ProfileEditModalState();
}

class _ProfileEditModalState extends State<ProfileEditModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;
  
  // Variables to track original values for change detection
  String _originalName = '';
  String? _originalImagePath;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    _addChangeListeners();
  }

  void _initializeUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      _nameController.text = user.name;
      // Store original values
      _originalName = user.name;
      _originalImagePath = user.profileImage;
    }
  }

  void _addChangeListeners() {
    _nameController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final nameChanged = _nameController.text.trim() != _originalName;
    final imageChanged = _selectedImage != null || (_selectedImage == null && _originalImagePath != null);
    
    final hasChanges = nameChanged || imageChanged;
    
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkForChanges);
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        _checkForChanges(); // Check for changes after image selection
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  String _getProfileImageUrl(String? profileImage) {
    if (profileImage == null) return '';
    // Add timestamp and hash to prevent caching issues
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash = profileImage.hashCode;
    // Use the correct base URL from ApiConstants instead of hardcoded localhost
    final baseUrl = ApiConstants.baseUrl.replaceAll('/api', '');
    return '$baseUrl/uploads/profiles/$profileImage?t=$timestamp&h=$hash';
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.primaryRed), // Using green instead of red
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                  });
                  _checkForChanges(); // Check for changes after image removal
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Show loading splash screen as full-screen overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Updating Profile',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please wait while we save your changes...',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Add a minimum delay to show the loading screen
      await Future.wait([
        authProvider.updateProfile(
          name: _nameController.text.trim(),
          email: null, // Don't allow email changes
          profileImage: _selectedImage,
        ),
        Future.delayed(const Duration(milliseconds: 1500)), // Minimum loading time
      ]);

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        
        // Update original values after successful save
        _originalName = _nameController.text.trim();
        if (_selectedImage != null) {
          _originalImagePath = _selectedImage!.path;
        }
        
        // Reset change tracking
        setState(() {
          _hasChanges = false;
        });
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppColors.primaryRed, // Using green instead of red
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 20,
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
          const Divider(),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Picture Section
                    Center(
                      child: Stack(
                        children: [
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              final user = authProvider.currentUser;
                              return CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: _selectedImage != null
                                    ? FileImage(_selectedImage!)
                                    : (user?.profileImage != null
                                        ? NetworkImage(_getProfileImageUrl(user!.profileImage))
                                        : null),
                                onBackgroundImageError: _selectedImage == null && user?.profileImage != null
                                    ? (exception, stackTrace) {
                                        print('Error loading profile edit image: $exception');
                                      }
                                    : null,
                                child: _selectedImage == null && user?.profileImage == null
                                    ? Text(
                                        (user?.name ?? 'U')[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              );
                            },
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _showImageSourceDialog,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(UIConstants.primaryColorValue),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF228B22), // Forest green
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 30),
                    // Save Button - Only show when there are changes
                    if (_hasChanges)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(UIConstants.primaryColorValue),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

void _showThemeSelectionDialog(BuildContext ctx) {
  showDialog(
    context: ctx,
    builder: (dialogContext) {
      return Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final ThemeMode selectedMode = themeProvider.isDarkMode
              ? ThemeMode.dark
              : (themeProvider.isLightMode ? ThemeMode.light : ThemeMode.light);
          return AlertDialog(
            title: const Text('Choose Theme'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: selectedMode,
                  title: const Text('Light'),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (mode) async {
                    if (mode != null) {
                      await themeProvider.setThemeMode(mode);
                      Navigator.of(dialogContext).pop();
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: selectedMode,
                  title: const Text('Dark'),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (mode) async {
                    if (mode != null) {
                      await themeProvider.setThemeMode(mode);
                      Navigator.of(dialogContext).pop();
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    },
  );
}