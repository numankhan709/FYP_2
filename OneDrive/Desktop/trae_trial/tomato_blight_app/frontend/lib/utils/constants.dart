class ApiConstants {
  // Backend API base URL - update this when backend is deployed
//  static const String baseUrl = 'http://172.17.241.147:3000/api';
//  static const String baseUrl = 'http://172.17.240.225:3000/api';
//  static const String baseUrl = 'http://10.0.2.2:3000/api'; // For Android emulator
  static const String baseUrl = 'http://192.168.100.58:3000/api';
  static const List<String> baseUrlCandidates = [
    'http://192.168.100.58:3000/api',
    'http://192.168.43.220:3000/api',
    'http://172.17.240.225:3000/api',
    'http://10.0.2.2:3000/api',
    'http://172.17.243.50:3000/api',
  ];
  
  // OpenWeather API
  // Get your free API key from: https://openweathermap.org/api
  // Replace 'demo_key' with your actual API key
  static const String openWeatherApiKey = '06f4afbb6059e103852222fdbaa3c8e7';
  static const String openWeatherBaseUrl = 'https://api.openweathermap.org/data/2.5';
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String signupEndpoint = '/auth/signup';
  static const String logoutEndpoint = '/auth/logout';
  static const String profileEndpoint = '/auth/profile';
  static const String diseasesEndpoint = '/diseases';
  static const String analyzeEndpoint = '/diseases/analyze';
  static const String scansEndpoint = '/scans';
  static const String riskAssessmentEndpoint = '/diseases/risk-assessment';
  
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
  
  // Password validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  
  // Name validation
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  
  // Error messages
  static const String emailRequiredError = 'Email is required';
  static const String emailInvalidError = 'Please enter a valid email address';
  static const String passwordRequiredError = 'Password is required';
  static const String passwordTooShortError = 'Password must be at least 6 characters';
  static const String passwordTooLongError = 'Password must be less than 50 characters';
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
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
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
}