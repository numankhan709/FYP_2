import 'package:flutter/foundation.dart';

class ApiConstants {
  // Backend API base URLs
  static const String baseUrlWeb = 'http://localhost:3000/api';
  // Update this to your machine's LAN IP shown by backend logs
  // Example from server logs: Network access: http://172.17.242.215:3000/api/health
  // Set to your PC's LAN IP so a physical Android device can reach the backend
  // Update this to match the "Network access" line printed by the server at startup
  // Example from logs: 🌐 Network access: http://172.17.242.215:3001/api/health
  // Set to your PC's LAN IP so physical devices can reach the backend
  // Detected IPv4 candidates: 192.168.117.1, 192.168.160.1, 192.168.100.58
  // Using 192.168.100.58 for current Wi‑Fi network
  static const String baseUrlDevice = 'http://192.168.100.58:3000/api';

  // Resolve base URL per platform at runtime
  static String get baseUrl {
    // For physical devices, use configured LAN IP
    // For emulator runs, temporarily set baseUrlDevice to 'http://10.0.2.2:3000/api'
    return kIsWeb ? baseUrlWeb : baseUrlDevice;
  }

  // OpenWeather API
  static const String openWeatherApiKey = '06f4afbb6059e103852222fdbaa3c8e7';
  static const String openWeatherBaseUrl = 'https://api.openweathermap.org/data/2.5';

  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String signupEndpoint = '/auth/signup';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String logoutEndpoint = '/auth/logout';
  static const String profileEndpoint = '/auth/profile';
  static const String diseasesEndpoint = '/diseases';
  static const String analyzeEndpoint = '/diseases/analyze';
  static const String scansEndpoint = '/scans';
  static const String riskAssessmentEndpoint = '/diseases/risk-assessment';
  // Weather endpoints (backend)
  static const String weatherCurrentEndpoint = '/weather/current';
  static const String weatherForecastEndpoint = '/weather/forecast';
  static const String weatherMlAssessEndpoint = '/weather-ml/assess';
  static const String weatherMlAlertsEndpoint = '/weather-ml/alerts';

  // Request timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 2);
}

class AppConstants {
  // App Information
  static const String appName = 'Tomato Disease Classification';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Smart Disease Detection for Healthier Crops';
  static const String appDescription =
      'An intelligent mobile application for early detection and management of tomato diseases using AI-powered image analysis and weather-based risk assessment.';
  
  // Features
  static const List<String> appFeatures = [
    'AI-powered disease detection from plant images',
    'Real-time weather monitoring and disease risk assessment',
    'Comprehensive disease information and treatment guides',
    'Scan history and progress tracking',
    'PDF report generation for professional use',
    'GPS-based location services for accurate weather data',
    'Offline functionality for remote areas',
    'User-friendly interface with modern design',
  ];
  
  // Supported image formats
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png'];
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB
  
  // Local storage keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String scanHistoryKey = 'scan_history';
  static const String settingsKey = 'app_settings';
  static const String lastLocationKey = 'last_location';
  static const String weatherCacheKey = 'weather_cache';
  
  // Default values
  static const double defaultLatitude = 40.7128;
  static const double defaultLongitude = -74.0060;
  static const String defaultCity = 'New York';
  
  // Disease risk levels
  static const String riskLevelLow = 'Low';
  static const String riskLevelMedium = 'Medium';
  static const String riskLevelHigh = 'High';
  static const String riskLevelCritical = 'Critical';
}

class UIConstants {
  // Light Mode Color Scheme
  static const int primaryColorValue = 0xFF228B22; // Forest Green
  static const int secondaryColorValue = 0xFF228B22; // Forest Green
  static const int accentColorValue = 0xFFFFD700; // Golden Yellow
  static const int backgroundColorValue = 0xFFF5F5F5; // Light Gray
  static const int textColorValue = 0xFF333333; // Charcoal
  
  // Dark Mode Color Scheme
  static const int darkPrimaryColorValue = 0xFF228B22; // Forest Green (same)
  static const int darkSecondaryColorValue = 0xFF2F6A47; // Dark Forest Green
  static const int darkAccentColorValue = 0xFFFFB300; // Soft Golden Yellow
  static const int darkBackgroundColorValue = 0xFF121212; // Rich Charcoal
  static const int darkTextColorValue = 0xFFE0E0E0; // Light Gray/White
  
  // Additional semantic colors
  static const int errorColorValue = 0xFFE53935; // Error red
  static const int warningColorValue = 0xFFFFB300; // Warning amber
  static const int successColorValue = 0xFF4CAF50; // Success green
  
  // Legacy tomato plant colors (kept for backward compatibility)
  static const int tomatoStemValue = 0xFF1B5E20; // Deep tomato stem green
  static const int tomatoLeafDarkValue = 0xFF0D4F14; // Very dark tomato leaf
  static const int tomatoLeafLightValue = 0xFF4CAF50; // Bright tomato leaf
  static const int greenTomatoValue = 0xFF558B2F; // Green unripe tomato
  static const int tomatoBlossomValue = 0xFFFDD835; // Bright tomato flower yellow
  static const int tomatoVineValue = 0xFF2E7D32; // Strong tomato vine green
  static const int tomatoRipeningValue = 0xFFFF6F00; // Tomato ripening orange
  static const int tomatoSkinValue = 0xFFD84315; // Tomato skin red-orange
  static const int tomatoSeedValue = 0xFFFFF3E0; // Tomato seed cream
  
  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Border radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXLarge = 16.0;
  
  // Icon sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;
  
  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
}

class ValidationConstants {
  // Email validation
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  
  // Password validation aligned with backend regex
  static const int minPasswordLength = 5;
  static const int maxPasswordLength = 50;
  static const String passwordPattern = r'^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{5,}$';
  
  // Name validation
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  
  // Error messages
  static const String emailRequiredError = 'Email is required';
  static const String emailInvalidError = 'Please enter a valid email address';
  static const String passwordRequiredError = 'Password is required';
  static const String passwordTooShortError = 'Password must be at least 5 characters';
  static const String passwordTooLongError = 'Password must be less than 50 characters';
  static const String passwordFormatError = 'Password must include upper, lower, and a number';
  static const String nameRequiredError = 'Name is required';
  static const String nameTooShortError = 'Name must be at least 2 characters';
  static const String nameTooLongError = 'Name must be less than 50 characters';
  static const String passwordMismatchError = 'Passwords do not match';
  
  // Network error messages
  static const String networkError = 'Network connection error. Please check your internet connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String timeoutError = 'Request timeout. Please try again.';
  static const String unknownError = 'An unexpected error occurred. Please try again.';
}

class RouteConstants {
  // Removed splash routes; app now starts directly at login or home via router logic
  static const String welcomeSplash = '/welcome-splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String scan = '/scan';
  static const String scanResult = '/scan-result';
  static const String history = '/history';
  static const String diseases = '/diseases';
  static const String diseaseDetail = '/disease-detail';
  static const String weather = '/weather';
  static const String riskAssessment = '/risk-assessment';
  static const String reports = '/reports';
  static const String about = '/about';
  static const String profile = '/profile';
  static const String settings = '/settings';
  // Forgot/Reset password routes
}