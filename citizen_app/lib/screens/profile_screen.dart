import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../global.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController(text: loggedInUserName);
  final _phoneController = TextEditingController(text: loggedInUserNIC);
  
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  void _updateProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully.')),
    );
  }

  void _changePassword() {
    if (_currentPasswordController.text.isNotEmpty && _newPasswordController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
    }
  }

  void _deactivateAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Account'),
        content: const Text('Are you sure you want to deactivate your account? You will need to contact support to reactivate.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.primaryColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Deactivate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(color: AppTheme.danger)),
        content: const Text('WARNING: This will permanently delete your account and all associated tokens. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.primaryDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Delete Forever', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required String title, required List<Widget> children, Color? borderColor}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor ?? Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(color: (borderColor ?? AppTheme.primaryColor).withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: borderColor ?? AppTheme.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textSecondary),
          prefixIcon: Icon(icon, color: AppTheme.primaryColor),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppTheme.borderColor.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryDark),
        title: const Text('My Profile', style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Ambient Mesh Gradient Background
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -size.height * 0.1 + (80 * _bgController.value),
                    left: -size.width * 0.1 - (50 * _bgController.value),
                    child: Container(
                      width: size.width * 0.9,
                      height: size.width * 0.9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withOpacity(0.15),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -size.height * 0.1 - (80 * _bgController.value),
                    right: -size.width * 0.2 + (50 * _bgController.value),
                    child: Container(
                      width: size.width * 0.8,
                      height: size.width * 0.8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accentColor.withOpacity(0.2),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.white.withOpacity(0.5)),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  
                  // Profile Avatar
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: AppTheme.primaryColor, width: 3),
                        boxShadow: [
                          BoxShadow(color: AppTheme.primaryColor.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: const Icon(Icons.person, size: 50, color: AppTheme.primaryColor),
                    ),
                  ).animate().fade(duration: 500.ms).scale(),
                  
                  const SizedBox(height: 32),

                  _buildGlassCard(
                    title: 'Profile Details',
                    children: [
                      _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                      _buildTextField(_phoneController, 'NIC', Icons.badge_outlined),
                      ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Update Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
                  
                  const SizedBox(height: 24),
                  
                  _buildGlassCard(
                    title: 'My Booking History',
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('tokens')
                            .where('userNIC', isEqualTo: loggedInUserNIC)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return const Text('Error loading history.');
                          }
                          
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No booking history found.', style: TextStyle(color: AppTheme.textSecondary)),
                            );
                          }

                          final docs = snapshot.data!.docs.toList();
                          // Sort manually to avoid Firestore composite index requirement
                          docs.sort((a, b) {
                            final timeA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                            final timeB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                            if (timeA == null) return 1;
                            if (timeB == null) return -1;
                            return timeB.compareTo(timeA); // descending
                          });

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              final token = data['token'] ?? '--';
                              final service = data['service'] ?? 'Service';
                              final dateStr = data['date'] != null ? data['date'].toString().split('T')[0] : '';
                              final slot = data['slot'] ?? '';
                              final status = data['status'] ?? 'waiting';
                              
                              Color statusColor;
                              if (status == 'completed') statusColor = AppTheme.primaryColor;
                              else if (status == 'skipped') statusColor = AppTheme.warning;
                              else if (status == 'cancelled') statusColor = AppTheme.danger;
                              else statusColor = Colors.blue;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(token, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(service, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                          Text('$dateStr | $slot', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ).animate().fade(delay: 250.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),
                  
                  _buildGlassCard(
                    title: 'Change Password',
                    children: [
                      _buildTextField(_currentPasswordController, 'Current Password', Icons.lock_outline, obscure: true),
                      _buildTextField(_newPasswordController, 'New Password', Icons.lock_outline, obscure: true),
                      ElevatedButton(
                        onPressed: _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
                  
                  const SizedBox(height: 24),
                  
                  _buildGlassCard(
                    title: 'Account Management',
                    borderColor: AppTheme.danger,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _deactivateAccount,
                        icon: const Icon(Icons.pause_circle_outline, color: AppTheme.warning),
                        label: const Text('Deactivate Account', style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.warning),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _deleteAccount,
                        icon: const Icon(Icons.delete_forever, color: AppTheme.danger),
                        label: const Text('Permanently Delete Account', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.danger),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
