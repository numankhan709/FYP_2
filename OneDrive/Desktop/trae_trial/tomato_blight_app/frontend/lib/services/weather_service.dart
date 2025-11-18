import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import '../utils/constants.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _apiKey = ApiConstants.openWeatherApiKey;

  // Check if API key is configured
  bool get _isApiKeyConfigured => _apiKey != 'demo_key' && _apiKey.isNotEmpty;

  Future<WeatherData> getCurrentWeather(double lat, double lon) async {
    print('🌐 WeatherService: Getting current weather for $lat, $lon');
    print('🌐 WeatherService: API key configured: $_isApiKeyConfigured');
    
    // Return demo data if API key is not configured
    if (!_isApiKeyConfigured) {
      print('🌐 WeatherService: Using demo data (API key not configured)');
      return _getDemoWeatherData(lat, lon);
    }

    try {
      final url = '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';
      print('🌐 WeatherService: Making API call to: $url');
      
      final response = await http.get(Uri.parse(url));
      print('🌐 WeatherService: API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🌐 WeatherService: API response data: ${data['main']['temp']}°C, ${data['weather'][0]['description']}');
        return WeatherData.fromOpenWeatherMap(data);
      } else {
        print('🌐 WeatherService: API call failed with status: ${response.statusCode}');
        throw Exception('Failed to fetch weather data: ${response.statusCode}');
      }
    } catch (e) {
      print('🌐 WeatherService: API call error: ${e.toString()}');
      print('🌐 WeatherService: Falling back to demo data');
      // Fallback to demo data if API call fails
      return _getDemoWeatherData(lat, lon);
    }
  }

  Future<Map<String, dynamic>> getBackendCurrent(double lat, double lon) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/weather/current');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'latitude': lat, 'longitude': lon}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final weatherJson = data['weather'];
      final riskJson = data['riskAssessment'];
      final weather = WeatherData(
        temperature: (weatherJson['temperature'] as num).toDouble(),
        feelsLike: (weatherJson['feelsLike'] as num).toDouble(),
        humidity: (weatherJson['humidity'] as num).toInt(),
        pressure: (weatherJson['pressure'] as num).toDouble(),
        windSpeed: (weatherJson['windSpeed'] is num ? (weatherJson['windSpeed'] as num).toDouble() : 0.0),
        windDirection: 0,
        cloudiness: (weatherJson['cloudiness'] is num ? (weatherJson['cloudiness'] as num).toInt() : 0),
        uvIndex: null,
        visibility: weatherJson['visibility'] is num ? (weatherJson['visibility'] as num).toDouble() : null,
        description: weatherJson['description']?.toString() ?? '',
        icon: weatherJson['icon']?.toString() ?? '01d',
        dateTime: DateTime.parse(weatherJson['timestamp'] as String),
        location: weatherJson['location']?['name']?.toString() ?? 'Unknown',
        additionalData: {},
      );
      return {
        'weather': weather,
        'risk': riskJson,
      };
    }
    throw Exception('Backend weather failed: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getBackendRisk({required double temperature, required int humidity, double windSpeed = 0, int cloudiness = 0, double rain = 0}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/weather/risk-assessment');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'temperature': temperature,
        'humidity': humidity,
        'windSpeed': windSpeed,
        'cloudiness': cloudiness,
        'rain': rain,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['riskAssessment'] as Map<String, dynamic>;
    }
    throw Exception('Backend risk failed: ${response.statusCode}');
  }

  Future<List<WeatherData>> getForecast(double lat, double lon, {int days = 5}) async {
    // Return demo data if API key is not configured
    if (!_isApiKeyConfigured) {
      return _getDemoForecastData(lat, lon, days);
    }

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&cnt=${days * 8}', // 8 forecasts per day (3-hour intervals)
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> forecastList = data['list'];
        
        return forecastList.map((item) {
          return WeatherData.fromOpenWeatherMap(item);
        }).toList();
      } else {
        throw Exception('Failed to fetch forecast data: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to demo data if API call fails
      return _getDemoForecastData(lat, lon, days);
    }
  }

  Future<WeatherData> getWeatherByCity(String cityName) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromOpenWeatherMap(data);
      } else {
        throw Exception('Failed to fetch weather data for $cityName: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather data for $cityName: $e');
    }
  }

  Future<List<WeatherData>> getHourlyForecast(double lat, double lon, {int hours = 48}) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&cnt=${(hours / 3).ceil()}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> forecastList = data['list'];
        
        return forecastList.map((item) {
          return WeatherData.fromOpenWeatherMap(item);
        }).toList();
      } else {
        throw Exception('Failed to fetch hourly forecast: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching hourly forecast: $e');
    }
  }

  Future<Map<String, dynamic>> getWeatherAlerts(double lat, double lon) async {
    try {
      // Using One Call API for alerts (requires different endpoint)
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/3.0/onecall?lat=$lat&lon=$lon&appid=$_apiKey&units=metric',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'alerts': data['alerts'] ?? [],
          'current': data['current'],
          'daily': data['daily'],
          'hourly': data['hourly'],
        };
      } else {
        throw Exception('Failed to fetch weather alerts: ${response.statusCode}');
      }
    } catch (e) {
      // Return empty alerts if One Call API is not available
      return {'alerts': []};
    }
  }

  Future<Map<String, dynamic>> getAirQuality(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$_apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to fetch air quality data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching air quality data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchCities(String query) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=$_apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to search cities: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching cities: $e');
    }
  }

  // Helper method to get weather conditions favorable for diseases
  Future<Map<String, dynamic>> getDiseaseRiskWeatherData(double lat, double lon) async {
    try {
      final currentWeather = await getCurrentWeather(lat, lon);
      final forecast = await getForecast(lat, lon, days: 3);
      
      // Calculate disease risk based on weather conditions
      final riskFactors = {
        'current_humidity': currentWeather.humidity,
        'current_temperature': currentWeather.temperature,
        'current_risk': currentWeather.diseaseRiskLevel,
        'avg_humidity_3days': forecast.isEmpty ? 0 : 
            forecast.map((w) => w.humidity).reduce((a, b) => a + b) / forecast.length,
        'avg_temperature_3days': forecast.isEmpty ? 0 : 
            forecast.map((w) => w.temperature).reduce((a, b) => a + b) / forecast.length,
        'rainy_days_forecast': forecast.where((w) => w.isRainy).length,
        'high_humidity_days': forecast.where((w) => w.humidity > 80).length,
        'favorable_conditions': currentWeather.favorableForFungalDiseases || 
                               currentWeather.favorableForBacterialDiseases,
      };
      
      return {
        'current': currentWeather.toJson(),
        'forecast': forecast.map((w) => w.toJson()).toList(),
        'risk_factors': riskFactors,
      };
    } catch (e) {
      throw Exception('Error getting disease risk weather data: $e');
    }
  }

  // Get weather icon URL
  String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  // Convert weather condition to disease risk level
  String getWeatherBasedDiseaseRisk(WeatherData weather) {
    if (weather.humidity > 90 && weather.temperature > 20 && weather.temperature < 30) {
      return 'Very High';
    } else if (weather.humidity > 80 && weather.temperature > 15 && weather.temperature < 32) {
      return 'High';
    } else if (weather.humidity > 60 && weather.temperature > 10 && weather.temperature < 35) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }

  // Demo weather data for testing when API key is not configured
  WeatherData _getDemoWeatherData(double lat, double lon) {
    final now = DateTime.now();
    final demoData = {
      'coord': {'lon': lon, 'lat': lat},
      'weather': [{
        'id': 801,
        'main': 'Clouds',
        'description': 'few clouds',
        'icon': '02d'
      }],
      'main': {
        'temp': 24.5,
        'feels_like': 26.2,
        'temp_min': 22.1,
        'temp_max': 27.3,
        'pressure': 1013,
        'humidity': 65
      },
      'wind': {
        'speed': 3.2,
        'deg': 180
      },
      'clouds': {
        'all': 25
      },
      'dt': now.millisecondsSinceEpoch ~/ 1000,
      'name': 'Demo Location',
      'visibility': 10000
    };
    return WeatherData.fromOpenWeatherMap(demoData);
  }

  // Demo forecast data for testing
  List<WeatherData> _getDemoForecastData(double lat, double lon, int days) {
    final List<WeatherData> forecast = [];
    final now = DateTime.now();
    
    for (int i = 1; i <= days * 8; i++) {
      final futureTime = now.add(Duration(hours: i * 3));
      final temp = 20 + (i % 10); // Varying temperature
      final humidity = 50 + (i % 40); // Varying humidity
      
      final demoData = {
        'dt': futureTime.millisecondsSinceEpoch ~/ 1000,
        'main': {
          'temp': temp.toDouble(),
          'feels_like': temp + 2.0,
          'temp_min': temp - 2.0,
          'temp_max': temp + 3.0,
          'pressure': 1010 + (i % 20),
          'humidity': humidity
        },
        'weather': [{
          'id': i % 2 == 0 ? 800 : 801,
          'main': i % 2 == 0 ? 'Clear' : 'Clouds',
          'description': i % 2 == 0 ? 'clear sky' : 'few clouds',
          'icon': i % 2 == 0 ? '01d' : '02d'
        }],
        'wind': {
          'speed': 2.0 + (i % 5),
          'deg': (i * 45) % 360
        },
        'clouds': {
          'all': i % 2 == 0 ? 0 : 25
        },
        'visibility': 10000
      };
      
      forecast.add(WeatherData.fromOpenWeatherMap(demoData));
    }
    
    return forecast;
  }
}