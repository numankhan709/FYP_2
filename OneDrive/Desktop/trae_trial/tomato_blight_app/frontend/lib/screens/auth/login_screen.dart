import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../constants/app_colors.dart';
import '../../services/splash_service.dart';

class LeafIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Main leaf shape
    final leafPath = Path();
    leafPath.moveTo(size.width * 0.5, size.height * 0.1);
    leafPath.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.3,
      size.width * 0.85,
      size.height * 0.6,
    );
    leafPath.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.9,
      size.width * 0.5,
      size.height * 0.95,
    );
    leafPath.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.9,
      size.width * 0.15,
      size.height * 0.6,
    );
    leafPath.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.1,
    );
    leafPath.close();

    // Create gradient for the leaf using theme colors
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: [
        AppColors.primaryLight, // Primary green
        AppColors.accentGreenLight, // Accent green
        AppColors.primaryDark, // Darker green
      ],
      stops: [0.0, 0.6, 1.0],
    );

    paint.shader = gradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    canvas.drawPath(leafPath, paint);

    // Paint for the main vein using theme colors
    final mainVeinPaint = Paint()
      ..color = AppColors.primaryDark.withOpacity(0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final veinPath = Path();
    veinPath.moveTo(size.width * 0.5, size.height * 0.15);
    veinPath.quadraticBezierTo(
      size.width * 0.52,
      size.height * 0.5,
      size.width * 0.5,
      size.height * 0.85,
    );

    canvas.drawPath(veinPath, mainVeinPaint);

    // Paint for side veins using theme colors
    final sideVeinPaint = Paint()
      ..color = AppColors.primaryDark.withOpacity(0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Left side veins
    for (int i = 0; i < 3; i++) {
      final y = size.height * (0.3 + i * 0.2);
      final leftVein = Path();
      leftVein.moveTo(size.width * 0.5, y);
      leftVein.quadraticBezierTo(
        size.width * 0.35,
        y + size.height * 0.05,
        size.width * 0.25,
        y + size.height * 0.1,
      );
      canvas.drawPath(leftVein, sideVeinPaint);
    }

    // Right side veins
    for (int i = 0; i < 3; i++) {
      final y = size.height * (0.3 + i * 0.2);
      final rightVein = Path();
      rightVein.moveTo(size.width * 0.5, y);
      rightVein.quadraticBezierTo(
        size.width * 0.65,
        y + size.height * 0.05,
        size.width * 0.75,
        y + size.height * 0.1,
      );
      canvas.drawPath(rightVein, sideVeinPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CurvedSeparatorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Create gradient for smooth transition using theme colors
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.backgroundLight.withOpacity(0.0), // Light background start
        AppColors.neutralMedium.withOpacity(0.3), // Medium neutral
        AppColors.surfaceLight, // Light surface color
      ],
      stops: [0.0, 0.3, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.7);
    
    // Create a more elegant curved transition
    path.cubicTo(
      size.width * 0.15,
      size.height * 0.3,
      size.width * 0.35,
      size.height * 0.1,
      size.width * 0.5,
      size.height * 0.2,
    );
    path.cubicTo(
      size.width * 0.65,
      size.height * 0.3,
      size.width * 0.85,
      size.height * 0.1,
      size.width,
      size.height * 0.4,
    );
    
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Add subtle shadow effect using theme colors
    final shadowPaint = Paint()
      ..color = AppColors.primaryLight.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final shadowPath = Path();
    shadowPath.moveTo(0, size.height * 0.95);
    shadowPath.lineTo(0, size.height * 0.75);
    
    shadowPath.cubicTo(
      size.width * 0.15,
      size.height * 0.35,
      size.width * 0.35,
      size.height * 0.15,
      size.width * 0.5,
      size.height * 0.25,
    );
    shadowPath.cubicTo(
      size.width * 0.65,
      size.height * 0.35,
      size.width * 0.85,
      size.height * 0.15,
      size.width,
      size.height * 0.45,
    );
    
    shadowPath.lineTo(size.width, size.height * 0.95);
    shadowPath.close();

    canvas.drawPath(shadowPath, shadowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> 
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  double _loginProgress = 0.0;
  String _loginStatusText = '';
  bool _hasNavigated = false; // Flag to prevent multiple navigations
  
  late AnimationController _logoController;
  late AnimationController _logoRotationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _logoRotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeLogoAnimations();
    _startLogoAnimation();
  }
  
  @override
  void dispose() {
    _logoController.dispose();
    _logoRotationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _initializeLogoAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoRotationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5), // Start from top (matching splash exit)
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    ));

    _logoRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0, // Keep tomato straight head up
    ).animate(CurvedAnimation(
      parent: _logoRotationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startLogoAnimation() {
    // Small delay to create seamless transition feeling
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _logoController.forward();
        _logoRotationController.forward();
      }
    });
  }



  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _loginProgress = 0.0;
      _loginStatusText = 'Validating credentials...';
      _hasNavigated = false; // Reset navigation flag
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Simulate progress updates
      for (int i = 1; i <= 5; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          setState(() {
            _loginProgress = i / 5;
            switch (i) {
              case 1:
                _loginStatusText = 'Connecting to server...';
                break;
              case 2:
                _loginStatusText = 'Verifying credentials...';
                break;
              case 3:
                _loginStatusText = 'Authenticating user...';
                break;
              case 4:
                _loginStatusText = 'Setting up session...';
                break;
              case 5:
                _loginStatusText = 'Login successful!';
                break;
            }
          });
        }
      }

      final loginSuccess = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _loginStatusText = loginSuccess ? 'Welcome back!' : '';
        });
        
        if (loginSuccess) {
          // Check if welcome splash should be shown
          final shouldShowWelcome = await SplashService.shouldShowWelcomeSplash();
          
          if (shouldShowWelcome) {
            // Navigate to welcome splash screen
            if (mounted) {
              context.go(RouteConstants.welcomeSplash);
            }
          } else {
            // Navigate directly to home
            if (mounted) {
              context.go(RouteConstants.home);
            }
          }
        } else {
          // Show error message if login failed
          final errorMessage = authProvider.errorMessage ?? 'Login failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loginProgress = 0.0;
          _loginStatusText = '';
          _hasNavigated = false; // Reset on error
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProgress(double progress, String status) async {
    if (mounted) {
      setState(() {
        _loginProgress = progress;
        _loginStatusText = status;
      });
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? [
              AppColors.backgroundDark, // Dark background
              AppColors.surfaceDark, // Dark surface
              AppColors.neutralDark, // Dark neutral
            ] : [
              AppColors.backgroundLight, // Light background
              AppColors.surfaceLight, // Light surface
              AppColors.neutralWhite, // Pure white
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          MediaQuery.of(context).padding.bottom - 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Header with modern card design
                  _buildModernHeader(),
                  
                  const SizedBox(height: 32),
                  
                  // Login Form Card
                  _buildModernLoginCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Sign Up Link
                  _buildModernSignUpLink(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF228B22), // Primary forest green
            Color(0xFF006400), // Darker forest green
            Color(0xFF004000), // Deep green
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated Professional Logo
          SlideTransition(
            position: _logoSlideAnimation,
            child: ScaleTransition(
              scale: _logoScaleAnimation,
              child: RotationTransition(
                turns: _logoRotationAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isDark 
                          ? const Color(0xFF4A4A4A).withOpacity(0.3)
                          : Colors.white.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                    'assets/images/professional_logo.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          
          Text(
            'Tomato Guard',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: isDark 
                ? const Color(0xFFE0E0E0) 
                : Colors.white,
              letterSpacing: -0.5,
              shadows: [
                Shadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  color: isDark 
                    ? const Color(0xFF4A4A4A).withOpacity(0.6)
                    : Colors.black.withOpacity(0.3),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to continue protecting your tomatoes',
            style: TextStyle(
              fontSize: 16,
              color: isDark 
                ? const Color(0xFFB0B0B0) 
                : Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernLoginCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF2D2D2D) 
          : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email Field
            _buildModernTextField(
              controller: _emailController,
              hintText: 'Email Address',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: ValidationHelper.validateEmail,
            ),
            
            const SizedBox(height: 20),
            
            // Password Field
            _buildModernTextField(
              controller: _passwordController,
              hintText: 'Password',
              prefixIcon: Icons.lock_outline,
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.done,
              validator: ValidationHelper.validatePassword,
              onFieldSubmitted: (_) => _handleLogin(),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondary.withOpacity(0.7)
                    : const Color(0xFF718096),
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Remember Me and Forgot Password
            _buildRememberMeAndForgotPassword(),
            
            const SizedBox(height: 32),
            
            // Login Button
            _buildModernLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark 
          ? AppColors.backgroundDark.withOpacity(0.8)
          : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
            ? AppColors.neutralDark.withOpacity(0.3)
            : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        obscureText: obscureText,
        style: TextStyle(
          fontSize: 16,
          color: isDark 
            ? AppColors.textDark
            : const Color(0xFF1A202C),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDark 
              ? AppColors.textSecondary.withOpacity(0.7)
              : const Color(0xFF718096),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: isDark 
              ? AppColors.textSecondary.withOpacity(0.7)
              : const Color(0xFF718096),
            size: 20,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildRememberMeAndForgotPassword() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        Row(
          children: [
            Transform.scale(
              scale: 1.1,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                activeColor: const Color(0xFF228B22),
                checkColor: isDark 
                  ? const Color(0xFF1E1E1E) 
                  : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Remember me',
                style: TextStyle(
                  color: isDark 
                    ? AppColors.textDark
                    : const Color(0xFF4A5568),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              // TODO: Implement forgot password functionality
              ErrorHelper.showErrorSnackBar(
                context,
                'Forgot password feature coming soon!',
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Forgot Password?',
              style: TextStyle(
                color: Color(0xFF228B22), // Primary forest green
                fontSize: 15,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF228B22), // Primary forest green
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernLoginButton() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        // Progress bar (only visible when loading)
        if (_isLoading) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                LinearPercentIndicator(
                  width: MediaQuery.of(context).size.width - 48,
                  animation: true,
                  animationDuration: 300,
                  lineHeight: 8.0,
                  percent: _loginProgress,
                  center: Text(
                    '${(_loginProgress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark 
                        ? const Color(0xFF1E1E1E) 
                        : Colors.white,
                    ),
                  ),
                  linearStrokeCap: LinearStrokeCap.roundAll,
                  progressColor: const Color(0xFF228B22),
                  backgroundColor: const Color(0xFF228B22).withOpacity(0.2),
                  barRadius: const Radius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  _loginStatusText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondary
                      : const Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Login button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: _isLoading 
                ? null 
                : const LinearGradient(
                    colors: [Color(0xFF228B22), Color(0xFF32CD32)], // Primary forest green to light forest green
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: _isLoading ? const Color(0xFFE2E8F0) : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isLoading 
                ? null 
                : [
                    BoxShadow(
                      color: const Color(0xFF228B22).withOpacity(0.3), // Primary forest green shadow
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: isDark 
                ? const Color(0xFFE0E0E0) 
                : Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularPercentIndicator(
                        radius: 12.0,
                        lineWidth: 3.0,
                        animation: true,
                        percent: _loginProgress,
                        center: Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textSecondary
                            : const Color(0xFF718096),
                        ),
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: const Color(0xFF228B22),
                        backgroundColor: const Color(0xFF228B22).withOpacity(0.2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Signing In...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textSecondary
                            : const Color(0xFF718096),
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark 
                        ? const Color(0xFF1E1E1E) 
                        : Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernSignUpLink() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF2D2D2D) 
          : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textSecondary
                : const Color(0xFF718096),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          GestureDetector(
            onTap: () {
              context.go(RouteConstants.signup);
            },
            child: const Text(
              'Sign Up',
              style: TextStyle(
                color: Color(0xFF228B22), // Primary forest green
                fontSize: 15,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF228B22), // Primary forest green
              ),
            ),
          ),
        ],
      ),
    );
  }
}