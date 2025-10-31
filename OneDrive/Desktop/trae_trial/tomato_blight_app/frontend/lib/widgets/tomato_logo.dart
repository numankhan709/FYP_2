import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TomatoLogo extends StatelessWidget {
  final double size;
  final Color? color;
  
  const TomatoLogo({
    super.key,
    this.size = 60,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SvgPicture.asset(
        'assets/images/tomato_logo.svg',
        width: size,
        height: size,
        colorFilter: color != null 
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
      ),
    );
  }
}

// Fallback widget if SVG is not available
class TomatoIconFallback extends StatelessWidget {
  final double size;
  final Color? color;
  
  const TomatoIconFallback({
    super.key,
    this.size = 60,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B35), // Tomato red
            Color(0xFFE55A2B), // Darker tomato red
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.agriculture,
        size: size * 0.6,
        color: color ?? Colors.white,
      ),
    );
  }
}