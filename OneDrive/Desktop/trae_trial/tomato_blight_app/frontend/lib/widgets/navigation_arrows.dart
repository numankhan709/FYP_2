import 'package:flutter/material.dart';
import '../services/navigation_service.dart';
import '../utils/constants.dart';

class NavigationArrows extends StatelessWidget {
  final String currentRoute;
  final bool showLabels;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;

  const NavigationArrows({
    super.key,
    required this.currentRoute,
    this.showLabels = true,
    this.iconSize = UIConstants.iconSizeLarge,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final navigationService = NavigationService();
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? theme.primaryColor.withOpacity(0.1);
    final effectiveIconColor = iconColor ?? theme.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.paddingMedium,
        vertical: UIConstants.paddingSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Page Button
          _buildNavigationButton(
            context: context,
            icon: Icons.arrow_back_ios,
            label: showLabels ? 'Previous' : null,
            isEnabled: navigationService.hasPreviousPage(currentRoute),
            onPressed: () => navigationService.goToPreviousPage(context, currentRoute),
            backgroundColor: effectiveBackgroundColor,
            iconColor: effectiveIconColor,
          ),

          // Page Indicator (optional)
          if (showLabels) _buildPageIndicator(context, navigationService),

          // Next Page Button
          _buildNavigationButton(
            context: context,
            icon: Icons.arrow_forward_ios,
            label: showLabels ? 'Next' : null,
            isEnabled: navigationService.hasNextPage(currentRoute),
            onPressed: () => navigationService.goToNextPage(context, currentRoute),
            backgroundColor: effectiveBackgroundColor,
            iconColor: effectiveIconColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required BuildContext context,
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color iconColor,
    String? label,
  }) {
    final theme = Theme.of(context);
    
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.3,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusLarge),
          child: Container(
            padding: const EdgeInsets.all(UIConstants.paddingSmall),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(UIConstants.borderRadiusLarge),
              border: Border.all(
                color: iconColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: iconSize,
                  color: isEnabled ? iconColor : iconColor.withOpacity(0.5),
                ),
                if (label != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isEnabled ? iconColor : iconColor.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(BuildContext context, NavigationService navigationService) {
    final theme = Theme.of(context);
    final currentIndex = navigationService.getCurrentPageIndex(currentRoute);
    final totalPages = navigationService.mainPages.length;
    
    if (currentIndex < 0) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          navigationService.getPageTitle(currentRoute),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${currentIndex + 1} of $totalPages',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.primaryColor.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        // Page dots indicator
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(totalPages, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == currentIndex
                    ? theme.primaryColor
                    : theme.primaryColor.withOpacity(0.3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// Compact version for smaller spaces
class CompactNavigationArrows extends StatelessWidget {
  final String currentRoute;
  final Color? iconColor;

  const CompactNavigationArrows({
    super.key,
    required this.currentRoute,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationArrows(
      currentRoute: currentRoute,
      showLabels: false,
      iconSize: UIConstants.iconSizeMedium,
      backgroundColor: Colors.transparent,
      iconColor: iconColor,
    );
  }
}