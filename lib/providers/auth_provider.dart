import 'package:flutter/material.dart';
import '../models/user_model.dart' as user_model;
import '../services/auth_service.dart';

/// Provider for managing authentication state with Supabase integration
class AuthProvider extends ChangeNotifier {
  user_model.AuthUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  final AuthService _authService = AuthService();

  user_model.AuthUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  user_model.UserRole? get userRole => _currentUser?.role;

  /// Check if user has specific role
  bool hasRole(user_model.UserRole role) {
    return _currentUser?.role == role;
  }

  /// Check if user has any of the specified roles
  bool hasAnyRole(List<user_model.UserRole> roles) {
    return roles.contains(_currentUser?.role);
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    setLoading(true);
    clearError();

    try {
      final result = await _authService.signIn(
        email: email,
        password: password,
      );

      if (result['success']) {
        _currentUser = result['user'];
        notifyListeners();
        return true;
      } else {
        setError(result['message'] ?? 'Login failed');
        return false;
      }
    } catch (e) {
      setError('Login error: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Signup with email, password, and name
  Future<bool> signup({
    required String email,
    required String password,
    required String fullName,
  }) async {
    setLoading(true);
    clearError();

    try {
      final result = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (result['success']) {
        setError(null);
        return true;
      } else {
        setError(result['message'] ?? 'Signup failed');
        return false;
      }
    } catch (e) {
      setError('Signup error: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Set current user (after successful login)
  void setUser(user_model.AuthUser user) {
    _currentUser = user;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear user (logout)
  void clearUser() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
