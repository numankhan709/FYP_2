import 'package:flutter/material.dart';

// Beautiful Professional Color Palette for TomatoCare App
class AppColors {
  // === PRIMARY PALETTE ===
  // Forest Green - Professional and vibrant (changed from red to green)
  static const Color primaryRed = Color(0xFF228B22); // Primary forest green
  static const Color primaryRedLight = Color(0xFF32CD32); // Light forest green
  static const Color primaryRedDark = Color(0xFF006400); // Dark forest green
  
  // Sophisticated Green - Secondary accent
  static const Color accentGreen = Color(0xFF10B981); // Modern emerald
  static const Color accentGreenLight = Color(0xFF34D399); // Light emerald
  static const Color accentGreenDark = Color(0xFF059669); // Dark emerald
  
  // Premium Gold - Elegant accent
  static const Color accentGold = Color(0xFFF59E0B); // Amber-500
  static const Color accentGoldLight = Color(0xFFFBBF24); // Amber-400
  
  // === NEUTRAL PALETTE ===
  // Modern grays with perfect contrast
  static const Color neutralWhite = Color(0xFFFFFFFE); // Pure white
  static const Color neutralLight = Color(0xFFF8FAFC); // Slate-50
  static const Color neutralMedium = Color(0xFFE2E8F0); // Slate-200
  static const Color neutralDark = Color(0xFF475569); // Slate-600
  static const Color neutralCharcoal = Color(0xFF1E293B); // Slate-800
  static const Color neutralBlack = Color(0xFF0F172A); // Slate-900
  
  // === SEMANTIC COLORS ===
  static const Color success = Color(0xFF22C55E); // Green-500
  static const Color successLight = Color(0xFF86EFAC); // Green-300
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color warningLight = Color(0xFFFDE68A); // Amber-200
  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color errorLight = Color(0xFFFECACA); // Red-200
  static const Color info = Color(0xFF3B82F6); // Blue-500
  static const Color infoLight = Color(0xFFBFDBFE); // Blue-200
  
  // === LIGHT THEME COLORS ===
  static const Color primaryLight = primaryRed;
  static const Color secondaryLight = accentGreen;
  static const Color tertiaryLight = accentGold;
  static const Color backgroundLight = neutralWhite;
  static const Color surfaceLight = neutralLight;
  static const Color textLight = neutralCharcoal;
  static const Color textSecondaryLight = neutralDark;
  
  // === DARK THEME COLORS ===
  static const Color primaryDark = primaryRedLight;
  static const Color secondaryDark = accentGreenLight;
  static const Color tertiaryDark = accentGoldLight;
  static const Color backgroundDark = Color(0xFF000000); // Pure black
  static const Color surfaceDark = Color(0xFF121212); // Very dark grey for cards/surfaces
  static const Color textDark = Color(0xFFFFFFFF); // Pure white
  static const Color textSecondaryDark = Color(0xFFB0B0B0); // Light grey for secondary text
  static const Color iconDark = Color(0xFF808080); // Medium grey for icons
  static const Color iconSecondaryDark = Color(0xFF606060); // Darker grey for secondary icons
  
  // === UNIVERSAL TEXT COLORS (theme-aware) ===
  static const Color textPrimary = neutralCharcoal; // Primary text color
  static const Color textSecondary = neutralDark; // Secondary text color
  static const Color textTertiary = Color(0xFF94A3B8); // Slate-400 - Tertiary text
  
  // === GRADIENT COLORS ===
  static const List<Color> primaryGradient = [
    Color(0xFF228B22), // Primary forest green
    Color(0xFF006400), // Dark forest green
  ];
  
  static const List<Color> accentGradient = [
    Color(0xFF10B981), // Emerald
    Color(0xFF059669), // Dark emerald
  ];
  
  static const List<Color> backgroundGradient = [
    Color(0xFFF8FAFC), // Slate-50
    Color(0xFFFFFFFF), // White
  ];
  
  // === LEGACY SUPPORT (for backward compatibility) ===
  static const Color tomatoRed = primaryRed;
  static const Color leafGreen = accentGreen;
  static const Color sunsetYellow = accentGold;
  static const Color skyBlue = info;
  static const Color cloudWhite = neutralLight;
  static const Color deepCharcoal = neutralCharcoal;
  static const Color mossGreen = accentGreenDark;
  static const Color lightGray = neutralMedium;
}