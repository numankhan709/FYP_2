import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  // Notifier for router refresh that only triggers on auth state changes
  final ChangeNotifier _routerNotifier = ChangeNotifier();

  User? get user => _user;
  User? get currentUser => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  Listenable get routerListenable => _routerNotifier;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<bool> _checkAuthStatus() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null) {
        // Try to get fresh user data from server
        final userData = await _authService.getCurrentUser(token);
        
        if (userData != null) {
          _user = userData;
          await _saveUserData(_user!); // Save fresh data
          return true;
        } else {
          // Fallback to cached user data if server is unreachable
          final cachedUserData = prefs.getString('user_data');
          if (cachedUserData != null) {
            _user = User.fromJson(json.decode(cachedUserData));
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      // If there's an error, try to load cached user data
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedUserData = prefs.getString('user_data');
        if (cachedUserData != null) {
          _user = User.fromJson(json.decode(cachedUserData));
          return true;
        }
      } catch (cacheError) {
        _setError('Failed to check authentication status');
      }
      return false;
    } finally {
      _setLoading(false);
      _isInitialized = true;
      _routerNotifier.notifyListeners();
    }
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userJson = prefs.getString('user_data');
      
      print('🔍 AuthProvider: Loading token from storage');
      print('🔍 AuthProvider: Token exists: ${token != null}');
      print('🔍 AuthProvider: User data exists: ${userJson != null}');
      
      if (userJson != null) {
        try {
          final userData = json.decode(userJson);
          _user = User.fromJson(userData);
          print('✅ AuthProvider: User loaded from storage: ${_user?.email}');
          
          // Validate token if both user and token exist
          if (token != null && _user != null) {
            await _validateToken();
          }
        } catch (e) {
          print('❌ AuthProvider: Error parsing stored user data: $e');
          // Clear corrupted data
          await _clearToken();
        }
      }
    } catch (e) {
      print('❌ AuthProvider: Error loading token: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      print('🔍 AuthProvider: Starting login process for $email');
      _setLoading(true);
      _clearError();

      final serverOk = await checkServerConnection();
      if (!serverOk) {
        print('⚠️ AuthProvider: Server health check failed, attempting login anyway');
        // Continue to attempt login; health endpoint may be blocked while auth works
      }

      final result = await _authService.login(email, password);
      print('🔍 AuthProvider: AuthService result: $result');

      if (result['success']) {
        print('🔍 AuthProvider: Login successful, setting user and token');
        _user = result['user'];
        
        print('🔍 AuthProvider: User set: ${_user?.toString()}');
        print('🔍 AuthProvider: isAuthenticated: $isAuthenticated');
        
        // Save to SharedPreferences
        await _saveToken(result['token']);
        await _saveUserData(_user!);
        
        print('✅ AuthProvider: User data saved to SharedPreferences');
        _isInitialized = true; // Ensure router redirect works
        notifyListeners();
        _routerNotifier.notifyListeners();
        return true;
      } else {
        print('❌ AuthProvider: Login failed: ${result['message']}');
        _setError(result['message'] ?? 'Login failed');
        return false;
      }
    } catch (e) {
      print('❌ AuthProvider: Exception during login: $e');
      _setError('Network error. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authService.signup(name, email, password);
      if (result['success']) {
        _user = result['user'];
        await _saveToken(result['token']);
        await _saveUserData(_user!);
        _isInitialized = true; // Ensure router redirect works
        notifyListeners();
        return true;
      } else {
        _setError(result['message'] ?? 'Signup failed');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> logout() async {
    try {
      print('🔍 AuthProvider: Starting logout process');
      _setLoading(true);
      _clearError();

      // Call logout service
      final success = await _authService.logout();
      
      if (success) {
        print('🔍 AuthProvider: Clearing user data and tokens');
        
        // Clear in-memory state
        _user = null;
        _isInitialized = true;
        
        // Clear persistent storage
        await _clearToken();
        
        print('✅ AuthProvider: Logout completed successfully');
        notifyListeners();
        _routerNotifier.notifyListeners();
        return true;
      } else {
        print('❌ AuthProvider: Logout service failed');
        _setError('Logout failed. Please try again.');
        return false;
      }
    } catch (e) {
      print('❌ AuthProvider: Exception during logout: $e');
      
      // Even if there's an error, clear local state for security
      _user = null;
      _isInitialized = true;
      await _clearToken();
      
      _setError('Logout completed with warnings.');
      notifyListeners();
      _routerNotifier.notifyListeners();
      return true; // Return true because local state is cleared
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(user.toJson()));
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Check authentication status
  Future<bool> checkAuthStatus() {
    return _checkAuthStatus();
  }
  
  // Set user data without triggering listeners (used during splash navigation)
  void setUserSilently(User userData) {
    _user = userData;
    _isLoading = false;
    _isInitialized = true;
    _errorMessage = null;
    // Don't call notifyListeners() to avoid triggering router redirects
  }

  // Validate current token
  Future<bool> _validateToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        print('🔍 AuthProvider: No token to validate');
        return false;
      }

      print('🔍 AuthProvider: Validating current token');
      final user = await _authService.getCurrentUser(token);
      
      if (user != null) {
        print('✅ AuthProvider: Token is valid');
        _user = user;
        await _saveUserData(_user!);
        notifyListeners();
        return true;
      } else {
        print('❌ AuthProvider: Token is invalid or expired');
        await _clearToken();
        _user = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ AuthProvider: Token validation error: $e');
      return false;
    }
  }

  // Public method to check token validity
  Future<bool> validateCurrentToken() async {
    return await _validateToken();
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();
    try {
      final result = await _authService.forgotPassword(email);
      if (result['success'] == true) {
        return true;
      } else {
        _setError((result['message'] as String?) ?? 'Failed to send reset email');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyEmailExists(String email) async {
    _setLoading(true);
    _clearError();
    try {
      final result = await _authService.verifyEmailExists(email);
      if (result['success'] == true) {
        return true;
      } else {
        _setError((result['message'] as String?) ?? 'Invalid email');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPasswordByEmail(String email, String newPassword) async {
    _setLoading(true);
    _clearError();
    try {
      final result = await _authService.resetPasswordByEmail(email, newPassword);
      if (result['success'] == true) {
        return true;
      } else {
        _setError((result['message'] as String?) ?? 'Failed to reset password');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check if server is reachable
  Future<bool> checkServerConnection() async {
    try {
      return await _authService.checkServerHealth();
    } catch (e) {
      print('❌ AuthProvider: Server connection check failed: $e');
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    File? profileImage,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        _setError('Authentication required');
        return false;
      }

      // For now, we'll handle image as a simple string path
      // In a real app, you'd upload the image to a server first
      String? profileImagePath;
      if (profileImage != null) {
        profileImagePath = profileImage.path;
      }

      final Map<String, dynamic> result = await _authService.updateProfile(
        token: token,
        name: name,
        email: email,
        profileImage: profileImagePath,
      );

      final bool success = result['success'] == true;
      if (success) {
        final dynamic userValue = result['user'];
        if (userValue is User) {
          setUserSilently(userValue);
          await _saveUserData(_user!);
          return true;
        } else if (userValue is Map<String, dynamic>) {
          // Handle case where service returns raw JSON
          try {
            setUserSilently(User.fromJson(userValue));
            await _saveUserData(_user!);
            return true;
          } catch (e) {
            _setError('Invalid user data received');
            return false;
          }
        } else {
          _setError('Invalid user data received');
          return false;
        }
      } else {
        final String message = (result['message'] as String?) ?? 'Profile update failed';
        _errorMessage = message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _setError('Network error. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void refresh() {
    notifyListeners();
  }
}