import 'package:supabase_flutter/supabase_flutter.dart';

enum UserRole { admin, management, accountant, user }

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final supabase = Supabase.instance.client;

  // Store logged-in user data
  static String? _loggedInUserEmail;
  static String? _loggedInUserRole;

  /// Get user role from database signin table
  Future<UserRole> getRoleFromDatabase(String email) async {
    try {
      final userData =
          await supabase.from('signin').select().eq('email', email).single();

      final roleString = userData['role'] ?? 'user';
      return UserRole.values
          .firstWhere((e) => e.toString().split('.').last == roleString);
    } catch (e) {
      return UserRole.user;
    }
  }

  /// Sign up with email and password - saves to signin table
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    UserRole role = UserRole.user,
  }) async {
    try {
      // Check if user already exists
      final existingUser =
          await supabase.from('signin').select().eq('email', email);

      if (existingUser.isNotEmpty) {
        return {
          'success': false,
          'message': 'Email already registered',
        };
      }

      // Insert user into signin table
      await supabase.from('signin').insert({
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role.toString().split('.').last,
        'created_at': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'message': 'Account created successfully!',
        'role': role,
        'email': email,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating account: $e',
      };
    }
  }

  /// Sign in with email and password - checks signin table
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Query the signin table for matching email and password
      final userData = await supabase
          .from('signin')
          .select()
          .eq('email', email)
          .eq('password', password);

      if (userData.isEmpty) {
        return {
          'success': false,
          'message': 'Invalid email or password',
        };
      }

      final user = userData[0];
      final roleString = user['role'] ?? 'user';
      final role = UserRole.values
          .firstWhere((e) => e.toString().split('.').last == roleString);

      // Store logged in user info
      _loggedInUserEmail = email;
      _loggedInUserRole = roleString;

      return {
        'success': true,
        'message': 'Login successful',
        'role': role,
        'email': email,
        'fullName': user['full_name'] ?? 'User',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _loggedInUserEmail = null;
      _loggedInUserRole = null;
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Get current logged-in user email
  String? getCurrentUserEmail() {
    return _loggedInUserEmail;
  }

  /// Get current logged-in user role
  UserRole? getCurrentUserRole() {
    if (_loggedInUserRole == null) return null;
    return UserRole.values
        .firstWhere((e) => e.toString().split('.').last == _loggedInUserRole!);
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _loggedInUserEmail != null;
  }
}
