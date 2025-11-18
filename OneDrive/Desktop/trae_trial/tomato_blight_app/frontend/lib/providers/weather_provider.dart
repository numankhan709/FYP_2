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
  List<Map<String, dynamic>> _weatherAlerts = [];
  Position? _currentPosition;
  String? _currentLocation;
  bool _isLoading = false;
  String? _errorMessage;

  WeatherData? get currentWeather => _currentWeather;
  List<WeatherData> get forecast => _forecast;
  List<Map<String, dynamic>> get weatherAlerts => _weatherAlerts;
  Position? get currentPosition => _currentPosition;
  String? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Set context for theme updates
  void setContext(BuildContext context) {
    _context = context;
  }
  
  // Get current risk assessment based on weather conditions
  Map<String, dynamic>? get currentRiskAssessment {
    if (_backendRisk != null) return _backendRisk;
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

  Map<String, dynamic>? _backendRisk;

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
      try {
        final backend = await _weatherService.getBackendCurrent(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        _currentWeather = backend['weather'] as WeatherData;
        _backendRisk = backend['risk'] as Map<String, dynamic>;
      } catch (_) {
        _currentWeather = await _weatherService.getCurrentWeather(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      }

      // Fetch 5-day forecast
      _forecast = await _weatherService.getForecast(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      // Update theme based on current weather
      _updateThemeForWeather();

      _setLoading(false);
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
    } catch (e) {
      print('🌤️ WeatherProvider: Error fetching weather data: ${e.toString()}');
      _errorMessage = 'Failed to fetch weather data: ${e.toString()}';
      _isLoading = false;
    }
    
    // Only notify listeners after everything is set
    print('🌤️ WeatherProvider: Notifying listeners...');
    notifyListeners();
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

  bool get isWeatherFavorableForDisease {
    if (_currentWeather == null) return false;
    
    // High humidity and moderate temperature favor fungal diseases
    return _currentWeather!.humidity > 70 && 
           _currentWeather!.temperature > 15 && 
           _currentWeather!.temperature < 30;
  }

  String get weatherRiskLevel {
    if (_currentWeather == null) return 'Unknown';
    
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
    await fetchWeatherData();
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

  // Fetch weather alerts for current location
  Future<void> fetchWeatherAlerts({int limit = 20}) async {
    if (_currentPosition == null) {
      try {
        await _initializeLocation();
      } catch (_) {}
    }

    if (_currentPosition == null) {
      _setError('Location not available for alerts');
      _weatherAlerts = [];
      notifyListeners();
      return;
    }

    try {
      final data = await _weatherService.getWeatherAlerts(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      final rawAlerts = (data['alerts'] as List?) ?? [];
      // Map OpenWeather alert structure to UI-friendly shape
      final mapped = rawAlerts.map<Map<String, dynamic>>((a) {
        final event = a['event']?.toString() ?? 'Weather Alert';
        final description = a['description']?.toString() ?? '';
        final tags = (a['tags'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? const [];
        final start = (a['start'] is int) ? DateTime.fromMillisecondsSinceEpoch((a['start'] as int) * 1000).toIso8601String() : null;

        // Basic severity heuristic
        String severity = 'low';
        final eventLower = event.toLowerCase();
        if (tags.contains('thunderstorm') || tags.contains('severe') || eventLower.contains('storm')) {
          severity = 'high';
        } else if (tags.contains('rain') || tags.contains('snow') || eventLower.contains('rain') || eventLower.contains('snow')) {
          severity = 'medium';
        }

        return {
          'title': event,
          'message': description,
          'severity': severity,
          'createdAt': start,
          'source': 'OpenWeather',
        };
      }).toList();

      _weatherAlerts = mapped.take(limit).toList();
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to fetch weather alerts');
      _weatherAlerts = [];
      notifyListeners();
    }
  }

  // Simulate weather conditions (debug)
  Future<void> simulateWeatherConditions({
    required double temperature,
    required int humidity,
    required String description,
    required int cloudiness,
    required double windSpeed,
    required double pressure,
  }) async {
    try {
      final now = DateTime.now();
      final location = _currentLocation ?? 'Simulated';
      _currentWeather = WeatherData(
        temperature: temperature,
        feelsLike: temperature,
        humidity: humidity,
        pressure: pressure,
        windSpeed: windSpeed,
        windDirection: 0,
        cloudiness: cloudiness,
        uvIndex: null,
        visibility: null,
        description: description,
        icon: '01d',
        dateTime: now,
        location: location,
        additionalData: {
          'simulated': true,
        },
      );
      _updateThemeForWeather();
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to simulate weather conditions');
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