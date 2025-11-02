import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class WeatherThemeProvider extends ChangeNotifier {
  ThemeData _currentTheme = _getDefaultTheme();
  String _currentWeatherCondition = 'clear';

  ThemeData get currentTheme => _currentTheme;
  String get currentWeatherCondition => _currentWeatherCondition;

  void updateThemeForWeather(String weatherCondition) {
    _currentWeatherCondition = weatherCondition.toLowerCase();
    _currentTheme = _getThemeForWeather(_currentWeatherCondition);
    notifyListeners();
  }

  static ThemeData _getDefaultTheme() {
    return ThemeData(
      primaryColor: AppColors.primaryRed, // Red theme
      primarySwatch: Colors.red,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData _getThemeForWeather(String condition) {
    switch (condition) {
      case 'clear':
      case 'sunny':
        return _getSunnyTheme();
      case 'clouds':
      case 'cloudy':
      case 'overcast':
        return _getCloudyTheme();
      case 'rain':
      case 'drizzle':
      case 'shower':
        return _getRainyTheme();
      case 'thunderstorm':
      case 'storm':
        return _getStormyTheme();
      case 'snow':
      case 'sleet':
        return _getSnowyTheme();
      case 'mist':
      case 'fog':
      case 'haze':
        return _getFoggyTheme();
      default:
        return _getDefaultTheme();
    }
  }

  static ThemeData _getSunnyTheme() {
    return ThemeData(
      primarySwatch: Colors.orange,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFF8E1), // Light yellow background
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFF9800), // Orange
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFFFFFDE7), // Very light yellow
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFFF9800),
        secondary: Color(0xFFFFC107),
        surface: Color(0xFFFFFDE7),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.bold,
          shadows: [Shadow(offset: Offset(0.5, 0.5), blurRadius: 1.0, color: Colors.white54)],
        ),
        headlineMedium: TextStyle(
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.w600,
          shadows: [Shadow(offset: Offset(0.5, 0.5), blurRadius: 1.0, color: Colors.white54)],
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF212121),
          shadows: [Shadow(offset: Offset(0.3, 0.3), blurRadius: 0.8, color: Colors.white70)],
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF212121),
          shadows: [Shadow(offset: Offset(0.3, 0.3), blurRadius: 0.8, color: Colors.white70)],
        ),
      ),
    );
  }

  static ThemeData _getCloudyTheme() {
    return ThemeData(
      primarySwatch: Colors.blueGrey,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFECEFF1), // Light grey background
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF607D8B), // Blue grey
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFFF5F5F5), // Light grey
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF607D8B),
        secondary: Color(0xFF90A4AE),
        surface: Color(0xFFF5F5F5),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.bold,
          shadows: [Shadow(offset: Offset(0.5, 0.5), blurRadius: 1.0, color: Colors.white54)],
        ),
        headlineMedium: TextStyle(
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.w600,
          shadows: [Shadow(offset: Offset(0.5, 0.5), blurRadius: 1.0, color: Colors.white54)],
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF212121),
          shadows: [Shadow(offset: Offset(0.3, 0.3), blurRadius: 0.8, color: Colors.white70)],
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF212121),
          shadows: [Shadow(offset: Offset(0.3, 0.3), blurRadius: 0.8, color: Colors.white70)],
        ),
      ),
    );
  }

  static ThemeData _getRainyTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFE3F2FD), // Light blue background
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1976D2), // Blue
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFFE8F4FD), // Very light blue
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1976D2),
        secondary: Color(0xFF42A5F5),
        surface: Color(0xFFE8F4FD),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.bold,
          shadows: [Shadow(offset: Offset(0.5, 0.5), blurRadius: 1.0, color: Colors.white54)],
        ),
        headlineMedium: TextStyle(
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.w600,
          shadows: [Shadow(offset: Offset(0.5, 0.5), blurRadius: 1.0, color: Colors.white54)],
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF212121),
          shadows: [Shadow(offset: Offset(0.3, 0.3), blurRadius: 0.8, color: Colors.white70)],
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF212121),
          shadows: [Shadow(offset: Offset(0.3, 0.3), blurRadius: 0.8, color: Colors.white70)],
        ),
      ),
    );
  }

  static ThemeData _getStormyTheme() {
    return ThemeData(
      primarySwatch: Colors.deepPurple,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A1A2E), // Dark purple background
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF16213E), // Dark blue
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF0F3460), // Dark blue
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF7C4DFF),
        secondary: Color(0xFF9C27B0),
        surface: Color(0xFF0F3460),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(offset: Offset(0.5, 0.5), blurRadius: 1.0, color: Colors.black54)],
        ),
        headlineMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          shadows: [Shadow(offset: Offset(0.5, 0.5), blurRadius: 1.0, color: Colors.black54)],
        ),
        bodyLarge: TextStyle(
          color: Color(0xFFE0E0E0),
          shadows: [Shadow(offset: Offset(0.3, 0.3), blurRadius: 0.8, color: Colors.black87)],
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFE0E0E0),
          shadows: [Shadow(offset: Offset(0.3, 0.3), blurRadius: 0.8, color: Colors.black87)],
        ),
      ),
    );
  }

  static ThemeData _getSnowyTheme() {
    return ThemeData(
      primarySwatch: Colors.cyan,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF0F8FF), // Alice blue background
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF00BCD4), // Cyan
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFFF8FDFF), // Very light cyan
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF00BCD4),
        secondary: Color(0xFF4FC3F7),
        surface: Color(0xFFF8FDFF),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.bold,
          shadows: [Shadow(offset: Offset(0.5, 0.5), blurRadius: 1.0, color: Colors.white54)],
        ),
        headlineMedium: TextStyle(
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.w600,
          shadows: [Shadow(offset: Offset(0.5, 0.5), blurRadius: 1.0, color: Colors.white54)],
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF212121),
          shadows: [Shadow(offset: Offset(0.3, 0.3), blurRadius: 0.8, color: Colors.white70)],
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF212121),
          shadows: [Shadow(offset: Offset(0.3, 0.3), blurRadius: 0.8, color: Colors.white70)],
        ),
      ),
    );
  }

  static ThemeData _getFoggyTheme() {
    return ThemeData(
      primarySwatch: Colors.grey,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light grey background
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF757575), // Grey
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFFFAFAFA), // Very light grey
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF757575),
        secondary: Color(0xFF9E9E9E),
        surface: Color(0xFFFAFAFA),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.bold,
          shadows: [Shadow(offset: Offset(0.5, 0.5), blurRadius: 1.0, color: Colors.white54)],
        ),
        headlineMedium: TextStyle(
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.w600,
          shadows: [Shadow(offset: Offset(0.5, 0.5), blurRadius: 1.0, color: Colors.white54)],
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF212121),
          shadows: [Shadow(offset: Offset(0.3, 0.3), blurRadius: 0.8, color: Colors.white70)],
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF212121),
          shadows: [Shadow(offset: Offset(0.3, 0.3), blurRadius: 0.8, color: Colors.white70)],
        ),
      ),
    );
  }

  // Helper method to get weather condition from weather data
  static String extractWeatherCondition(Map<String, dynamic>? weatherData) {
    if (weatherData == null) return 'clear';
    
    // Extract from OpenWeatherMap API format
    if (weatherData['weather'] != null && weatherData['weather'].isNotEmpty) {
      final mainCondition = weatherData['weather'][0]['main']?.toString().toLowerCase() ?? 'clear';
      return mainCondition;
    }
    
    // Fallback for demo data
    if (weatherData['condition'] != null) {
      return weatherData['condition'].toString().toLowerCase();
    }
    
    return 'clear';
  }
}