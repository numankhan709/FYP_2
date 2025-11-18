import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // Define the main app pages in order
  static const List<String> _mainPages = [
    RouteConstants.home,
    RouteConstants.scan,
    RouteConstants.diseases,
    RouteConstants.history,
    RouteConstants.weather,
    RouteConstants.about,
  ];

  // Get the current page index
  int getCurrentPageIndex(String currentRoute) {
    return _mainPages.indexOf(currentRoute);
  }

  // Check if there's a previous page
  bool hasPreviousPage(String currentRoute) {
    final currentIndex = getCurrentPageIndex(currentRoute);
    return currentIndex > 0;
  }

  // Check if there's a next page
  bool hasNextPage(String currentRoute) {
    final currentIndex = getCurrentPageIndex(currentRoute);
    return currentIndex >= 0 && currentIndex < _mainPages.length - 1;
  }

  // Get the previous page route
  String? getPreviousPage(String currentRoute) {
    final currentIndex = getCurrentPageIndex(currentRoute);
    if (currentIndex > 0) {
      return _mainPages[currentIndex - 1];
    }
    return null;
  }

  // Get the next page route
  String? getNextPage(String currentRoute) {
    final currentIndex = getCurrentPageIndex(currentRoute);
    if (currentIndex >= 0 && currentIndex < _mainPages.length - 1) {
      return _mainPages[currentIndex + 1];
    }
    return null;
  }

  // Navigate to previous page
  void goToPreviousPage(BuildContext context, String currentRoute) {
    final previousPage = getPreviousPage(currentRoute);
    if (previousPage != null) {
      context.go(previousPage);
    }
  }

  // Navigate to next page
  void goToNextPage(BuildContext context, String currentRoute) {
    final nextPage = getNextPage(currentRoute);
    if (nextPage != null) {
      context.go(nextPage);
    }
  }

  // Get page title for display
  String getPageTitle(String route) {
    switch (route) {
      case RouteConstants.home:
        return 'Home';
      case RouteConstants.scan:
        return 'Scan';
      case RouteConstants.diseases:
        return 'Diseases';
      case RouteConstants.history:
        return 'History';
      case RouteConstants.weather:
        return 'Weather';
      case RouteConstants.about:
        return 'About';
      default:
        return 'Unknown';
    }
  }

  // Get all main pages
  List<String> get mainPages => List.unmodifiable(_mainPages);
}