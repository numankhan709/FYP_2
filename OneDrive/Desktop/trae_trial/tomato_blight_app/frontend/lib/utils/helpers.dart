import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'constants.dart';

class ValidationHelper {
  static bool isValidEmail(String email) {
    return RegExp(ValidationConstants.emailPattern).hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= ValidationConstants.minPasswordLength &&
           password.length <= ValidationConstants.maxPasswordLength;
  }

  static bool isValidName(String name) {
    return name.trim().length >= ValidationConstants.minNameLength &&
           name.trim().length <= ValidationConstants.maxNameLength;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationConstants.emailRequiredError;
    }
    if (!isValidEmail(value)) {
      return ValidationConstants.emailInvalidError;
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationConstants.passwordRequiredError;
    }
    if (value.length < ValidationConstants.minPasswordLength) {
      return ValidationConstants.passwordTooShortError;
    }
    if (value.length > ValidationConstants.maxPasswordLength) {
      return ValidationConstants.passwordTooLongError;
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationConstants.nameRequiredError;
    }
    if (value.trim().length < ValidationConstants.minNameLength) {
      return ValidationConstants.nameTooShortError;
    }
    if (value.trim().length > ValidationConstants.maxNameLength) {
      return ValidationConstants.nameTooLongError;
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return ValidationConstants.passwordRequiredError;
    }
    if (value != password) {
      return ValidationConstants.passwordMismatchError;
    }
    return null;
  }
}

class DateTimeHelper {
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return formatDate(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
           date.month == yesterday.month &&
           date.day == yesterday.day;
  }

  static String formatDateForFilename(DateTime date) {
    return DateFormat('yyyy-MM-dd_HH-mm-ss').format(date);
  }
}

class FileHelper {
  static bool isValidImageFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return AppConstants.supportedImageFormats.contains(extension);
  }

  static Future<bool> isFileSizeValid(File file) async {
    final fileSize = await file.length();
    return fileSize <= AppConstants.maxImageSizeBytes;
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  static String getFileExtension(String filePath) {
    return filePath.split('.').last.toLowerCase();
  }
}

class LocationHelper {
  static Future<bool> requestLocationPermission() async {
    final permission = await Permission.location.request();
    return permission.isGranted;
  }

  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }
}

class ColorHelper {
  static Color getRiskLevelColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return const Color(UIConstants.successColorValue);
      case 'medium':
        return const Color(UIConstants.warningColorValue);
      case 'high':
        return const Color(UIConstants.errorColorValue);
      case 'critical':
        return const Color(0xFF006400); // Dark green for critical
      default:
        return Colors.grey;
    }
  }

  static Color getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return const Color(UIConstants.successColorValue);
    } else if (confidence >= 0.6) {
      return const Color(UIConstants.warningColorValue);
    } else {
      return const Color(UIConstants.errorColorValue);
    }
  }

  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }

  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

class NumberHelper {
  static String formatPercentage(double value, {int decimals = 1}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  static String formatTemperature(double celsius, {bool showUnit = true}) {
    final rounded = celsius.round();
    return showUnit ? '$rounded°C' : rounded.toString();
  }

  static String formatHumidity(double humidity, {bool showUnit = true}) {
    final rounded = humidity.round();
    return showUnit ? '$rounded%' : rounded.toString();
  }

  static String formatWindSpeed(double mps, {bool showUnit = true}) {
    final kmh = (mps * 3.6).round();
    return showUnit ? '$kmh km/h' : kmh.toString();
  }

  static double roundToDecimals(double value, int decimals) {
    final factor = pow(10, decimals);
    return (value * factor).round() / factor;
  }
}

class StringHelper {
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String capitalizeWords(String text) {
    return text.split(' ').map(capitalize).join(' ');
  }

  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - suffix.length) + suffix;
  }

  static String removeExtraSpaces(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool isNullOrEmpty(String? text) {
    return text == null || text.trim().isEmpty;
  }
}

class ErrorHelper {
  static String getErrorMessage(dynamic error) {
    if (error is SocketException) {
      return ValidationConstants.networkError;
    } else if (error is FormatException) {
      return ValidationConstants.serverError;
    } else if (error.toString().contains('timeout')) {
      return ValidationConstants.timeoutError;
    } else {
      return ValidationConstants.unknownError;
    }
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(UIConstants.errorColorValue),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(UIConstants.paddingMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(UIConstants.successColorValue),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(UIConstants.paddingMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
        ),
      ),
    );
  }
}

class DeviceHelper {
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diagonal = sqrt(pow(size.width, 2) + pow(size.height, 2));
    return diagonal > 1100;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
}