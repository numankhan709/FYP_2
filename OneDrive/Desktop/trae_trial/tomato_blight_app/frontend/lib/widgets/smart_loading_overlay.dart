import 'package:flutter/material.dart';

class SmartLoadingOverlay extends StatefulWidget {
  final Widget child;
  final Future<dynamic>? future;
  final String? loadingMessage;
  final Duration minimumLoadingTime;
  final Duration delayBeforeShowing;
  final VoidCallback? onComplete;

  const SmartLoadingOverlay({
    super.key,
    required this.child,
    this.future,
    this.loadingMessage,
    this.minimumLoadingTime = const Duration(milliseconds: 500),
    this.delayBeforeShowing = const Duration(milliseconds: 300),
    this.onComplete,
  });

  @override
  State<SmartLoadingOverlay> createState() => _SmartLoadingOverlayState();
}

class _SmartLoadingOverlayState extends State<SmartLoadingOverlay>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _shouldShowLoading = false;
  late AnimationController _fadeController;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _handleFuture();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
  }

  void _handleFuture() async {
    if (widget.future == null) return;

    final startTime = DateTime.now();
    
    // Wait for the delay before showing loading
    await Future.delayed(widget.delayBeforeShowing);
    
    // Check if the future is still running
    if (mounted && _isLoading) {
      setState(() {
        _shouldShowLoading = true;
      });
      _fadeController.forward();
      _rotationController.repeat();
    }

    try {
      setState(() {
        _isLoading = true;
      });

      await widget.future;

      // Ensure minimum loading time for better UX
      final elapsedTime = DateTime.now().difference(startTime);
      if (elapsedTime < widget.minimumLoadingTime) {
        await Future.delayed(widget.minimumLoadingTime - elapsedTime);
      }
    } catch (e) {
      // Handle errors if needed
      print('SmartLoadingOverlay: Error in future - $e');
    } finally {
      if (mounted) {
        await _fadeController.reverse();
        setState(() {
          _isLoading = false;
          _shouldShowLoading = false;
        });
        _rotationController.stop();
        widget.onComplete?.call();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_shouldShowLoading)
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _rotationAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationAnimation.value * 2 * 3.14159,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).primaryColor,
                                      Theme.of(context).primaryColor.withOpacity(0.3),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.loadingMessage ?? 'Loading...',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Helper widget for easy integration
class SmartLoadingWrapper extends StatelessWidget {
  final Widget child;
  final String? loadingMessage;

  const SmartLoadingWrapper({
    super.key,
    required this.child,
    this.loadingMessage,
  });

  /// Show loading overlay for a specific future
  static Future<T> showForFuture<T>({
    required BuildContext context,
    required Future<T> future,
    String? loadingMessage,
    Duration? expectedDuration,
  }) async {
    // Decide whether to show loading overlay based on expected duration threshold
    // If the expected duration is very short, skip showing the overlay to avoid flicker
    const Duration threshold = Duration(milliseconds: 300);
    if (expectedDuration != null && expectedDuration < threshold) {
      return await future;
    }

    // Show loading overlay
    return await showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SmartLoadingOverlay(
        future: future,
        loadingMessage: loadingMessage,
        child: const SizedBox.shrink(),
      ),
    ) ?? await future;
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

// Extension for easy use with any widget
extension SmartLoadingExtension on Widget {
  Widget withSmartLoading({
    Future<dynamic>? future,
    String? loadingMessage,
    Duration? minimumLoadingTime,
    Duration? delayBeforeShowing,
    VoidCallback? onComplete,
  }) {
    return SmartLoadingOverlay(
      future: future,
      loadingMessage: loadingMessage,
      minimumLoadingTime: minimumLoadingTime ?? const Duration(milliseconds: 500),
      delayBeforeShowing: delayBeforeShowing ?? const Duration(milliseconds: 300),
      onComplete: onComplete,
      child: this,
    );
  }
}