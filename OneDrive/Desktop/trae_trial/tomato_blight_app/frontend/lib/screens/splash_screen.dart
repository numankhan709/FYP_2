import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/splash_service.dart';
import '../utils/constants.dart';
import '../constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with TickerProviderStateMixin {
  bool _isNavigating = false;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _backgroundController;
  late AnimationController _exitController;
  late AnimationController _pulseController;
  
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _exitFadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _startTimer();
  }

  void _initializeAnimations() {
    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Background animations
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Exit animations
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Pulse animation for logo
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Logo animations
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    ));

    // Text animations
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    // Background animation
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    // Exit animation
    _exitFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    if (!mounted) return;
    
    // Start background animation immediately
    _backgroundController.forward();
    
    // Start logo animation with slight delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _logoController.forward();
      }
    });
    
    // Start text animation after logo
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _textController.forward();
      }
    });
    
    // Start pulse animation after everything is visible
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _backgroundController.dispose();
    _exitController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() async {
    // Wait for 2.5 seconds then start exit animation
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted || _isNavigating) return;
    _isNavigating = true;

    // Stop pulse animation safely
    try {
      _pulseController.stop();
    } catch (e) {
      // Controller already disposed
    }
    
    // Start exit animation safely
    try {
      _exitController.forward();
    } catch (e) {
      // Controller already disposed
    }
    
    // Wait for exit animation to complete
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (!mounted) return;

    try {
      // Mark splash as shown
      await SplashService.markSplashAsShown();
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Wait for auth provider to be initialized
      while (!authProvider.isInitialized && mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      if (!mounted) return;

      // Navigate based on authentication status
      if (authProvider.isAuthenticated) {
        context.go(RouteConstants.home);
      } else {
        context.go(RouteConstants.login);
      }
    } catch (e) {
      // Navigate to login on error
      if (mounted) {
        context.go(RouteConstants.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: FadeTransition(
        opacity: _exitFadeAnimation,
        child: AnimatedBuilder(
          animation: _backgroundAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark ? [
                    Color.lerp(AppColors.primaryDark, AppColors.secondaryDark, _backgroundAnimation.value)!,
                    Color.lerp(AppColors.secondaryDark, AppColors.backgroundDark, _backgroundAnimation.value)!,
                    Color.lerp(AppColors.backgroundDark, AppColors.surfaceDark, _backgroundAnimation.value)!,
                  ] : [
                    Color.lerp(AppColors.primaryLight, AppColors.secondaryLight, _backgroundAnimation.value)!,
                    Color.lerp(AppColors.secondaryLight, AppColors.tertiaryLight, _backgroundAnimation.value)!,
                    Color.lerp(AppColors.tertiaryLight, AppColors.primaryLight, _backgroundAnimation.value)!,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Modern geometric background
                  Positioned.fill(
                    child: _buildModernBackground(),
                  ),
                  
                  // Main content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Professional Logo
                        SlideTransition(
                          position: _logoSlideAnimation,
                          child: FadeTransition(
                            opacity: _logoFadeAnimation,
                            child: ScaleTransition(
                              scale: _logoScaleAnimation,
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Container(
                                      width: 160,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: isDark 
                                              ? AppColors.iconDark.withOpacity(0.3)
                                              : AppColors.neutralWhite.withOpacity(0.2),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: SvgPicture.asset(
                                        'assets/images/professional_logo.svg',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 50),
                        
                        // App Title
                        SlideTransition(
                          position: _textSlideAnimation,
                          child: FadeTransition(
                            opacity: _textFadeAnimation,
                            child: Column(
                              children: [
                                Text(
                                  'Tomato Guard',
                                  style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w700,
                                    color: isDark 
                                      ? AppColors.textDark 
                                      : AppColors.neutralWhite,
                                    letterSpacing: 2.0,
                                    shadows: [
                                      Shadow(
                                        offset: const Offset(0, 4),
                                        blurRadius: 8,
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: isDark 
                                      ? AppColors.surfaceDark.withOpacity(0.3)
                                      : AppColors.neutralWhite.withOpacity(0.1),
                                    border: Border.all(
                                      color: isDark 
                                        ? AppColors.iconDark.withOpacity(0.4)
                                        : AppColors.neutralWhite.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'AI-Powered Plant Health Monitoring',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isDark 
                                        ? AppColors.textSecondaryDark
                                        : AppColors.neutralWhite.withOpacity(0.9),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 60),
                                
                                // Loading indicator
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDark ? AppColors.primaryDark : AppColors.primaryLight,
                                    ),
                                    backgroundColor: isDark 
                                      ? AppColors.iconDark.withOpacity(0.3)
                                      : AppColors.neutralWhite.withOpacity(0.2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Floating elements
                  Positioned.fill(
                    child: _buildFloatingElements(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernBackground() {
    return Stack(
      children: [
        // Geometric shapes with modern gradients
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryLight.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -120,
          right: -120,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondaryLight.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 150,
          right: -80,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryLight.withOpacity(0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Modern grid pattern
        Positioned.fill(
          child: CustomPaint(
            painter: ModernGridPainter(),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingElements() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return CustomPaint(
      painter: FloatingElementsPainter(isDark: isDark),
    );
  }
}

class ModernGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    
    // Draw vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class FloatingElementsPainter extends CustomPainter {
  final bool isDark;
  
  FloatingElementsPainter({required this.isDark});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Modern floating elements with theme colors
    final elements = [
      {'x': size.width * 0.1, 'y': size.height * 0.2, 'size': 6.0, 'opacity': 0.4, 'color': AppColors.primaryLight},
      {'x': size.width * 0.85, 'y': size.height * 0.15, 'size': 4.0, 'opacity': 0.3, 'color': AppColors.secondaryLight},
      {'x': size.width * 0.15, 'y': size.height * 0.75, 'size': 8.0, 'opacity': 0.2, 'color': AppColors.tertiaryLight},
      {'x': size.width * 0.9, 'y': size.height * 0.65, 'size': 5.0, 'opacity': 0.35, 'color': AppColors.accentGreen},
      {'x': size.width * 0.25, 'y': size.height * 0.1, 'size': 3.0, 'opacity': 0.5, 'color': AppColors.secondaryLight},
      {'x': size.width * 0.75, 'y': size.height * 0.85, 'size': 7.0, 'opacity': 0.25, 'color': AppColors.primaryLight},
    ];

    for (final element in elements) {
      paint.color = (element['color'] as Color).withOpacity(element['opacity'] as double);
      
      // Draw modern geometric shapes instead of circles
      final center = Offset(element['x'] as double, element['y'] as double);
      final size = element['size'] as double;
      
      // Alternate between circles and rounded rectangles
      if (elements.indexOf(element) % 2 == 0) {
        canvas.drawCircle(center, size, paint);
      } else {
        final rect = Rect.fromCenter(center: center, width: size * 1.5, height: size * 1.5);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(size * 0.3)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}