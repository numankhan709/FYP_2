import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryLight,
      brightness: Brightness.light,
      primary: AppColors.primaryLight,
      primaryContainer: AppColors.primaryRedLight,
      secondary: AppColors.secondaryLight,
      secondaryContainer: AppColors.accentGreenLight,
      tertiary: AppColors.tertiaryLight,
      tertiaryContainer: AppColors.accentGoldLight,
      surface: AppColors.surfaceLight,
      surfaceVariant: AppColors.neutralMedium,
      background: AppColors.backgroundLight,
      error: AppColors.error,
      errorContainer: AppColors.errorLight,
      onPrimary: AppColors.neutralWhite,
      onPrimaryContainer: AppColors.primaryRedDark,
      onSecondary: AppColors.neutralWhite,
      onSecondaryContainer: AppColors.accentGreenDark,
      onTertiary: AppColors.neutralWhite,
      onTertiaryContainer: AppColors.neutralCharcoal,
      onSurface: AppColors.textLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      onBackground: AppColors.textLight,
      onError: AppColors.neutralWhite,
      onErrorContainer: AppColors.error,
      outline: AppColors.neutralMedium,
      outlineVariant: AppColors.neutralLight,
      shadow: AppColors.neutralCharcoal.withOpacity(0.1),
      scrim: AppColors.neutralBlack.withOpacity(0.5),
      inverseSurface: AppColors.neutralCharcoal,
      onInverseSurface: AppColors.neutralLight,
      inversePrimary: AppColors.primaryRedLight,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    
    // App Bar Theme - Modern and elegant
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: AppColors.neutralWhite,
      elevation: 0,
      shadowColor: AppColors.neutralCharcoal.withOpacity(0.1),
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.neutralWhite,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(
        color: AppColors.neutralWhite,
        size: 24,
      ),
      actionsIconTheme: IconThemeData(
        color: AppColors.neutralWhite,
        size: 24,
      ),
    ),
    
    // Text Theme - Enhanced typography
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: AppColors.textLight,
        fontWeight: FontWeight.w800,
        fontSize: 57,
        letterSpacing: -0.25,
        height: 1.12,
      ),
      displayMedium: TextStyle(
        color: AppColors.textLight,
        fontWeight: FontWeight.w700,
        fontSize: 45,
        letterSpacing: 0,
        height: 1.16,
      ),
      displaySmall: TextStyle(
        color: AppColors.textLight,
        fontWeight: FontWeight.w600,
        fontSize: 36,
        letterSpacing: 0,
        height: 1.22,
      ),
      headlineLarge: TextStyle(
        color: AppColors.textLight,
        fontWeight: FontWeight.w700,
        fontSize: 32,
        letterSpacing: 0,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        color: AppColors.primaryLight,
        fontWeight: FontWeight.w600,
        fontSize: 28,
        letterSpacing: 0,
        height: 1.29,
      ),
      headlineSmall: TextStyle(
        color: AppColors.primaryLight,
        fontWeight: FontWeight.w600,
        fontSize: 24,
        letterSpacing: 0,
        height: 1.33,
      ),
      titleLarge: TextStyle(
        color: AppColors.textLight,
        fontWeight: FontWeight.w600,
        fontSize: 22,
        letterSpacing: 0,
        height: 1.27,
      ),
      titleMedium: TextStyle(
        color: AppColors.textLight,
        fontWeight: FontWeight.w500,
        fontSize: 16,
        letterSpacing: 0.15,
        height: 1.50,
      ),
      titleSmall: TextStyle(
        color: AppColors.textSecondaryLight,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      bodyLarge: TextStyle(
        color: AppColors.textLight,
        fontWeight: FontWeight.w400,
        fontSize: 16,
        letterSpacing: 0.5,
        height: 1.50,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textLight,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        letterSpacing: 0.25,
        height: 1.43,
      ),
      bodySmall: TextStyle(
        color: AppColors.textSecondaryLight,
        fontWeight: FontWeight.w400,
        fontSize: 12,
        letterSpacing: 0.4,
        height: 1.33,
      ),
      labelLarge: TextStyle(
        color: AppColors.textLight,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      labelMedium: TextStyle(
        color: AppColors.textSecondaryLight,
        fontWeight: FontWeight.w500,
        fontSize: 12,
        letterSpacing: 0.5,
        height: 1.33,
      ),
      labelSmall: TextStyle(
        color: AppColors.textSecondaryLight,
        fontWeight: FontWeight.w500,
        fontSize: 11,
        letterSpacing: 0.5,
        height: 1.45,
      ),
    ),
    
    // Elevated Button Theme - Modern and professional
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.neutralWhite,
        elevation: 3,
        shadowColor: AppColors.primaryLight.withOpacity(0.3),
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        minimumSize: Size(120, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.hovered)) {
              return AppColors.neutralWhite.withOpacity(0.1);
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.neutralWhite.withOpacity(0.2);
            }
            return null;
          },
        ),
      ),
    ),
    
    // Outlined Button Theme - Elegant borders
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        side: BorderSide(color: AppColors.primaryLight, width: 2),
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        minimumSize: Size(120, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: TextStyle(
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
    
    // Text Button Theme - Clean and minimal
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: Size(80, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.25,
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
    
    // Card Theme - Modern elevated cards
    cardTheme: CardTheme(
      elevation: 6,
      shadowColor: AppColors.neutralDark.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: AppColors.neutralWhite,
      surfaceTintColor: AppColors.primaryLight.withOpacity(0.02),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    // Input Decoration Theme - Professional form styling
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.neutralLight.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.neutralMedium, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.neutralMedium, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryLight, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.errorLight, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.errorLight, width: 2.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: TextStyle(
        color: AppColors.neutralMedium,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: TextStyle(
        color: AppColors.neutralDark,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        color: AppColors.primaryLight,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
    
    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: CircleBorder(),
    ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.textLight.withOpacity(0.6),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    
    // Icon Theme
    iconTheme: IconThemeData(
      color: AppColors.textLight,
      size: 24,
    ),
    
    // Divider Theme
    dividerTheme: DividerThemeData(
      color: AppColors.textLight.withOpacity(0.2),
      thickness: 1,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryDark,
      brightness: Brightness.dark,
      primary: AppColors.primaryDark,
      secondary: AppColors.secondaryDark,
      tertiary: AppColors.accentGreenDark,
      primaryContainer: AppColors.primaryDark.withOpacity(0.3),
      secondaryContainer: AppColors.secondaryDark.withOpacity(0.3),
      tertiaryContainer: AppColors.accentGreenDark.withOpacity(0.3),
      surface: AppColors.surfaceDark,
      surfaceVariant: AppColors.neutralDark.withOpacity(0.8),
      background: AppColors.backgroundDark,
      error: AppColors.error,
      errorContainer: AppColors.error.withOpacity(0.3),
      onPrimary: AppColors.neutralWhite,
      onSecondary: AppColors.neutralWhite,
      onTertiary: AppColors.neutralWhite,
      onSurface: AppColors.textDark,
      onBackground: AppColors.textDark,
      onError: AppColors.neutralWhite,
      outline: AppColors.neutralMedium,
      shadow: AppColors.neutralDark.withOpacity(0.5),
      scrim: AppColors.neutralDark.withOpacity(0.8),
      inverseSurface: AppColors.neutralWhite,
      inversePrimary: AppColors.primaryLight,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    
    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    
    // Text Theme
    textTheme: TextTheme(
      displayLarge: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: AppColors.textSecondaryDark, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: AppColors.textDark),
      bodyMedium: TextStyle(color: AppColors.textDark),
      bodySmall: TextStyle(color: AppColors.textSecondaryDark),
      labelLarge: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(color: AppColors.textSecondaryDark, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(color: AppColors.textSecondaryDark, fontWeight: FontWeight.w500),
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        side: BorderSide(color: AppColors.primaryDark),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    
    // Card Theme
    cardTheme: CardTheme(
      color: AppColors.surfaceDark,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primaryDark.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primaryDark.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primaryDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.error),
      ),
      labelStyle: TextStyle(color: AppColors.textDark.withOpacity(0.7)),
      hintStyle: TextStyle(color: AppColors.textDark.withOpacity(0.5)),
    ),
    
    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: CircleBorder(),
    ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.primaryDark,
      unselectedItemColor: AppColors.iconDark,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    
    // Icon Theme
    iconTheme: IconThemeData(
      color: AppColors.iconDark,
      size: 24,
    ),
    
    // Divider Theme
    dividerTheme: DividerThemeData(
      color: AppColors.textDark.withOpacity(0.2),
      thickness: 1,
    ),
  );
}