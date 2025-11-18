import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'providers/disease_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/tomato_theme_provider.dart';
import 'theme/app_theme.dart';
// import 'screens/splash_screen.dart';
// import 'widgets/welcome_splash_screen.dart';
// import 'services/splash_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/scan_result_screen.dart';
import 'screens/diseases_screen.dart';
import 'screens/history_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/weather/weather_screen.dart';
import 'screens/about_screen.dart';
import 'screens/risk_assessment_screen.dart';
// import 'services/splash_service.dart';
import 'utils/constants.dart';

void main() {
  runApp(const TomatoCareApp());
}

class TomatoCareApp extends StatelessWidget {
  const TomatoCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DiseaseProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TomatoThemeProvider()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, child) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode, // Use ThemeProvider for dynamic theme switching
            routerConfig: _buildRouter(authProvider),
          );
        },
      ),
    );
  }



  GoRouter _buildRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: RouteConstants.home,
      refreshListenable: authProvider.routerListenable,
      redirect: (context, state) async {
        // Wait until auth provider initializes
        if (!authProvider.isInitialized) {
          return null;
        }

        final isLoggedIn = authProvider.isAuthenticated;
        final currentLocation = state.matchedLocation;

        // If user is logged in and on auth screens, go to home
        if (isLoggedIn && (currentLocation == RouteConstants.login || currentLocation == RouteConstants.signup)) {
          return RouteConstants.home;
        }

        // Public routes that don't require authentication
        final publicRoutes = [
          RouteConstants.login,
          RouteConstants.signup,
          RouteConstants.resetPassword,
        ];

        // If user is not logged in and trying to access protected routes, redirect to login
        if (!isLoggedIn && !publicRoutes.contains(currentLocation)) {
          return RouteConstants.login;
        }

        // Allow navigation to public routes and valid authenticated routes
        return null;
      },
      routes: [
        // Splash routes removed
        // GoRoute(
        //   path: RouteConstants.splash,
        //   builder: (context, state) => const SplashScreen(),
        // ),
        
        // Welcome Splash Screen removed
        // GoRoute(
        //   path:RouteConstants.welcomeSplash,
        //   pageBuilder: (context, state) {
        //     return _buildPageWithFadeTransition(
        //       context, 
        //       state, 
        //       Consumer<AuthProvider>(
        //         builder: (context, authProvider, child) {
        //           final userName = authProvider.user?.name ?? 'User';
        //           return WelcomeSplashScreen(
        //             userName: userName,
        //             onComplete: () async {
        //               // Mark welcome splash as shown
        //               await SplashService.markWelcomeSplashShown();
        //               // Navigate to home
        //               if (context.mounted) {
        //                 context.go(RouteConstants.home);
        //               }
        //             },
        //           );
        //         },
        //       ),
        //     );
        //   },
        // ),
        
        // Authentication Routes (fade transition)
        GoRoute(
          path: RouteConstants.login,
          pageBuilder: (context, state) => _buildPageWithFadeTransition(
            context, state, const LoginScreen(),
          ),
        ),
        GoRoute(
          path: RouteConstants.signup,
          pageBuilder: (context, state) => _buildPageWithFadeTransition(
            context, state, const SignupScreen(),
          ),
        ),
        GoRoute(
          path: RouteConstants.resetPassword,
          pageBuilder: (context, state) {
            return _buildPageWithFadeTransition(
              context,
              state,
              ResetPasswordScreen(
                initialEmail: state.uri.queryParameters['email'],
              ),
            );
          },
        ),
        
        // Main App Routes (slide transition)
        GoRoute(
          path: RouteConstants.home,
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context, state, const HomeScreen(),
          ),
        ),
        GoRoute(
          path: RouteConstants.scan,
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context, state, const ScanScreen(),
          ),
        ),
        GoRoute(
          path: RouteConstants.scanResult,
          pageBuilder: (context, state) {
            final scanId = state.uri.queryParameters['scanId'] ?? '';
            return _buildPageWithSlideTransition(
              context, state, ScanResultScreen(scanId: scanId),
            );
          },
        ),
        GoRoute(
          path: RouteConstants.history,
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context, state, const HistoryScreen(),
          ),
        ),
        GoRoute(
          path: RouteConstants.reports,
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context, state, const ReportsScreen(),
          ),
        ),
        GoRoute(
          path: RouteConstants.diseases,
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context, state, const DiseasesScreen(),
          ),
        ),
        GoRoute(
          path: RouteConstants.weather,
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context, state, const WeatherScreen(),
          ),
        ),
        GoRoute(
          path: RouteConstants.riskAssessment,
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context, state, const RiskAssessmentScreen(),
          ),
        ),
        GoRoute(
          path: RouteConstants.about,
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context, state, const AboutScreen(),
          ),
        ),
      ],
      
      // Error handling
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Page Not Found'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Page Not Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The page "${state.matchedLocation}" could not be found.',
                style: const TextStyle(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(RouteConstants.home),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Beautiful fade transition for authentication screens
  Page<dynamic> _buildPageWithFadeTransition(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
          child: child,
        );
      },
    );
  }

  // Beautiful slide transition for main app screens
  Page<dynamic> _buildPageWithSlideTransition(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide from right to left
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        var offsetAnimation = animation.drive(tween);

        // Add a subtle fade effect
        var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
          ),
        );

        // Add scale effect for more modern feel
        var scaleAnimation = Tween(begin: 0.95, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
          ),
        );

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
