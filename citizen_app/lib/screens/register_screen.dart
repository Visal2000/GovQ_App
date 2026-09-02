import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  bool _isLoading = false;

  Future<void> _register() async {
    if (_nameController.text.isNotEmpty &&
        _nicController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text) {
      
      setState(() { _isLoading = true; });

      try {
        final usersRef = FirebaseFirestore.instance.collection('users');
        
        // Check if NIC already exists
        final doc = await usersRef.doc(_nicController.text).get();
        if (doc.exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account with this NIC already exists.'), backgroundColor: AppTheme.danger),
            );
          }
        } else {
          // Register the user
          await usersRef.doc(_nicController.text).set({
            'name': _nameController.text,
            'nic': _nicController.text,
            'phone': _phoneController.text,
            'email': _emailController.text,
            'password': _passwordController.text, // Normally this should be hashed, but for simplicity here we store it
            'createdAt': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration successful! Please login.'), backgroundColor: AppTheme.success),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly.'), backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _nameController.dispose();
    _nicController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    int delay = 0,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        hintText: hintText,
        hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
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
    ).animate().fade(duration: 500.ms, delay: delay.ms).slideX(begin: -0.1, end: 0, curve: Curves.easeOutQuad);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor, // Official Light Base
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryDark),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          // Elegant animated soft-blob background using Official Colors
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Stack(
                children: [
                  // Blob 1 (Maroon)
                  Positioned(
                    top: -size.height * 0.1 + (100 * _bgController.value),
                    right: -size.width * 0.2 + (50 * _bgController.value),
                    child: Container(
                      width: size.width * 0.8,
                      height: size.width * 0.8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                  ),
                  // Blob 2 (Gold)
                  Positioned(
                    bottom: -size.height * 0.1 - (100 * _bgController.value),
                    left: -size.width * 0.2 - (50 * _bgController.value),
                    child: Container(
                      width: size.width * 0.7,
                      height: size.width * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accentColor.withOpacity(0.3),
                      ),
                    ),
                  ),
                  // Blob 3 (Light Maroon)
                  Positioned(
                    top: size.height * 0.4 - (50 * _bgController.value),
                    left: -size.width * 0.1 + (50 * _bgController.value),
                    child: Container(
                      width: size.width * 0.6,
                      height: size.width * 0.6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryLight.withOpacity(0.2),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Massive blur over the blobs to create a smooth ambient mesh gradient
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                color: Colors.white.withOpacity(0.4), // Frosty overlay
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      'Join GovQ',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ).animate().fade(duration: 600.ms, delay: 100.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                    
                    const SizedBox(height: 6),
                    Text(
                      'Register for Citizen Services',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                    ).animate().fade(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                    
                    const SizedBox(height: 32),
                    
                    // Premium Official Glassmorphic Registration Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Create Account',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: AppTheme.primaryDark,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),
                              
                              _buildCustomTextField(
                                controller: _nameController,
                                labelText: 'Full Name',
                                hintText: 'Enter your full name',
                                icon: Icons.person_outline,
                                delay: 300,
                              ),
                              const SizedBox(height: 16),
                              
                              _buildCustomTextField(
                                controller: _nicController,
                                labelText: 'NIC Number',
                                hintText: 'Enter your NIC',
                                icon: Icons.badge_outlined,
                                delay: 400,
                              ),
                              const SizedBox(height: 16),
                              
                              _buildCustomTextField(
                                controller: _phoneController,
                                labelText: 'Phone Number',
                                hintText: 'Enter your phone number',
                                icon: Icons.phone_outlined,
                                delay: 500,
                              ),
                              const SizedBox(height: 16),
                              
                              _buildCustomTextField(
                                controller: _emailController,
                                labelText: 'Email Address',
                                hintText: 'Enter your email address',
                                icon: Icons.email_outlined,
                                delay: 550,
                              ),
                              const SizedBox(height: 16),
                              
                              _buildCustomTextField(
                                controller: _passwordController,
                                labelText: 'Password',
                                hintText: 'Create a password',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                delay: 600,
                              ),
                              const SizedBox(height: 16),
                              
                              _buildCustomTextField(
                                controller: _confirmPasswordController,
                                labelText: 'Confirm Password',
                                hintText: 'Re-enter your password',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                delay: 700,
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Register Button
                              ElevatedButton(
                                onPressed: _isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 5,
                                  shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                                  disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
                                ),
                                child: _isLoading 
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text(
                                      'REGISTER',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700, 
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                              ).animate().fade(duration: 500.ms, delay: 800.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutQuart),
                              
                              const SizedBox(height: 24),
                              
                              // Login Link
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                ),
                                child: const Text(
                                  'Already have an account? Sign In',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ).animate().fade(duration: 500.ms, delay: 900.ms),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fade(duration: 700.ms, delay: 200.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
