import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../utils/constants.dart';

class BackArrow extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;

  const BackArrow({
    super.key,
    this.onPressed,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return IconButton(
      icon: Icon(
        Icons.arrow_back,
        color: color ?? (isDark ? AppColors.textDark : AppColors.neutralWhite),
        size: size ?? 24,
      ),
      onPressed: onPressed ?? () {
        if (context.canPop()) {
          context.pop();
        } else {
          // If can't pop, go to home
          context.go(RouteConstants.home);
        }
      },
      tooltip: 'Back',
    );
  }
}