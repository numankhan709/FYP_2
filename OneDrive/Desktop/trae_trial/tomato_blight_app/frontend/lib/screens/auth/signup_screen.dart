import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../constants/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      ErrorHelper.showErrorSnackBar(
        context,
        'Please accept the terms and conditions to continue.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signup(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        ErrorHelper.showSuccessSnackBar(
          context,
          'Account created successfully! Welcome aboard!',
        );
        // Router will automatically redirect to home due to auth state change
      } else {
        ErrorHelper.showErrorSnackBar(
          context,
          authProvider.errorMessage ?? 'Signup failed. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHelper.showErrorSnackBar(
          context,
          ErrorHelper.getErrorMessage(e),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF228B22).withValues(alpha: 0.1), // Light forest green tint
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(UIConstants.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: UIConstants.paddingLarge),
                
                // Header
                _buildHeader(),
                
                const SizedBox(height: UIConstants.paddingXLarge),
                
                // Signup Form
                _buildSignupForm(),
                
                const SizedBox(height: UIConstants.paddingMedium),
                
                // Terms and Conditions
                _buildTermsCheckbox(),
                
                const SizedBox(height: UIConstants.paddingLarge),
                
                // Signup Button
                _buildSignupButton(),
                
                const SizedBox(height: UIConstants.paddingXLarge),
                
                // Divider
                _buildDivider(),
                
                const SizedBox(height: UIConstants.paddingLarge),
                
                // Login Link
                _buildLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusLarge),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_florist,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: UIConstants.paddingMedium),
        Text(
          'Create Account',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: UIConstants.paddingSmall),
        Text(
          'Join us to start protecting your crops with AI',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Name Field
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            validator: ValidationHelper.validateName,
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              prefixIcon: const Icon(Icons.person_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
                borderSide: BorderSide(color: AppColors.neutralLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
                borderSide: BorderSide(color: Color(0xFF228B22)), // Primary forest green
              ),
            ),
          ),
          
          const SizedBox(height: UIConstants.paddingMedium),
          
          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: ValidationHelper.validateEmail,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email address',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
                borderSide: BorderSide(color: AppColors.neutralLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
                borderSide: BorderSide(color: Color(0xFF228B22)), // Primary forest green
              ),
            ),
          ),
          
          const SizedBox(height: UIConstants.paddingMedium),
          
          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.next,
            validator: ValidationHelper.validatePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
                borderSide: BorderSide(color: AppColors.neutralLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
                borderSide: BorderSide(color: Color(0xFF228B22)), // Primary forest green
              ),
            ),
          ),
          
          const SizedBox(height: UIConstants.paddingMedium),
          
          // Confirm Password Field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            textInputAction: TextInputAction.done,
            validator: (value) => ValidationHelper.validateConfirmPassword(
              value,
              _passwordController.text,
            ),
            onFieldSubmitted: (_) => _handleSignup(),
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Confirm your password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
                borderSide: BorderSide(color: AppColors.neutralLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
                borderSide: BorderSide(color: Color(0xFF228B22)), // Primary forest green
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          activeColor: Color(0xFF228B22), // Primary forest green
          onChanged: (value) {
            setState(() {
              _acceptTerms = value ?? false;
            });
          },
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _acceptTerms = !_acceptTerms;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: Color(0xFF228B22), // Primary forest green
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: Color(0xFF228B22), // Primary forest green
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignup,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF228B22), // Primary forest green
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.neutralLight,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.paddingMedium,
          ),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.neutralLight,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () {
            context.go(RouteConstants.login);
          },
          child: Text(
            'Sign In',
            style: TextStyle(
              color: Color(0xFF228B22), // Primary forest green
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}