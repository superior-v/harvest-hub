import 'package:flutter/material.dart';
import 'package:harvest/core/constants/app_constants.dart';
import 'package:harvest/core/services/auth_service.dart';
import 'package:harvest/core/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'donor';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.background,
                      const Color(0xFFF0E7DA)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -120,
              right: -40,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryGreen.withOpacity(0.12),
                ),
              ),
            ),
            Positioned(
              left: -80,
              bottom: -90,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFB26A3D).withOpacity(0.1),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.eco_rounded,
                                  color: AppColors.deepGreen,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'HarvestHub',
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: AppColors.deepGreen,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLogin ? 'Login to continue your impact journey.' : 'Create an account and start sharing with your community.',
                            style: TextStyle(
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 22),
                          if (!_isLogin) ...[
                            _buildTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline_rounded,
                              validator: (value) {
                                if (!_isLogin && (value == null || value.trim().isEmpty)) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (!_isLogin && value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          if (_isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading ? null : _handleForgotPassword,
                                child: const Text('Forgot Password?'),
                              ),
                            ),
                          if (!_isLogin) ...[
                            const SizedBox(height: 8),
                            _buildRolePicker(),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(_isLogin ? 'Login' : 'Create Account'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isLogin ? "Don't have an account? " : 'Already have an account? ',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _isLogin = !_isLogin;
                                        });
                                      },
                                child: Text(_isLogin ? 'Sign Up' : 'Login'),
                              ),
                            ],
                          ),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, '/role-selection');
                              },
                              child: Text(
                                'Continue as Guest',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildRolePicker() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGreen.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select role',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.deepGreen,
            ),
          ),
          const SizedBox(height: 10),
          _buildRoleOption('donor', 'Donor', 'I want to donate'),
          _buildRoleOption('recipient', 'Recipient (NGO)', 'I need donations'),
          _buildRoleOption('farmer', 'Farmer', 'I need organic waste'),
        ],
      ),
    );
  }

  Widget _buildRoleOption(String value, String title, String subtitle) {
    final isSelected = _selectedRole == value;
    final roleColor = value == 'recipient'
        ? AppColors.roleRecipient
        : value == 'farmer'
            ? AppColors.roleFarmer
            : AppColors.roleDonor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRole = value;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? roleColor.withOpacity(0.12) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? roleColor : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? roleColor : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? roleColor : Colors.black,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        final credential = await _authService.signInWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (credential?.user != null) {
          try {
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(credential!.user!.uid).get();

            if (!userDoc.exists) {
              // Older accounts can exist in Auth without a profile doc.
              // Auto-create a minimal profile to unblock login.
              await _firestoreService.createUserProfile(
                uid: credential.user!.uid,
                email: credential.user!.email ?? _emailController.text.trim(),
                name: credential.user!.displayName ?? 'User',
                role: 'recipient',
              );
            }

            if (mounted) {
              // Always ask role after login.
              Navigator.pushReplacementNamed(context, '/role-selection');
            }
          } catch (e) {
            debugPrint('Error fetching user role: $e');
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/role-selection');
            }
          }
        }
      } else {
        // SIGNUP
        final user = await _authService.signUpWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
        );

        if (user != null) {
          // Create user profile
          try {
            await _firestoreService.createUserProfile(
              uid: user.uid,
              email: _emailController.text.trim(),
              name: _nameController.text.trim(),
              role: _selectedRole,
            );
          } catch (e) {
            debugPrint('Error creating user profile: $e');
          }

          if (mounted) {
            _navigateToRoleDashboard(_selectedRole);
          }
        }
      }
    } catch (e) {
      debugPrint('Error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
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

  void _navigateToRoleDashboard(String role) {
    String route;
    switch (role.toLowerCase()) {
      case 'donor':
        route = '/donor-dashboard';
        break;
      case 'recipient':
        route = '/recipient-dashboard';
        break;
      case 'farmer':
        route = '/recipient-dashboard';
        break;
      default:
        route = '/role-selection';
    }

    Navigator.pushReplacementNamed(context, route);
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid email first, then tap Forgot Password.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _authService.resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _friendlyError(Object e) {
    final message = e.toString();
    if (message.startsWith('Exception: ')) {
      return message.replaceFirst('Exception: ', '');
    }
    return message;
  }
}
