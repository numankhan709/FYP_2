import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/weather_provider.dart';
import '../providers/disease_provider.dart';
import '../widgets/back_arrow.dart';
import '../widgets/tomato_gradient_scaffold.dart';
import '../utils/constants.dart';
import '../constants/app_colors.dart';

class RiskAssessmentScreen extends StatefulWidget {
  const RiskAssessmentScreen({super.key});

  @override
  State<RiskAssessmentScreen> createState() => _RiskAssessmentScreenState();
}

class _RiskAssessmentScreenState extends State<RiskAssessmentScreen> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRiskAssessment();
    });
  }

  Future<void> _loadRiskAssessment() async {
    if (mounted) {
      setState(() {
        _isInitializing = true;
      });
    }
    
    try {
      final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
      final diseaseProvider = Provider.of<DiseaseProvider>(context, listen: false);
      
      // Clear any previous errors by triggering a refresh
      
      // Load weather data and assess disease risk
      await Future.wait([
        weatherProvider.assessDiseaseRisk(),
        diseaseProvider.loadDiseases(),
      ]);
    } catch (e) {
      print('Error loading risk assessment: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TomatoGradientScaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Consumer2<WeatherProvider, DiseaseProvider>(
              builder: (context, weatherProvider, diseaseProvider, child) {
                if (_isInitializing || weatherProvider.isLoading || diseaseProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                }

                if (weatherProvider.errorMessage != null || diseaseProvider.errorMessage != null) {
                  return _buildErrorState(weatherProvider, diseaseProvider);
                }

                return _buildRiskAssessmentContent(weatherProvider, diseaseProvider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(UIConstants.paddingLarge),
      child: Column(
        children: [
          const SizedBox(height: UIConstants.paddingMedium),
          Row(
            children: [
              BackArrow(
                onPressed: () => context.go(RouteConstants.home),
                color: Colors.white,
              ),
              const SizedBox(width: UIConstants.paddingMedium),
              const Expanded(
                child: Text(
                  'Disease Risk Assessment',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: UIConstants.paddingSmall),
          const Text(
            'Weather-based disease risk analysis for your crops',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(WeatherProvider weatherProvider, DiseaseProvider diseaseProvider) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(UIConstants.paddingLarge),
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.primaryRed, // Using green instead of red
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            const Text(
              'Unable to Load Risk Assessment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: UIConstants.paddingSmall),
            Text(
              weatherProvider.errorMessage ?? diseaseProvider.errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: UIConstants.paddingLarge),
            ElevatedButton(
              onPressed: _loadRiskAssessment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed, // Using green instead of red
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: UIConstants.paddingLarge,
                  vertical: UIConstants.paddingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAssessmentContent(WeatherProvider weatherProvider, DiseaseProvider diseaseProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(UIConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallRiskCard(weatherProvider),
          const SizedBox(height: UIConstants.paddingLarge),
          _buildWeatherConditionsCard(weatherProvider),
          const SizedBox(height: UIConstants.paddingLarge),
          _buildDiseaseSpecificRisks(weatherProvider, diseaseProvider),
          const SizedBox(height: UIConstants.paddingLarge),
          _buildRecommendationsCard(weatherProvider),
        ],
      ),
    );
  }

  Widget _buildOverallRiskCard(WeatherProvider weatherProvider) {
    final riskAssessment = weatherProvider.currentRiskAssessment;
    final riskLevel = riskAssessment?['risk_level'] ?? 'Unknown';
    Color riskColor;
    switch (riskLevel) {
       case 'High':
         riskColor = AppColors.primaryRed; // Using green instead of red
         break;
      case 'Medium':
        riskColor = Colors.orange;
        break;
      default:
        riskColor = Colors.green;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusLarge),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusLarge),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              riskColor.withValues(alpha: 0.1),
              riskColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assessment,
                  color: AppColors.accentGreen,
                  size: UIConstants.iconSizeLarge,
                ),
                const SizedBox(width: UIConstants.paddingMedium),
                const Expanded(
                  child: Text(
                    'Overall Risk Level',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.paddingLarge,
                vertical: UIConstants.paddingMedium,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentGreenDark,
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
              ),
              child: Text(
                '$riskLevel Risk',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            Text(
              riskAssessment?['description'] ?? 'Risk assessment data unavailable',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherConditionsCard(WeatherProvider weatherProvider) {
    final weather = weatherProvider.currentWeather;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.cloud,
                  color: Colors.blue,
                  size: UIConstants.iconSizeLarge,
                ),
                SizedBox(width: UIConstants.paddingMedium),
                Text(
                  'Current Weather Conditions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingLarge),
            if (weather != null) ...[
              _buildWeatherRow('Temperature', '${weather.temperature.toStringAsFixed(1)}°C'),
              _buildWeatherRow('Humidity', '${weather.humidity.toStringAsFixed(1)}%'),
              _buildWeatherRow('Conditions', weather.description),
              _buildWeatherRow('Wind Speed', '${weather.windSpeed.toStringAsFixed(1)} m/s'),
            ] else
              const Text(
                'Weather data unavailable',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseSpecificRisks(WeatherProvider weatherProvider, DiseaseProvider diseaseProvider) {
    final diseases = diseaseProvider.diseases;
    final weather = weatherProvider.currentWeather;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: Colors.orange,
                  size: UIConstants.iconSizeLarge,
                ),
                SizedBox(width: UIConstants.paddingMedium),
                Text(
                  'Disease-Specific Risks',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingLarge),
            if (diseases.isNotEmpty && weather != null) ...[
              ...diseases.map((disease) => _buildDiseaseRiskItem(disease, weather)),
            ] else
              const Text(
                'Disease risk data unavailable',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseRiskItem(dynamic disease, dynamic weather) {
    // Calculate risk based on weather conditions
    final riskLevel = _calculateDiseaseRisk(disease, weather);
    Color riskColor;
    switch (riskLevel) {
       case 'High':
         riskColor = AppColors.primaryRed; // Using green instead of red
         break;
      case 'Medium':
        riskColor = Colors.orange;
        break;
      default:
        riskColor = Colors.green;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.paddingMedium),
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.accentGreenLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.accentGreenLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disease['name'] ?? 'Unknown Disease',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: UIConstants.paddingSmall),
                Text(
                  _getDiseaseRiskDescription(riskLevel),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: UIConstants.paddingMedium,
              vertical: UIConstants.paddingSmall,
            ),
            decoration: BoxDecoration(
              color: riskColor,
              borderRadius: BorderRadius.circular(UIConstants.borderRadiusSmall),
            ),
            child: Text(
              riskLevel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(WeatherProvider weatherProvider) {
    final riskAssessment = weatherProvider.currentRiskAssessment;
    final recommendations = riskAssessment?['recommendations'] as List<dynamic>? ?? [];
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Colors.amber,
                  size: UIConstants.iconSizeLarge,
                ),
                SizedBox(width: UIConstants.paddingMedium),
                Text(
                  'Recommendations',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingLarge),
            if (recommendations.isNotEmpty) ...[
              ...recommendations.map((rec) => _buildRecommendationItem(rec.toString())),
            ] else ...[
              _buildRecommendationItem('Monitor your plants regularly for signs of disease'),
              _buildRecommendationItem('Ensure proper air circulation around plants'),
              _buildRecommendationItem('Avoid overhead watering during humid conditions'),
              _buildRecommendationItem('Apply preventive treatments if risk is high'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(String recommendation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UIConstants.paddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: UIConstants.paddingMedium),
          Expanded(
            child: Text(
              recommendation,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateDiseaseRisk(dynamic disease, dynamic weather) {
    final temperature = weather.temperature;
    final humidity = weather.humidity;
    
    // Simple risk calculation based on weather conditions
    // This can be enhanced with more sophisticated algorithms
    
    if (humidity > 80 && temperature > 20 && temperature < 30) {
      return 'High';
    } else if (humidity > 60 && temperature > 15 && temperature < 35) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }

  String _getDiseaseRiskDescription(String riskLevel) {
    switch (riskLevel) {
      case 'High':
        return 'Weather conditions are highly favorable for disease development';
      case 'Medium':
        return 'Moderate risk - monitor plants closely';
      case 'Low':
        return 'Low risk - current conditions not favorable for disease';
      default:
        return 'Risk level unknown';
    }
  }
}