import 'package:shared_preferences/shared_preferences.dart';

enum SplashScreenType {
  initial,
  welcome,
  loading,
}

class SplashService {
  static const String _splashShownKey = 'splash_screen_shown';
  static const String _welcomeShownKey = 'welcome_splash_shown';
  static const String _lastLoginTimeKey = 'last_login_time';
  
  /// Check if initial splash screen has been shown before
  static Future<bool> hasSplashBeenShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_splashShownKey) ?? false;
  }
  
  /// Mark initial splash screen as shown
  static Future<void> markSplashAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_splashShownKey, true);
  }
  
  /// Check if welcome splash should be shown after login/signup
  /// Returns true only if it has never been shown before
  static Future<bool> shouldShowWelcomeSplash() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_welcomeShownKey) ?? false);
  }

  /// Mark welcome splash as shown so it won't display again
  static Future<void> markWelcomeSplashShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeShownKey, true);
  }
  
  /// Determine if loading screen should be shown based on operation duration
  /// Returns true if the operation is expected to take more than 1 second
  static bool shouldShowLoadingScreen({
    required Duration expectedDuration,
    Duration threshold = const Duration(milliseconds: 1000),
  }) {
    return expectedDuration > threshold;
  }
  
  /// Reset all splash screen statuses (for testing purposes)
  static Future<void> resetAllSplashStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_splashShownKey);
    await prefs.remove(_welcomeShownKey);
    await prefs.remove(_lastLoginTimeKey);
  }
  
  /// Reset only initial splash screen status
  static Future<void> resetSplashStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_splashShownKey);
  }
  
  /// Reset welcome splash status (force welcome splash on next login)
  static Future<void> resetWelcomeSplashStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_welcomeShownKey);
  }
  
  /// Get the type of splash screen that should be shown
  static Future<SplashScreenType?> getRequiredSplashScreen({
    required bool isAuthenticated,
    required bool isInitialAppLaunch,
  }) async {
    // If it's initial app launch and splash hasn't been shown
    if (isInitialAppLaunch && !(await hasSplashBeenShown())) {
      return SplashScreenType.initial;
    }
    
    // If user just logged in and should see welcome splash
    if (isAuthenticated && await shouldShowWelcomeSplash()) {
      return SplashScreenType.welcome;
    }
    
    return null; // No splash screen needed
  }
}