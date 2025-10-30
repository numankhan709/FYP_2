import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/weather_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/tomato_gradient_scaffold.dart';
import '../../widgets/back_arrow.dart';
import '../../widgets/location_selection_dialog.dart';
import '../../constants/app_colors.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshWeather();
    });
  }

  Future<void> _refreshWeather() async {
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    await weatherProvider.refreshWeatherData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return LightTomatoGradientScaffold(
      appBar: AppBar(
        title: Text(
          'Weather & Risk Assessment',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshWeather,
            tooltip: 'Refresh weather data',
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
                ? const Color(0xFF1E1E1E) 
                : Colors.white,
            ],
          ),
        ),
        child: Consumer<WeatherProvider>(
          builder: (context, weatherProvider, child) {
            if (weatherProvider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: UIConstants.paddingMedium),
                    Text('Loading weather data...'),
                  ],
                ),
              );
            }

            if (weatherProvider.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.primaryRed, // Using green instead of red
                    ),
                    const SizedBox(height: UIConstants.paddingMedium),
                    Text(
                      weatherProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.accentGreenDark, // Using green instead of red
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: UIConstants.paddingLarge),
                    ElevatedButton.icon(
                      onPressed: _refreshWeather,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refreshWeather,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(UIConstants.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Location Info
                    _buildLocationCard(weatherProvider),
                    
                    const SizedBox(height: UIConstants.paddingLarge),
                    
                    // Current Weather
                    _buildCurrentWeatherCard(weatherProvider),
                    
                    const SizedBox(height: UIConstants.paddingLarge),
                    
                    // Disease Risk Assessment
                    _buildRiskAssessmentCard(weatherProvider),
                    
                    const SizedBox(height: UIConstants.paddingLarge),
                    
                    // Weather Details
                    _buildWeatherDetailsCard(weatherProvider),
                    
                    const SizedBox(height: UIConstants.paddingLarge),
                    
                    // 5-Day Forecast
                    _buildForecastCard(weatherProvider),
                    

                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocationCard(WeatherProvider weatherProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: Theme.of(context).primaryColor,
              size: UIConstants.iconSizeMedium,
            ),
            const SizedBox(width: UIConstants.paddingMedium),
            Expanded(
              child: GestureDetector(
                onTap: () => _showLocationSelectionDialog(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Location',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            weatherProvider.currentLocation ?? 'Unknown Location',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.edit_location_alt,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  onPressed: weatherProvider.isLoading
                      ? null
                      : () => weatherProvider.refreshLocation(),
                  tooltip: 'Refresh Location',
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(DateTime.now()),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? AppColors.textSecondaryDark 
                        : AppColors.textSecondary,
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

  Widget _buildCurrentWeatherCard(WeatherProvider weatherProvider) {
    final weather = weatherProvider.currentWeather;
    if (weather == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
              Theme.of(context).primaryColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weather.temperature.round()}°C',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      weather.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Icon(
                      _getWeatherIcon(weather.description),
                      size: 64,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: UIConstants.paddingSmall),
                    Text(
                      'Feels like ${weather.feelsLike.round()}°C',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAssessmentCard(WeatherProvider weatherProvider) {
    final mlAvailable = weatherProvider.hasMlResult;
    final predictedLabel = weatherProvider.mlPredictedLabel;
    final topProb = weatherProvider.mlTopProbability;
    final fallbackRisk = weatherProvider.backendRiskLevel ?? weatherProvider.weatherRiskLevel;
    final riskLevel = fallbackRisk;
    
    Color riskColor;
    IconData riskIcon;
    
    switch (riskLevel) {
      case 'High':
        riskColor = AppColors.primaryRed; // Using green instead of red
        riskIcon = Icons.warning;
        break;
      case 'Medium':
        riskColor = Colors.orange;
        riskIcon = Icons.info;
        break;
      default:
        riskColor = Colors.green;
        riskIcon = Icons.check_circle;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
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
                  riskIcon,
                  color: riskColor,
                  size: UIConstants.iconSizeMedium,
                ),
                const SizedBox(width: UIConstants.paddingMedium),
                Text(
                  'Disease Risk Assessment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: riskColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.paddingMedium,
                vertical: UIConstants.paddingSmall,
              ),
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusSmall),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    mlAvailable && predictedLabel != null
                        ? 'Model: $predictedLabel${topProb != null ? ' (${(topProb * 100).toStringAsFixed(1)}%)' : ''}'
                        : 'Heuristic: $riskLevel',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            Text(
              mlAvailable && predictedLabel != null
                  ? 'Model-based assessment available. Fallback risk: $riskLevel.'
                  : _getRiskDescription(riskLevel),
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? AppColors.textSecondaryDark 
                    : AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetailsCard(WeatherProvider weatherProvider) {
    final weather = weatherProvider.currentWeather;
    if (weather == null) return const SizedBox.shrink();

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
            const Text(
              'Weather Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            Row(
              children: [
                Expanded(
                  child: _buildWeatherDetail(
                    'Humidity',
                    '${weather.humidity}%',
                    Icons.water_drop,
                  ),
                ),
                Expanded(
                  child: _buildWeatherDetail(
                    'Wind Speed',
                    '${weather.windSpeed} m/s',
                    Icons.air,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            Row(
              children: [
                Expanded(
                  child: _buildWeatherDetail(
                    'Pressure',
                    '${weather.pressure} hPa',
                    Icons.speed,
                  ),
                ),
                Expanded(
                  child: _buildWeatherDetail(
                    'UV Index',
                    weather.uvIndex.toString(),
                    Icons.wb_sunny,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.neutralLight,
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusSmall),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: UIConstants.iconSizeSmall,
          ),
          const SizedBox(height: UIConstants.paddingSmall),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? AppColors.textDark : AppColors.textLight,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard(WeatherProvider weatherProvider) {
    final forecast = weatherProvider.forecast;
    if (forecast.isEmpty) return const SizedBox.shrink();

    // Group forecast by day
    final Map<String, List<dynamic>> dailyForecast = {};
    for (final weather in forecast.take(40)) { // 5 days * 8 forecasts per day
      final day = DateFormat('MMM dd').format(weather.dateTime);
      if (!dailyForecast.containsKey(day)) {
        dailyForecast[day] = [];
      }
      dailyForecast[day]!.add(weather);
    }

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
            const Text(
              '5-Day Forecast',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: dailyForecast.length,
                itemBuilder: (context, index) {
                  final day = dailyForecast.keys.elementAt(index);
                  final dayWeather = dailyForecast[day]!;
                  final avgTemp = dayWeather.map((w) => w.temperature).reduce((a, b) => a + b) / dayWeather.length;
                  final mainWeather = dayWeather[dayWeather.length ~/ 2]; // Middle forecast of the day
                  
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: UIConstants.paddingMedium),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.neutralLight,
                      borderRadius: BorderRadius.circular(UIConstants.borderRadiusSmall),
                    ),
                    padding: const EdgeInsets.all(UIConstants.paddingSmall),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          day,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isDark ? AppColors.textDark : AppColors.textLight,
                          ),
                        ),
                        Icon(
                          _getWeatherIcon(mainWeather.description),
                          color: Theme.of(context).primaryColor,
                          size: UIConstants.iconSizeMedium,
                        ),
                        Text(
                          '${avgTemp.round()}°C',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textDark : AppColors.textLight,
                          ),
                        ),
                        Text(
                          '${dayWeather.map((w) => w.humidity).reduce((a, b) => a + b) ~/ dayWeather.length}%',
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('rain')) return Icons.water_drop;
    if (desc.contains('cloud')) return Icons.cloud;
    if (desc.contains('sun') || desc.contains('clear')) return Icons.wb_sunny;
    if (desc.contains('snow')) return Icons.ac_unit;
    if (desc.contains('thunder')) return Icons.flash_on;
    return Icons.wb_cloudy;
  }

  String _getRiskDescription(String riskLevel) {
    switch (riskLevel) {
      case 'High':
        return 'Weather conditions are highly favorable for disease development. Monitor plants closely and consider preventive treatments.';
      case 'Medium':
        return 'Moderate risk of disease development. Regular monitoring recommended.';
      default:
        return 'Low risk of disease development. Current weather conditions are not favorable for most plant diseases.';
    }
  }

  void _showLocationSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LocationSelectionDialog(),
    );
  }
}