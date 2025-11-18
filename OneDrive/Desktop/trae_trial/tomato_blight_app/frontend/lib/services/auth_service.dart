import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  static const String _baseUrl = ApiConstants.baseUrl;
  static String? _selectedBaseUrl;

  String _apiBase() {
    return _selectedBaseUrl ?? _baseUrl;
  }

  Future<void> _resolveBaseUrl() async {
    if (_selectedBaseUrl != null) return;
    final candidates = <String>[_baseUrl, ...ApiConstants.baseUrlCandidates.where((u) => u != _baseUrl)];
    for (final url in candidates) {
      try {
        print('🔍 AuthService: Probing base URL $url');
        final res = await http.get(Uri.parse('$url/health')).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          _selectedBaseUrl = url;
          print('✅ AuthService: Using base URL $_selectedBaseUrl');
          return;
        }
      } catch (_) {}
    }
    print('❌ AuthService: No base URL reachable');
  }
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    return await _retryOperation(() async {
      print('🔍 AuthService: Attempting login for $email');
      await _resolveBaseUrl();
      final primaryLoginUrl = Uri.parse('${_apiBase()}/auth/login');
      print('🔍 AuthService: Primary login URL $primaryLoginUrl');

      Future<http.Response> doPost(Uri url, Duration timeout) {
        return http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'email': email.trim().toLowerCase(),
            'password': password,
          }),
        ).timeout(timeout);
      }

      http.Response? response;
      try {
        response = await doPost(primaryLoginUrl, const Duration(seconds: 15));
      } catch (e) {
        print('❌ AuthService: Primary login attempt failed: $e');
        // Try other candidates directly even if health failed
        final tried = <String>{primaryLoginUrl.toString()};
        http.Response? altResponse;
        for (final candidate in ApiConstants.baseUrlCandidates) {
          final altUrl = Uri.parse('$candidate/auth/login');
          if (tried.contains(altUrl.toString())) continue;
          try {
            print('🔄 AuthService: Trying alternate login URL $altUrl');
            altResponse = await doPost(altUrl, const Duration(seconds: 8));
            response = altResponse; // set for parsing
            break;
          } catch (altErr) {
            print('❌ AuthService: Alternate login failed: $altErr');
            continue;
          }
        }
        if (altResponse == null) {
          throw TimeoutException('Login request failed');
        }
      }

      if (response == null) {
        throw TimeoutException('Login request failed');
      }
      final resp = response;
      print('🔍 AuthService: Response status: ${resp.statusCode}');
      print('🔍 AuthService: Response body: ${resp.body}');

      Map<String, dynamic> data = {};
      if (resp.body.isNotEmpty) {
        try {
          final decoded = json.decode(resp.body);
          if (decoded is Map<String, dynamic>) {
            data = decoded;
          }
        } catch (e) {
          print('❌ AuthService: Failed to decode JSON: $e');
        }
      }

      if (resp.statusCode == 200 && data['user'] != null && data['token'] != null) {
        print('🔍 AuthService: Login successful, parsing user data...');
        print('🔍 AuthService: User data from server: ${data['user']}');
        
        try {
          final user = User.fromJson(data['user']);
          print('✅ AuthService: User parsed successfully: ${user.toString()}');
          return {
            'success': true,
            'user': user,
            'token': data['token'],
          };
        } catch (parseError) {
          print('❌ AuthService: Error parsing user data: $parseError');
          return {
            'success': false,
            'message': 'Error parsing user data: ${parseError.toString()}',
          };
        }
      } else if (resp.statusCode == 200) {
        print('❌ AuthService: Missing user data in server response');
        return {
          'success': false,
          'message': 'Invalid server response',
        };
      } else if (resp.statusCode == 401) {
        return {
          'success': false,
          'message': 'Invalid email or password',
        };
      } else if (resp.statusCode == 400) {
        return {
          'success': false,
          'message': (data['message'] as String?) ?? 'Validation failed',
        };
      } else if (resp.statusCode >= 500) {
        return {
          'success': false,
          'message': (data['message'] as String?) ?? 'Internal server error',
        };
      } else {
        print('❌ AuthService: Login failed with status ${resp.statusCode}');
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    }, 'login');
  }

  // Retry mechanism for network operations
  Future<Map<String, dynamic>> _retryOperation(
    Future<Map<String, dynamic>> Function() operation,
    String operationName,
  ) async {
    int maxRetries = 3;
    int retryDelay = 1000; // milliseconds

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🔄 AuthService: $operationName attempt $attempt/$maxRetries');
        return await operation();
      } catch (e) {
        print('❌ AuthService: $operationName attempt $attempt failed: $e');
        
        if (attempt == maxRetries) {
          // Last attempt failed
          if (e is SocketException) {
            return {
              'success': false,
              'message': 'No internet connection. Please check your network and try again.',
            };
          } else if (e is TimeoutException) {
            return {
              'success': false,
              'message': 'Connection timeout. Please check your network and try again.',
            };
          } else if (e is FormatException) {
            return {
              'success': false,
              'message': 'Server response error. Please try again later.',
            };
          } else {
            return {
              'success': false,
              'message': 'Network error: ${e.toString()}',
            };
          }
        } else {
          // Wait before retrying
          await Future.delayed(Duration(milliseconds: retryDelay));
          retryDelay *= 2; // Exponential backoff
        }
      }
    }

    return {
      'success': false,
      'message': 'Unexpected error occurred',
    };
  }

  Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    try {
      await _resolveBaseUrl();
      final response = await http.post(
        Uri.parse('${_apiBase()}/auth/signup'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      Map<String, dynamic> data = {};
      if (response.body.isNotEmpty) {
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) data = decoded;
        } catch (e) {
          print('❌ AuthService: Signup decode error: $e');
        }
      }
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'user': User.fromJson(data['user']),
          'token': data['token'],
          'message': data['message'] ?? 'Account created successfully',
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': (data['message'] as String?) ?? 'Validation failed',
        };
      } else if (response.statusCode >= 500) {
        return {
          'success': false,
          'message': (data['message'] as String?) ?? 'Internal server error',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Signup failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<User?> getCurrentUser(String token) async {
    try {
      print('🔍 AuthService: Getting current user with token');
      await _resolveBaseUrl();
      final meUrl = Uri.parse('${_apiBase()}/auth/me');
      print('🔍 AuthService: Me URL $meUrl');
      final response = await http.get(
        meUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      print('🔍 AuthService: getCurrentUser response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 AuthService: User data received: ${data['user']}');
        return User.fromJson(data['user']);
      } else if (response.statusCode == 401) {
        print('❌ AuthService: Token expired or invalid');
        return null;
      } else {
        print('❌ AuthService: getCurrentUser failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ AuthService: getCurrentUser error: $e');
      return null;
    }
  }

  // Logout method
  Future<bool> logout() async {
    try {
      print('🔍 AuthService: Performing logout');
      // For now, just return true as logout is handled client-side
      // In future, you can add server-side logout if needed
      return true;
    } catch (e) {
      print('❌ AuthService: Logout error: $e');
      return false;
    }
  }

  // Check if server is reachable
  Future<bool> checkServerHealth() async {
    try {
      print('🔍 AuthService: Checking server health');
      await _resolveBaseUrl();
      final healthUrl = Uri.parse('${_apiBase()}/health');
      print('🔍 AuthService: Health URL $healthUrl');
      final response = await http.get(
        healthUrl,
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ AuthService: Server health check failed: $e');
      return false;
    }
  }
  Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? name,
    String? email,
    String? profileImage,
  }) async {
    try {
      await _resolveBaseUrl();
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('${_apiBase()}/auth/profile'),
      );
      
      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add text fields
      if (name != null) request.fields['name'] = name;
      if (email != null) request.fields['email'] = email;
      
      // Add profile image file if provided
      if (profileImage != null) {
        final file = File(profileImage);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath('profileImage', profileImage),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      Map<String, dynamic> data = {};
      if (response.body.isNotEmpty) {
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) data = decoded;
        } catch (e) {
          print('❌ AuthService: Update profile decode error: $e');
        }
      }
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': User.fromJson(data['user']),
          'message': data['message'] ?? 'Profile updated successfully',
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': (data['message'] as String?) ?? 'Validation failed',
        };
      } else if (response.statusCode >= 500) {
        return {
          'success': false,
          'message': (data['message'] as String?) ?? 'Internal server error',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _resolveBaseUrl();
      final response = await http.put(
        Uri.parse('${_apiBase()}/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 15));

      Map<String, dynamic> data = {};
      if (response.body.isNotEmpty) {
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) data = decoded;
        } catch (e) {
          print('❌ AuthService: Change password decode error: $e');
        }
      }
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Password changed successfully',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Invalid email or password',
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': (data['message'] as String?) ?? 'Validation failed',
        };
      } else if (response.statusCode >= 500) {
        return {
          'success': false,
          'message': (data['message'] as String?) ?? 'Internal server error',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to change password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      await _resolveBaseUrl();
      final response = await http.post(
        Uri.parse('${_apiBase()}/auth/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
        }),
      ).timeout(const Duration(seconds: 15));

      Map<String, dynamic> data = {};
      if (response.body.isNotEmpty) {
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) data = decoded;
        } catch (e) {
          print('❌ AuthService: Forgot password decode error: $e');
        }
      }
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Password reset email sent',
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': (data['message'] as String?) ?? 'Validation failed',
        };
      } else if (response.statusCode >= 500) {
        return {
          'success': false,
          'message': (data['message'] as String?) ?? 'Internal server error',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send reset email',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> verifyEmailExists(String email) async {
    try {
      await _resolveBaseUrl();
      final response = await http.post(
        Uri.parse('${_apiBase()}/auth/forgot-password-check'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
        }),
      ).timeout(const Duration(seconds: 15));

      Map<String, dynamic> data = {};
      if (response.body.isNotEmpty) {
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) data = decoded;
        } catch (_) {}
      }

      if (response.statusCode == 200) {
        return { 'success': true, 'message': data['message'] ?? 'Email exists' };
      } else if (response.statusCode == 404) {
        return { 'success': false, 'message': 'Invalid email' };
      } else if (response.statusCode == 400) {
        return { 'success': false, 'message': (data['message'] as String?) ?? 'Validation failed' };
      } else {
        return { 'success': false, 'message': (data['message'] as String?) ?? 'Failed to verify email' };
      }
    } catch (e) {
      return { 'success': false, 'message': 'Network error: ${e.toString()}' };
    }
  }

  Future<Map<String, dynamic>> resetPasswordByEmail(String email, String newPassword) async {
    try {
      await _resolveBaseUrl();
      final response = await http.post(
        Uri.parse('${_apiBase()}/auth/reset-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 15));

      Map<String, dynamic> data = {};
      if (response.body.isNotEmpty) {
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) data = decoded;
        } catch (_) {}
      }

      if (response.statusCode == 200) {
        return { 'success': true, 'message': data['message'] ?? 'Password updated successfully' };
      } else if (response.statusCode == 404) {
        return { 'success': false, 'message': 'Invalid email' };
      } else if (response.statusCode == 400) {
        return { 'success': false, 'message': (data['message'] as String?) ?? 'Validation failed' };
      } else {
        return { 'success': false, 'message': (data['message'] as String?) ?? 'Failed to reset password' };
      }
    } catch (e) {
      return { 'success': false, 'message': 'Network error: ${e.toString()}' };
    }
  }

  Future<bool> validateToken(String token) async {
    try {
      await _resolveBaseUrl();
      final response = await http.get(
        Uri.parse('${_apiBase()}/auth/validate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  }