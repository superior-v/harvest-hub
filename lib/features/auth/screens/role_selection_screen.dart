import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:harvest/core/constants/app_constants.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _isSavingRole = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // App Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco,
                    size: 64,
                    color: AppColors.deepGreen,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'HarvestHub',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepGreen,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Connect. Share. Impact.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 48),

                const Text(
                  'Select Your Role',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                // Donor Card
                _buildRoleCard(
                  context,
                  title: 'Donor',
                  subtitle: 'I want to donate items',
                  icon: Icons.volunteer_activism,
                  color: AppColors.roleDonor,
                  onTap: () async {
                    await _handleRoleSelection('donor', '/donor-dashboard');
                  },
                ),

                const SizedBox(height: 16),

                // Recipient Card
                _buildRoleCard(
                  context,
                  title: 'Recipient (NGO)',
                  subtitle: 'I need donations',
                  icon: Icons.people,
                  color: AppColors.roleRecipient,
                  onTap: () async {
                    await _handleRoleSelection('recipient', '/recipient-dashboard');
                  },
                ),

                const SizedBox(height: 16),

                // Farmer Card
                _buildRoleCard(
                  context,
                  title: 'Farmer',
                  subtitle: 'I need organic waste',
                  icon: Icons.agriculture,
                  color: AppColors.roleFarmer,
                  onTap: () async {
                    await _handleRoleSelection('farmer', '/recipient-dashboard');
                  },
                ),

                const SizedBox(height: 24),

                // Guest Button
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/recipient-dashboard');
                  },
                  child: Text(
                    'Continue as Guest',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.mediumGray,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                if (_isSavingRole)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRoleSelection(String role, String route) async {
    if (_isSavingRole) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, route);
      return;
    }

    setState(() => _isSavingRole = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'name': user.displayName ?? 'User',
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, route);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save role. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingRole = false);
      }
    }
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.22)),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),

              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
