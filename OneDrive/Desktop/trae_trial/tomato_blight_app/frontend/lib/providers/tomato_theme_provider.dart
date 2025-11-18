import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';

class TomatoThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  TomatoThemeProvider() {
    _loadThemePreference();
  }
  
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }
  
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
  // Using AppColors for consistent theming

  ThemeData get currentTheme => _isDarkMode ? _buildTomatoDarkTheme() : _buildTomatoTheme();

  ThemeData _buildTomatoTheme() {
    return ThemeData(
      primarySwatch: _createMaterialColor(AppColors.primaryLight),
      primaryColor: AppColors.primaryLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryLight,
        brightness: Brightness.light,
        primary: AppColors.primaryLight,
        onPrimary: Colors.white,
        secondary: AppColors.secondaryLight,
        onSecondary: Colors.white,
        tertiary: AppColors.accentGreenLight,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textLight,
        surfaceVariant: AppColors.backgroundLight,
        onSurfaceVariant: AppColors.textLight,
        error: AppColors.error,
      ),
      useMaterial3: true,
      
      // Scaffold background with light gray
      scaffoldBackgroundColor: AppColors.backgroundLight,
      
      // App Bar Theme with tomato red styling
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: AppColors.primaryLight.withOpacity(0.3),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      
      // Card Theme with clean white styling
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 4,
        shadowColor: AppColors.primaryLight.withOpacity(0.15),
        surfaceTintColor: AppColors.backgroundLight.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.backgroundLight,
            width: 1.5,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Elevated Button Theme with vibrant coral-red styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.textLight.withOpacity(0.12),
          disabledForegroundColor: AppColors.textLight.withOpacity(0.38),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          shadowColor: AppColors.primaryLight.withOpacity(0.3),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.hovered)) {
                return AppColors.primaryLight.withOpacity(0.08);
              }
              if (states.contains(WidgetState.pressed)) {
                return AppColors.primaryLight.withOpacity(0.12);
              }
              return null;
            },
          ),
        ),
      ),
      
      // Text Button Theme with coral-red styling
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFE53E3E), // Coral-red instead of green
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input Decoration Theme with white + green styling
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.backgroundLight, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.backgroundLight, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryLight, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(
          color: AppColors.textLight,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: AppColors.textLight.withOpacity(0.6),
          fontSize: 16,
        ),
        errorStyle: TextStyle(
          color: AppColors.error,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Floating Action Button Theme with vibrant coral-red styling
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: const CircleBorder(),
      ),
      
      // Bottom Navigation Bar Theme with professional styling
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryLight, // Tomato red
          unselectedItemColor: AppColors.textLight,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
      
      // Professional Text Theme with proper hierarchy
      textTheme: TextTheme(
        // Display styles for hero content
        displayLarge: TextStyle(
          color: AppColors.textLight,
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          height: 1.12,
        ),
        displayMedium: TextStyle(
          color: AppColors.textLight,
          fontSize: 45,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.16,
        ),
        displaySmall: TextStyle(
          color: AppColors.textLight,
          fontSize: 36,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.22,
        ),
        
        // Headline styles for section headers
        headlineLarge: TextStyle(
          color: AppColors.textLight,
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.25,
        ),
        headlineMedium: TextStyle(
          color: AppColors.primaryLight,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.29,
        ),
        headlineSmall: TextStyle(
          color: AppColors.primaryLight,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.33,
        ),
        
        // Title styles for card headers and important content
        titleLarge: TextStyle(
          color: AppColors.textLight,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.27,
        ),
        titleMedium: TextStyle(
          color: AppColors.textLight,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          height: 1.50,
        ),
        titleSmall: TextStyle(
          color: AppColors.textLight,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.43,
        ),
        
        // Body text for main content
        bodyLarge: TextStyle(
          color: AppColors.textLight,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          height: 1.50,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textLight,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          height: 1.43,
        ),
        bodySmall: TextStyle(
          color: AppColors.textLight,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          height: 1.33,
        ),
        
        // Label styles for buttons and form labels
        labelLarge: TextStyle(
          color: AppColors.textLight,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.43,
        ),
        labelMedium: TextStyle(
          color: AppColors.textLight,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          height: 1.33,
        ),
        labelSmall: TextStyle(
          color: AppColors.textLight,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          height: 1.45,
        ),
      ),
      
      // Icon Theme with professional styling
      iconTheme: IconThemeData(
        color: AppColors.primaryLight, // Tomato red
        size: 24,
      ),
      
      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),
      
      // Additional professional theme configurations
      dividerTheme: DividerThemeData(
        color: AppColors.textLight.withOpacity(0.12),
        thickness: 1,
        space: 1,
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundLight,
        selectedColor: AppColors.primaryLight.withOpacity(0.12),
        disabledColor: AppColors.textLight.withOpacity(0.12),
        deleteIconColor: Colors.grey[600],
        labelStyle: TextStyle(
          color: AppColors.textLight,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: AppColors.textLight,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        brightness: Brightness.light,
      ),
    );
  }

  // Helper method to create MaterialColor from Color
  MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }

  // Method to get professional gradient for backgrounds
  static BoxDecoration getProfessionalGradientDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryLight,     // Primary tomato-red on top
          AppColors.accentGoldLight,   // Golden yellow in middle
          AppColors.secondaryLight, // Forest green on end
        ],
        stops: [0.0, 0.5, 1.0],
      ),
    );
  }

  // Method to get a subtle gradient for cards/containers
  static BoxDecoration getCardGradientDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          AppColors.backgroundLight.withOpacity(0.3),
          AppColors.primaryLight.withOpacity(0.05),
        ],
        stops: const [0.0, 0.6, 1.0],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppColors.backgroundLight,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.textLight.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Method to get accent gradient for special elements
  static BoxDecoration getAccentGradientDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryLight,      // Primary tomato-red
          AppColors.accentGoldLight,    // Golden yellow accent
          AppColors.secondaryLight,  // Forest green secondary
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.circular(12),
    );
  }

  ThemeData _buildTomatoDarkTheme() {
    return ThemeData(
      primarySwatch: _createMaterialColor(AppColors.primaryDark),
      primaryColor: AppColors.primaryDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryDark,
        brightness: Brightness.dark,
        primary: AppColors.primaryDark,
        onPrimary: Colors.white,
        secondary: AppColors.secondaryDark,
        onSecondary: Colors.white,
        tertiary: AppColors.accentGreenDark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textDark,
        background: AppColors.backgroundDark,
        onBackground: AppColors.textDark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.surfaceDark,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColors.backgroundDark,
        surfaceTintColor: AppColors.primaryDark.withOpacity(0.1),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: AppColors.textDark),
        displayMedium: TextStyle(color: AppColors.textDark),
        displaySmall: TextStyle(color: AppColors.textDark),
        headlineLarge: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: AppColors.textDark),
        titleLarge: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: AppColors.textDark),
        titleSmall: TextStyle(color: AppColors.textSecondaryDark),
        bodyLarge: TextStyle(color: AppColors.textDark),
        bodyMedium: TextStyle(color: AppColors.textDark),
        bodySmall: TextStyle(color: AppColors.textSecondaryDark),
        labelLarge: TextStyle(color: AppColors.textDark),
        labelMedium: TextStyle(color: AppColors.textSecondaryDark),
        labelSmall: TextStyle(color: AppColors.textSecondaryDark),
      ),
      iconTheme: IconThemeData(
        color: AppColors.iconDark,
        size: 24,
      ),
      primaryIconTheme: IconThemeData(
        color: AppColors.iconSecondaryDark,
        size: 24,
      ),
    );
  }
}