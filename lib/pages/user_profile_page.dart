import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wastefreebd/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class UserProfilePage extends StatefulWidget {
  final bool isDark;

  const UserProfilePage({super.key, this.isDark = false});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  String? _profilePhotoUrl;
  DateTime? _createdAt;
  final _imagePicker = ImagePicker();
  int _profileCompleteness = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      print("🔍 DEBUG - Load Profile:");
      print("  AuthProvider User: ${user?.email}");
      print("  AuthProvider User ID: ${user?.id}");

      // Use AuthProvider as primary source - it's always available when logged in
      if (user != null) {
        // Try to load additional profile data from database
        try {
          // Convert user.id to integer if it's a string
          final userId = int.parse(user.id);

          final response = await Supabase.instance.client
              .from('user_profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();

          print(
              "  Database Response: ${response != null ? 'Found' : 'Not found'}");

          if (mounted) {
            setState(() {
              _nameController.text = response?['full_name'] ?? user.fullName;
              _emailController.text = user.email;
              _phoneController.text = response?['phone'] ?? '';
              _addressController.text = response?['address'] ?? '';
              _profilePhotoUrl = response?['profile_photo'];
              _createdAt = (response != null && response['created_at'] != null)
                  ? DateTime.parse(response['created_at'])
                  : user.createdAt;
            });
            _calculateProfileCompleteness();
          }
        } catch (dbError) {
          print("  Database fetch failed: $dbError");
          // Still show profile with AuthProvider data
          if (mounted) {
            setState(() {
              _nameController.text = user.fullName;
              _emailController.text = user.email;
              _createdAt = user.createdAt;
            });
            _calculateProfileCompleteness();
          }
        }
      } else {
        // No AuthProvider user - show error message only
        print("  ⚠️ No valid session found");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to view your profile'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print("  ❌ Error loading profile: $e");

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user != null && mounted) {
        setState(() {
          _nameController.text = user.fullName;
          _emailController.text = user.email;
          _createdAt = user.createdAt;
        });
        _calculateProfileCompleteness();

        // Show error but don't treat as session expired
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Could not load full profile: ${e.toString().split(':').first}'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadUserProfile,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      // Debug: Check if user is logged in
      print("🔍 DEBUG - Update Profile:");
      print("  AuthProvider User: ${user?.email}");
      print("  AuthProvider User ID: ${user?.id}");

      if (user == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to update your profile'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final userRole = user.role.value;

      // Convert user.id to integer if it's a string
      final userId = int.parse(user.id);

      final data = {
        'id': userId,
        'full_name': _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
        'phone': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        'address': _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        'profile_photo': _profilePhotoUrl,
        'role': userRole,
      };

      final response = await Supabase.instance.client
          .from('user_profiles')
          .upsert(data, onConflict: 'id')
          .select()
          .single();

      setState(() {
        _nameController.text = response['full_name'] ?? '';
        _phoneController.text = response['phone'] ?? '';
        _addressController.text = response['address'] ?? '';
        _profilePhotoUrl = response['profile_photo'];
        _isEditing = false;
      });

      _calculateProfileCompleteness();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Profile updated successfully'),
            backgroundColor: Color(0xFF13EC5B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      final bytes = await image.readAsBytes();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user != null) {
        try {
          final fileName =
              'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

          await Supabase.instance.client.storage.from('avatars').uploadBinary(
              fileName, bytes,
              fileOptions: const FileOptions(upsert: true));

          final publicUrl = Supabase.instance.client.storage
              .from('avatars')
              .getPublicUrl(fileName);

          setState(() {
            _profilePhotoUrl = publicUrl;
          });
          _calculateProfileCompleteness();

          await Supabase.instance.client.from('user_profiles').upsert({
            'id': user.id,
            'profile_photo': publicUrl,
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Profile photo updated'),
                backgroundColor: Color(0xFF13EC5B),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (storageError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Photo upload failed: ${storageError.toString().contains('not found') ? 'Storage not configured' : 'Try again'}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().split(':').last}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _changePassword() async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 6 characters'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF13EC5B),
              foregroundColor: Colors.black87,
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        setState(() => _isLoading = true);

        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: newPasswordController.text),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Password changed successfully'),
            backgroundColor: Color(0xFF13EC5B),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }

    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await Supabase.instance.client.auth.signOut();
                authProvider.clearUser();

                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error logging out: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _calculateProfileCompleteness() {
    setState(() {
      int completed = 0;
      const total = 5;

      if (_nameController.text.isNotEmpty) completed++;
      if (_emailController.text.isNotEmpty) completed++;
      if (_phoneController.text.isNotEmpty) completed++;
      if (_addressController.text.isNotEmpty) completed++;
      if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty) {
        completed++;
      }

      _profileCompleteness = ((completed / total) * 100).round();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isDark = widget.isDark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.grey[400],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserProfile,
              color: const Color(0xFF13EC5B),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildProfileCompleteness(isDark),
                      const SizedBox(height: 16),
                      _buildProfileAvatar(isDark, user),
                      const SizedBox(height: 24),
                      _buildProfileInformation(isDark),
                      const SizedBox(height: 24),
                      if (_isEditing) _buildActionButtons(),
                      const SizedBox(height: 16),
                      _buildChangePasswordButton(),
                      const SizedBox(height: 12),
                      _buildLogoutButton(authProvider),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileCompleteness(bool isDark) {
    Color getCompletenessColor() {
      if (_profileCompleteness >= 80) return const Color(0xFF13EC5B);
      if (_profileCompleteness >= 50) return Colors.orange;
      return Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF23482F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile Completeness',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                '$_profileCompleteness%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: getCompletenessColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _profileCompleteness / 100,
              backgroundColor:
                  isDark ? const Color(0xFF1C2E22) : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(getCompletenessColor()),
              minHeight: 8,
            ),
          ),
          if (_profileCompleteness < 100) ...[
            const SizedBox(height: 8),
            Text(
              'Complete your profile to unlock all features!',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF92C9A4) : Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(bool isDark, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF23482F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isEditing ? _pickProfilePhoto : null,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFF13EC5B).withOpacity(0.2),
                  backgroundImage: _profilePhotoUrl != null
                      ? NetworkImage(_profilePhotoUrl!)
                      : null,
                  child: _profilePhotoUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Color(0xFF13EC5B),
                        )
                      : null,
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF13EC5B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _nameController.text.isNotEmpty
                ? _nameController.text
                : (user?.fullName ?? 'User'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.role.displayName ?? 'User',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF92C9A4) : Colors.grey[600],
            ),
          ),
          if (_createdAt != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF13EC5B).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Member since ${_createdAt!.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF13EC5B)
                      : const Color(0xFF0FA84D),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileInformation(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF23482F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            enabled: _isEditing,
            autofillHints: const [AutofillHints.name],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon:
                  const Icon(Icons.person_outline, color: Color(0xFF13EC5B)),
              labelStyle: TextStyle(
                color: isDark ? const Color(0xFF92C9A4) : Colors.grey[700],
              ),
              filled: true,
              fillColor: _isEditing
                  ? (isDark ? const Color(0xFF1C2E22) : Colors.grey[100])
                  : (isDark ? const Color(0xFF102216) : Colors.grey[200]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF326744) : Colors.grey[300]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF13EC5B),
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            enabled: false,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon:
                  const Icon(Icons.email_outlined, color: Color(0xFF13EC5B)),
              labelStyle: TextStyle(
                color: isDark ? const Color(0xFF92C9A4) : Colors.grey[700],
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF102216) : Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value)) {
                  return 'Enter valid phone number';
                }
              }
              return null;
            },
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'Phone Number',
              prefixIcon:
                  const Icon(Icons.phone_outlined, color: Color(0xFF13EC5B)),
              labelStyle: TextStyle(
                color: isDark ? const Color(0xFF92C9A4) : Colors.grey[700],
              ),
              filled: true,
              fillColor: _isEditing
                  ? (isDark ? const Color(0xFF1C2E22) : Colors.grey[100])
                  : (isDark ? const Color(0xFF102216) : Colors.grey[200]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF326744) : Colors.grey[300]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF13EC5B),
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            enabled: _isEditing,
            maxLines: 3,
            autofillHints: const [AutofillHints.fullStreetAddress],
            style: TextStyle(
              color: widget.isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'Address',
              prefixIcon: const Icon(Icons.location_on_outlined,
                  color: Color(0xFF13EC5B)),
              labelStyle: TextStyle(
                color:
                    widget.isDark ? const Color(0xFF92C9A4) : Colors.grey[700],
              ),
              filled: true,
              fillColor: _isEditing
                  ? (widget.isDark ? const Color(0xFF1C2E22) : Colors.grey[100])
                  : (widget.isDark
                      ? const Color(0xFF102216)
                      : Colors.grey[200]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: widget.isDark
                      ? const Color(0xFF326744)
                      : Colors.grey[300]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF13EC5B),
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() => _isEditing = false);
              _loadUserProfile();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF13EC5B),
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Changes'),
          ),
        ),
      ],
    );
  }

  Widget _buildChangePasswordButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _changePassword,
        icon: const Icon(Icons.lock_outline),
        label: const Text('Change Password'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF13EC5B),
          side: const BorderSide(color: Color(0xFF13EC5B)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context, authProvider),
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
