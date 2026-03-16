import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:harvest/core/constants/app_constants.dart';
import 'package:harvest/core/services/auth_service.dart';
import 'package:harvest/core/services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Theme tokens aligned with donor dashboard
  static const Color _forest = Color(0xFF1A3A1F);
  static const Color _leaf = Color(0xFF3D7A45);
  static const Color _sprout = Color(0xFF6BBF6A);
  static const Color _mist = Color(0xFFF3F7F0);
  static const Color _clay = Color(0xFFD4956A);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _divider = Color(0xFFDEEADE);

  static const LinearGradient _heroGradient = LinearGradient(
    colors: [
      Color(0xFF1A3A1F),
      Color(0xFF2D5E33)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await _firestoreService.getUserProfile(user.uid);
        if (doc.exists) {
          setState(() {
            _userProfile = doc.data() as Map<String, dynamic>?;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('Error loading profile: $e');
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // If no user, show login prompt
    if (user == null) {
      return Scaffold(
        backgroundColor: _mist,
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: _forest,
          flexibleSpace: Container(decoration: const BoxDecoration(gradient: _heroGradient)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              const Text(
                'Not Logged In',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please login to view your profile',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _leaf,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.login),
                label: const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _mist,
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: _forest,
          flexibleSpace: Container(decoration: const BoxDecoration(gradient: _heroGradient)),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_leaf),
          ),
        ),
      );
    }

    // Get user data
    final userData = _userProfile ??
        {
          'name': user.displayName ?? 'User',
          'email': user.email ?? 'No email',
          'role': 'User',
          'totalDonations': 0,
          'totalRequests': 0,
          'impactPoints': 0,
        };

    return Scaffold(
      backgroundColor: _mist,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: _forest,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: _heroGradient)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfile(userData),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        color: _leaf,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header with Avatar
              _buildProfileHeader(userData),

              const SizedBox(height: 20),

              // Stats Cards
              _buildStatsSection(userData),

              const SizedBox(height: 20),

              // Profile Info Section
              _buildInfoSection(userData),

              const SizedBox(height: 20),

              // Settings Section
              _buildSettingsSection(),

              const SizedBox(height: 20),

              // Logout Button
              _buildLogoutButton(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    final userName = userData['name'] ?? 'User';
    final userRole = userData['role'] ?? 'User';

    // Get creation date from Firebase user
    final user = FirebaseAuth.instance.currentUser;
    final joinedDate = user?.metadata.creationTime != null ? '${_getMonthName(user!.metadata.creationTime!.month)} ${user.metadata.creationTime!.year}' : 'Recently';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _forest,
            _leaf,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Avatar with camera button
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: _leaf,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 18,
                    color: _leaf,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 4),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatRole(userRole),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Member since $joinedDate',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> userData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.volunteer_activism,
              label: 'Donations',
              value: (userData['totalDonations'] ?? 0).toString(),
              color: _leaf,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.request_page,
              label: 'Requests',
              value: (userData['totalRequests'] ?? 0).toString(),
              color: const Color(0xFF4A90C4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.star,
              label: 'Impact',
              value: (userData['impactPoints'] ?? 0).toString(),
              color: _clay,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _forest.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Map<String, dynamic> userData) {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _divider),
          boxShadow: [
            BoxShadow(
              color: _forest.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildInfoItem(
              icon: Icons.email,
              label: 'Email',
              value: user?.email ?? 'No email',
            ),
            _buildDivider(),
            _buildInfoItem(
              icon: Icons.badge,
              label: 'User ID',
              value: user?.uid.substring(0, 8) ?? 'N/A',
            ),
            _buildDivider(),
            _buildInfoItem(
              icon: Icons.verified_user,
              label: 'Email Verified',
              value: user?.emailVerified ?? false ? 'Yes' : 'No',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: _leaf, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _divider),
          boxShadow: [
            BoxShadow(
              color: _forest.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildSettingsItem(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Push notifications & alerts',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications settings (Coming soon)'),
                    backgroundColor: _leaf,
                  ),
                );
              },
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: Icons.privacy_tip,
              title: 'Privacy',
              subtitle: 'Control your privacy settings',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Privacy settings (Coming soon)'),
                    backgroundColor: _leaf,
                  ),
                );
              },
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: Icons.help,
              title: 'Help & Support',
              subtitle: 'Get help & contact us',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Help & Support (Coming soon)'),
                    backgroundColor: _leaf,
                  ),
                );
              },
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: Icons.info,
              title: 'About',
              subtitle: 'App version & information',
              onTap: () {
                _showAboutDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: _leaf),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 60,
      color: _divider,
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showLogoutDialog(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.logout),
          label: const Text(
            'Logout',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _showEditProfile(Map<String, dynamic> userData) {
    final nameController = TextEditingController(text: userData['name']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await user.updateDisplayName(nameController.text);
                      await _loadUserProfile();
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile updated successfully!'),
                          backgroundColor: _leaf,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating profile: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _leaf,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _authService.signOut();
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info, color: AppColors.primaryGreen),
            Icon(Icons.info, color: _leaf),
            SizedBox(width: 12),
            Text('About HarvestHub'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('HarvestHub connects donors with those in need, '
                'reducing food waste and helping communities.'),
            SizedBox(height: 12),
            Text('Built with Flutter & Firebase'),
            SizedBox(height: 12),
            Text('© 2024 HarvestHub. All rights reserved.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _leaf,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatRole(String role) {
    switch (role.toLowerCase()) {
      case 'donor':
        return 'Donor';
      case 'recipient':
        return 'Recipient (NGO)';
      case 'farmer':
        return 'Farmer';
      default:
        return 'User';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
