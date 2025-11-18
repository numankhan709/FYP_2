import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  const ResetPasswordScreen({super.key, this.initialEmail});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _stepEmail;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
      _stepEmail = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailStep() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    try {
      final exists = await authProvider.verifyEmailExists(email);
      if (!mounted) return;
      if (exists) {
        _stepEmail = email;
        setState(() {});
      } else {
        ErrorHelper.showErrorSnackBar(context, authProvider.errorMessage ?? 'Invalid email');
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _handleResetStep(String email) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final newPassword = _passwordController.text;
    try {
      final ok = await authProvider.resetPasswordByEmail(email, newPassword);
      if (!mounted) return;
      if (ok) {
        ErrorHelper.showSuccessSnackBar(context, 'Password updated successfully. Please log in.');
        context.go(RouteConstants.login);
      } else {
        ErrorHelper.showErrorSnackBar(context, authProvider.errorMessage ?? 'Failed to reset password.');
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isResetStep = _stepEmail != null && _stepEmail!.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(isResetStep ? 'Set New Password' : 'Forgot Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isResetStep) ...[
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: ValidationHelper.validateEmail,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
                    ),
                  ),
                ),
                const SizedBox(height: UIConstants.paddingLarge),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleEmailStep,
                  child: Text(_isLoading ? 'Checking...' : 'Continue'),
                ),
              ] else ...[
                Text('Email: ${_stepEmail!}'),
                const SizedBox(height: UIConstants.paddingMedium),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: ValidationHelper.validatePassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
                    ),
                  ),
                ),
                const SizedBox(height: UIConstants.paddingLarge),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _handleResetStep(_stepEmail!),
                  child: Text(_isLoading ? 'Updating...' : 'Update Password'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}