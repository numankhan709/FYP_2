import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import 'weather_theme_provider.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  BuildContext? _context;
  
  WeatherData? _currentWeather;
  List<WeatherData> _forecast = [];
  Position? _currentPosition;
  String? _currentLocation;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastWeatherFetchAt;
  DateTime? _lastBackendAssessmentsAt;
  // Backend/ML assessment state
  Map<String, dynamic>? _mlAssessment;
  String? _backendRiskLevel; // heuristic from backend /api/weather/current

  // Weather-triggered disease alerts
  List<Map<String, dynamic>> _weatherAlerts = [];

  WeatherData? get currentWeather => _currentWeather;
  List<WeatherData> get forecast => _forecast;
  Position? get currentPosition => _currentPosition;
  String? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get mlAssessment => _mlAssessment;
  String? get backendRiskLevel => _backendRiskLevel;
  List<Map<String, dynamic>> get weatherAlerts => _weatherAlerts;
  
  // Set context for theme updates
  void setContext(BuildContext context) {
    _context = context;
  }
  
  // Get current risk assessment based on weather conditions
  Map<String, dynamic>? get currentRiskAssessment {
    if (_currentWeather == null) return null;
    final riskLevel = _calculateDiseaseRisk(_currentWeather!.temperature, _currentWeather!.humidity);
    return {
      'risk_level': riskLevel,
      'temperature': _currentWeather!.temperature,
      'humidity': _currentWeather!.humidity,
      'description': _getRiskDescription(riskLevel),
      'recommendations': _getRiskRecommendations(riskLevel),
      'weather_description': _currentWeather!.description,
      'pressure': _currentWeather!.pressure,
      'wind_speed': _currentWeather!.windSpeed,
      'cloudiness': _currentWeather!.cloudiness,
    };
  }

  WeatherProvider() {
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      print('🌍 WeatherProvider: Starting location initialization...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('🌍 WeatherProvider: Location services enabled: $serviceEnabled');
      if (!serviceEnabled) {
        print('🌍 WeatherProvider: Location services disabled');
        _setError('Location services are disabled. Please enable GPS/Location services in your device settings to get accurate local weather data.');
        await _useFallbackLocation();
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      print('🌍 WeatherProvider: Current permission: $permission');
      if (permission == LocationPermission.denied) {
        print('🌍 WeatherProvider: Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('🌍 WeatherProvider: Permission after request: $permission');
        if (permission == LocationPermission.denied) {
          print('🌍 WeatherProvider: Location permissions denied, using fallback location');
          await _useFallbackLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('🌍 WeatherProvider: Location permissions permanently denied, using fallback location');
        await _useFallbackLocation();
        return;
      }

      // Get current position
      print('🌍 WeatherProvider: Getting current position...');
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('🌍 WeatherProvider: Position obtained: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');

      // Get location name
      print('🌍 WeatherProvider: Getting location name...');
        await _getLocationName();
      print('🌍 WeatherProvider: Location name: $_currentLocation');
      
      // Fetch weather data without triggering listeners during build
      print('🌍 WeatherProvider: Fetching weather data...');
      await _fetchWeatherDataSilently();
      print('🌍 WeatherProvider: Weather data fetch completed');
    } catch (e) {
      print('🌍 WeatherProvider: Error during initialization: ${e.toString()}');
      _setError('Failed to get location: ${e.toString()}');
    }
  }

  Future<bool> getCurrentLocation() async {
    _setLoading(true);
    _clearError();
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('Location services are disabled. Please enable location services.');
        return false;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError('Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setError('Location permissions are permanently denied');
        return false;
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get location name
      await _getLocationName();
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to get current location: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _getLocationName() async {
    if (_currentPosition == null) return;
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        
        // Build location string with available data
        List<String> locationParts = [];
        
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          locationParts.add(placemark.locality!);
        } else if (placemark.subAdministrativeArea != null && placemark.subAdministrativeArea!.isNotEmpty) {
          locationParts.add(placemark.subAdministrativeArea!);
        }
        
        if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
          locationParts.add(placemark.administrativeArea!);
        } else if (placemark.country != null && placemark.country!.isNotEmpty) {
          locationParts.add(placemark.country!);
        }
        
        if (locationParts.isNotEmpty) {
          _currentLocation = locationParts.join(', ');
        } else {
          // Fallback to coordinates if no readable location found
          _currentLocation = '${_currentPosition!.latitude.toStringAsFixed(2)}, ${_currentPosition!.longitude.toStringAsFixed(2)}';
        }
      } else {
        // Fallback to coordinates if no placemarks found
        _currentLocation = '${_currentPosition!.latitude.toStringAsFixed(2)}, ${_currentPosition!.longitude.toStringAsFixed(2)}';
      }
    } catch (e) {
      // Fallback to coordinates instead of "Unknown Location"
      if (_currentPosition != null) {
        _currentLocation = '${_currentPosition!.latitude.toStringAsFixed(2)}, ${_currentPosition!.longitude.toStringAsFixed(2)}';
      } else {
        _currentLocation = 'Location unavailable';
      }
    }
  }

  Future<void> fetchWeatherData() async {
    if (_currentPosition == null) {
      _setError('Location not available');
      return;
    }

    _setLoading(true);
    _clearError();
    
    try {
      // Fetch current weather
      _currentWeather = await _weatherService.getCurrentWeather(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      // Fetch 5-day forecast
      _forecast = await _weatherService.getForecast(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      // Update theme based on current weather
      _updateThemeForWeather();

      _setLoading(false);
      _lastWeatherFetchAt = DateTime.now();
      await _fetchBackendAssessments();
      // Also fetch stored alerts from backend
      await fetchWeatherAlerts(limit: 20);
    } catch (e) {
      _setError('Failed to fetch weather data: ${e.toString()}');
      _setLoading(false);
    }
  }

  Future<void> refreshWeatherData() async {
    await fetchWeatherData();
  }

  // Silent fetch for initialization to prevent setState during build
  Future<void> _fetchWeatherDataSilently() async {
    print('🌤️ WeatherProvider: Starting silent weather fetch...');
    
    if (_currentPosition == null) {
      print('🌤️ WeatherProvider: No position available for weather fetch');
      _errorMessage = 'Location not available';
      return;
    }

    print('🌤️ WeatherProvider: Position available: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
    _isLoading = true;
    _errorMessage = null;
    
    try {
      // Fetch current weather
      print('🌤️ WeatherProvider: Fetching current weather...');
      _currentWeather = await _weatherService.getCurrentWeather(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      print('🌤️ WeatherProvider: Current weather fetched: ${_currentWeather?.temperature}°C, ${_currentWeather?.description}');

      // Fetch 5-day forecast
      print('🌤️ WeatherProvider: Fetching forecast...');
      _forecast = await _weatherService.getForecast(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      print('🌤️ WeatherProvider: Forecast fetched: ${_forecast.length} items');

      _isLoading = false;
      print('🌤️ WeatherProvider: Weather fetch completed successfully');
      _lastWeatherFetchAt = DateTime.now();
    } catch (e) {
      print('🌤️ WeatherProvider: Error fetching weather data: ${e.toString()}');
      _errorMessage = 'Failed to fetch weather data: ${e.toString()}';
      _isLoading = false;
    }
    
    // Only notify listeners after everything is set
    print('🌤️ WeatherProvider: Notifying listeners...');
    notifyListeners();
    await _fetchBackendAssessments();
  }

  // Fallback location when GPS/location services are unavailable
  Future<void> _useFallbackLocation() async {
    try {
      print('🌍 WeatherProvider: Using fallback location...');
      
      // Use a more generic location (London as an example)
      // This will be replaced with user's manual selection in the future
      const double fallbackLat = 51.5074;  // London coordinates
      const double fallbackLon = -0.1278;
      
      _currentPosition = Position(
        latitude: fallbackLat,
        longitude: fallbackLon,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      
      _currentLocation = 'London, UK (Default - Tap to change)';
      print('🌍 WeatherProvider: Fallback location set: $_currentLocation');
      
      // Fetch weather data for fallback location
      print('🌍 WeatherProvider: Fetching weather for fallback location...');
      await _fetchWeatherDataSilently();
      print('🌍 WeatherProvider: Fallback weather data fetch completed');
      
    } catch (e) {
      print('🌍 WeatherProvider: Error using fallback location: ${e.toString()}');
      _setError('Unable to fetch weather data. Please check your internet connection.');
    }
  }

  // Method to set custom location manually
  Future<void> setManualLocation(double lat, double lon, String locationName) async {
    try {
      print('🌍 WeatherProvider: Setting manual location: $locationName ($lat, $lon)');
      
      _currentPosition = Position(
        latitude: lat,
        longitude: lon,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      
      _currentLocation = locationName;
      _clearError();
      
      // Fetch weather data for the new location
      await fetchWeatherData();
      
      print('🌍 WeatherProvider: Manual location set successfully: $_currentLocation');
    } catch (e) {
      print('🌍 WeatherProvider: Error setting manual location: ${e.toString()}');
      _setError('Failed to set location: ${e.toString()}');
    }
  }

  Future<WeatherData?> getWeatherForLocation(double lat, double lon) async {
    try {
      return await _weatherService.getCurrentWeather(lat, lon);
    } catch (e) {
      _setError('Failed to get weather for location');
      return null;
    }
  }

  Map<String, dynamic> getWeatherDataForRiskAssessment() {
    if (_currentWeather == null) return {};
    
    return {
      'temperature': _currentWeather!.temperature,
      'humidity': _currentWeather!.humidity,
      'pressure': _currentWeather!.pressure,
      'windSpeed': _currentWeather!.windSpeed,
      'description': _currentWeather!.description,
      'cloudiness': _currentWeather!.cloudiness,
      'uvIndex': _currentWeather!.uvIndex,
    };
  }

  // Debug/test: simulate weather conditions and fetch backend assessments/alerts
  Future<void> simulateWeatherConditions({
    required double temperature,
    required int humidity,
    String description = 'clear sky',
    int cloudiness = 10,
    double windSpeed = 2.0,
    double pressure = 1013.0,
    double? uvIndex,
  }) async {
    // Ensure we have a position; use fallback if needed
    if (_currentPosition == null) {
      await _useFallbackLocation();
    }

    // Pick a simple icon based on description
    String icon = '01d';
    final desc = description.toLowerCase();
    if (desc.contains('rain')) {
      icon = '10d';
    } else if (desc.contains('cloud')) {
      icon = '03d';
    } else if (desc.contains('thunder')) {
      icon = '11d';
    } else if (desc.contains('snow')) {
      icon = '13d';
    } else if (desc.contains('mist') || desc.contains('fog')) {
      icon = '50d';
    }

    _currentWeather = WeatherData(
      temperature: temperature,
      feelsLike: temperature,
      humidity: humidity,
      pressure: pressure,
      windSpeed: windSpeed,
      windDirection: 0,
      cloudiness: cloudiness,
      uvIndex: uvIndex,
      visibility: 10000,
      description: description,
      icon: icon,
      dateTime: DateTime.now(),
      location: _currentLocation,
      additionalData: {
        'simulated': true,
      },
    );
    _lastWeatherFetchAt = DateTime.now();
    _clearError();
    notifyListeners();

    // Use the simulated weather in ML assessment to derive alerts
    await _fetchBackendAssessments();
    await fetchWeatherAlerts(limit: 20);
  }

  bool get isWeatherFavorableForDisease {
    if (_currentWeather == null) return false;
    
    // High humidity and moderate temperature favor fungal diseases
    return _currentWeather!.humidity > 70 && 
           _currentWeather!.temperature > 15 && 
           _currentWeather!.temperature < 30;
  }

  String get weatherRiskLevel {
    if (_currentWeather == null) return _backendRiskLevel ?? 'Unknown';
    
    final humidity = _currentWeather!.humidity;
    final temp = _currentWeather!.temperature;
    
    if (humidity > 80 && temp > 20 && temp < 28) {
      return 'High';
    } else if (humidity > 60 && temp > 15 && temp < 32) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }
  
  // Calculate disease risk based on temperature and humidity
  String _calculateDiseaseRisk(double temperature, int humidity) {
    if (humidity > 80 && temperature > 20 && temperature < 28) {
      return 'High';
    } else if (humidity > 60 && temperature > 15 && temperature < 32) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }
  
  // ML availability and formatted outputs
  bool get hasMlResult {
    final m = _mlAssessment;
    if (m == null) return false;
    final model = (m['modelAssessment'] is Map<String, dynamic>) ? m['modelAssessment'] as Map<String, dynamic> : m;
    return model['predicted_label'] != null || model['top_probability'] != null || model['probabilities'] != null;
  }

  String? get mlPredictedLabel {
    final m = _mlAssessment;
    if (m == null) return null;
    final model = (m['modelAssessment'] is Map<String, dynamic>) ? m['modelAssessment'] as Map<String, dynamic> : m;
    return model['predicted_label'] as String?;
  }

  double? get mlTopProbability {
    final m = _mlAssessment;
    if (m == null) return null;
    final model = (m['modelAssessment'] is Map<String, dynamic>) ? m['modelAssessment'] as Map<String, dynamic> : m;
    final p = model['top_probability'];
    if (p is num) return p.toDouble();
    return null;
  }
  
  // Get risk description based on risk level
  String _getRiskDescription(String riskLevel) {
    switch (riskLevel) {
      case 'High':
        return 'Weather conditions are highly favorable for disease development. High humidity and optimal temperatures create ideal conditions for fungal and bacterial diseases to spread rapidly.';
      case 'Medium':
        return 'Moderate risk of disease development. Weather conditions are somewhat favorable for disease spread. Regular monitoring is recommended.';
      case 'Low':
        return 'Low risk of disease development. Current weather conditions are not particularly favorable for most plant diseases.';
      default:
        return 'Risk assessment unavailable due to insufficient weather data.';
    }
  }
  
  // Get recommendations based on risk level
  List<String> _getRiskRecommendations(String riskLevel) {
    switch (riskLevel) {
      case 'High':
        return [
          'Inspect plants daily for early signs of disease',
          'Avoid overhead watering to reduce leaf wetness',
          'Ensure good air circulation around plants',
          'Consider applying preventive fungicide treatments',
          'Remove any infected plant material immediately',
          'Avoid working with plants when they are wet',
        ];
      case 'Medium':
        return [
          'Monitor plants every 2-3 days for disease symptoms',
          'Water at soil level rather than on leaves',
          'Maintain proper plant spacing for air circulation',
          'Be prepared to apply treatments if symptoms appear',
          'Keep garden tools clean and disinfected',
        ];
      case 'Low':
        return [
          'Continue regular plant monitoring',
          'Maintain good garden hygiene practices',
          'Ensure plants have adequate nutrition',
          'Keep weeds under control',
          'Monitor weather forecasts for changing conditions',
        ];
      default:
        return [
          'Check weather conditions regularly',
          'Maintain general plant health practices',
          'Monitor plants for any unusual symptoms',
        ];
    }
  }
  
  // Assess disease risk and refresh weather data
  Future<void> assessDiseaseRisk() async {
    // If recent weather data exists, avoid refetch to speed up navigation
    final now = DateTime.now();
    final isFresh = _lastWeatherFetchAt != null && now.difference(_lastWeatherFetchAt!).inMinutes < 10;
    if (_currentWeather != null && isFresh) {
      // Optionally refresh backend ML assessments if stale
      final mlStale = _lastBackendAssessmentsAt == null || now.difference(_lastBackendAssessmentsAt!).inMinutes >= 15;
      if (mlStale) {
        await _fetchBackendAssessments();
      }
      return;
    }
    await fetchWeatherData();
  }
  
  // Fetch backend heuristic and ML assessments
  Future<void> _fetchBackendAssessments() async {
    if (_currentPosition == null) return;
    // Prefer ML assess endpoint which works with provided weather values
    try {
      final mlRes = await _weatherService.assessWeatherMl(
        lat: _currentPosition!.latitude,
        lon: _currentPosition!.longitude,
        weather: _currentWeather,
      );
      _mlAssessment = mlRes;
      // Derive backendRiskLevel from heuristic or modelAssessment
      final heur = (mlRes['heuristic'] as Map<String, dynamic>?) ?? {};
      final model = (mlRes['modelAssessment'] as Map<String, dynamic>?) ?? {};
      final rawRisk = (heur['risk_level'] as String?) ?? (model['predicted_label'] as String?);
      _backendRiskLevel = _normalizeRiskLabel(rawRisk);
      // Capture any alerts included in ML assessment response
      final alertsRes = (mlRes['alerts'] as List?) ?? [];
      _weatherAlerts = alertsRes.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _mlAssessment = null;
      // Fallback: try legacy backend current endpoint if available
      try {
        final currentRes = await _weatherService.getBackendCurrentWeather(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        final risk = (currentRes['riskAssessment'] ?? currentRes['risk_assessment']) as Map<String, dynamic>?;
        _backendRiskLevel = risk != null
            ? _normalizeRiskLabel((risk['risk_level'] as String?) ?? (risk['riskLevel'] as String?))
            : null;
      } catch (_) {
        _backendRiskLevel = null;
      }
    }

    notifyListeners();
    _lastBackendAssessmentsAt = DateTime.now();
  }

  // Normalize varied backend risk labels to UI-friendly values
  String? _normalizeRiskLabel(String? input) {
    if (input == null) return null;
    final s = input.toLowerCase().trim();
    if (s.contains('high')) return 'High';
    if (s.contains('medium')) return 'Medium';
    if (s.contains('low')) return 'Low';
    return null;
  }

  // Fetch stored weather-triggered disease alerts from backend
  Future<void> fetchWeatherAlerts({int limit = 20}) async {
    try {
      final items = await _weatherService.getBackendWeatherAlerts(limit: limit);
      _weatherAlerts = items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      notifyListeners();
    } catch (e) {
      // Keep existing alerts on failure; optionally log error
    }
  }
  
  // Public method to initialize location
  Future<void> initializeLocation() async {
    await _initializeLocation();
  }
  
  // Public method to refresh location
  Future<void> refreshLocation() async {
    _setLoading(true);
    _clearError();
    
    try {
      // Get current position again
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Get updated location name
      await _getLocationName();
      
      // Refresh weather data with new location
      await fetchWeatherData();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh location: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Method to retry location services (useful when user enables GPS)
  Future<bool> retryLocationServices() async {
    _setLoading(true);
    _clearError();
    
    try {
      print('🌍 WeatherProvider: Retrying location services...');
      
      // Check if location services are now enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('🌍 WeatherProvider: Location services enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        _setError('Location services are still disabled. Please enable GPS/Location services in your device settings.');
        _setLoading(false);
        return false;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      print('🌍 WeatherProvider: Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        print('🌍 WeatherProvider: Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('🌍 WeatherProvider: Permission after request: $permission');
        
        if (permission == LocationPermission.denied) {
          _setError('Location permissions are denied. Please allow location access in app settings.');
          _setLoading(false);
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setError('Location permissions are permanently denied. Please enable them in app settings.');
        _setLoading(false);
        return false;
      }

      // Get current position
      print('🌍 WeatherProvider: Getting current position...');
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('🌍 WeatherProvider: Position obtained: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');

      // Get location name
      await _getLocationName();
      print('🌍 WeatherProvider: Location name: $_currentLocation');
      
      // Fetch weather data
      await fetchWeatherData();
      
      _setLoading(false);
      print('🌍 WeatherProvider: Location services retry successful');
      return true;
      
    } catch (e) {
      print('🌍 WeatherProvider: Error during location retry: ${e.toString()}');
      _setError('Failed to get location: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _updateThemeForWeather() {
    if (_context != null && _currentWeather != null) {
      try {
        final themeProvider = Provider.of<WeatherThemeProvider>(_context!, listen: false);
        final weatherCondition = _currentWeather!.description.toLowerCase();
        themeProvider.updateThemeForWeather(weatherCondition);
      } catch (e) {
        // Silently handle theme update errors
        debugPrint('Failed to update theme: $e');
      }
    }
  }
}