import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart' as user_model;

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final supabase = Supabase.instance.client;

  // Test credentials for each role
  static const Map<String, Map<String, String>> testCredentials = {
    'admin@wastefreebd.com': {
      'password': 'admin123',
      'name': 'Admin User',
      'role': 'admin'
    },
    'manager@wastefreebd.com': {
      'password': 'manager123',
      'name': 'Manager User',
      'role': 'management'
    },
    'accountant@wastefreebd.com': {
      'password': 'accountant123',
      'name': 'Accountant User',
      'role': 'accountant'
    },
    'user@wastefreebd.com': {
      'password': 'user123',
      'name': 'Regular User',
      'role': 'user'
    },
  };

  /// Sign up with email and password
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
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

      // Determine role based on email
      user_model.UserRole role = _getRoleFromEmail(email);

      // Insert user into signin table
      await supabase.from('signin').insert({
        'email': email,
        'password': password,
        'Name': fullName,
        'role': role.value,
      });

      return {
        'success': true,
        'message': 'Account created successfully!',
        'role': role,
        'email': email,
        'fullName': fullName,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating account: $e',
      };
    }
  }

  /// Sign in with email and password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // First check if it's a test account
      if (testCredentials.containsKey(email)) {
        if (testCredentials[email]!['password'] == password) {
          final role = user_model.UserRole.fromString(
            testCredentials[email]!['role'] ?? 'user',
          );
          return {
            'success': true,
            'message': 'Login successful',
            'user': user_model.AuthUser(
              id: email,
              email: email,
              fullName: testCredentials[email]!['name'] ?? 'User',
              role: role,
              createdAt: DateTime.now(),
            ),
          };
        } else {
          return {
            'success': false,
            'message': 'Invalid email or password',
          };
        }
      }

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
      final role = user_model.UserRole.fromString(user['role'] ?? 'user');

      final authUser = user_model.AuthUser(
        id: user['id'].toString(),
        email: email,
        fullName: user['Name'] ?? 'User',
        role: role,
        createdAt: user['created_at'] != null
            ? DateTime.parse(user['created_at'])
            : DateTime.now(),
      );

      return {
        'success': true,
        'message': 'Login successful',
        'user': authUser,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  /// Get role from email
  user_model.UserRole _getRoleFromEmail(String email) {
    if (email.contains('admin')) {
      return user_model.UserRole.admin;
    } else if (email.contains('management') || email.contains('manager')) {
      return user_model.UserRole.management;
    } else if (email.contains('accountant')) {
      return user_model.UserRole.accountant;
    }
    return user_model.UserRole.user;
  }

  /// Get role from database
  Future<user_model.UserRole> getRoleFromDatabase(String email) async {
    try {
      final userData =
          await supabase.from('signin').select().eq('email', email).single();
      return user_model.UserRole.fromString(userData['role'] ?? 'user');
    } catch (e) {
      return user_model.UserRole.user;
    }
  }

  /// Get user by email
  Future<user_model.AuthUser?> getUserByEmail(String email) async {
    try {
      final userData =
          await supabase.from('signin').select().eq('email', email).single();
      return user_model.AuthUser.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Clear any stored session data
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Get test credentials
  static Map<String, Map<String, String>> getTestCredentials() {
    return testCredentials;
  }
}
