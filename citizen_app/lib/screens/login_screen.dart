import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../global.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _nicController = TextEditingController();
  final _passwordController = TextEditingController();
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

  Future<void> _login() async {
    final nic = _nicController.text.trim();
    final password = _passwordController.text.trim();

    if (nic.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter NIC and password.'), backgroundColor: AppTheme.danger),
      );
      return;
    }

    if (!RegExp(r'^([0-9]{9}[vVxX]|[0-9]{12})$').hasMatch(nic)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid NIC format. Enter 9 digits + V/X or 12 digits.'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    setState(() { _isLoading = true; });
    try {
      final usersRef = FirebaseFirestore.instance.collection('users');
      final doc = await usersRef.doc(nic).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['password'] == password) {
          loggedInUserNIC = nic;
          loggedInUserName = data['name'] ?? 'Citizen';

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('loggedInUserNIC', loggedInUserNIC);
          await prefs.setString('loggedInUserName', loggedInUserName);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid password.'), backgroundColor: AppTheme.danger),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account not found. Please register.'), backgroundColor: AppTheme.danger),
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
  }

  void _showForgotPasswordDialog() {
    final nicResetController = TextEditingController();
    final phoneResetController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool isVerifying = false;
    bool isVerified = false;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isVerified) ...[
                      const Text('Enter your NIC and registered phone number to verify your identity.'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nicResetController,
                        decoration: const InputDecoration(labelText: 'NIC Number', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: phoneResetController,
                        decoration: const InputDecoration(labelText: 'Phone Number (e.g. 0771234567)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.phone,
                      ),
                    ] else ...[
                      const Text('Identity verified. Please enter your new password.'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: newPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isVerifying ? null : () async {
                    if (!isVerified) {
                      final nic = nicResetController.text.trim();
                      final phone = phoneResetController.text.trim();
                      if (nic.isEmpty || phone.isEmpty) return;
                      
                      setDialogState(() => isVerifying = true);
                      try {
                        final doc = await FirebaseFirestore.instance.collection('users').doc(nic).get();
                        if (doc.exists && doc.data()?['phone'] == phone) {
                          setDialogState(() {
                            isVerified = true;
                            isVerifying = false;
                          });
                        } else {
                          setDialogState(() => isVerifying = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Details do not match our records.'), backgroundColor: AppTheme.danger),
                            );
                          }
                        }
                      } catch (e) {
                        setDialogState(() => isVerifying = false);
                      }
                    } else {
                      final newPass = newPasswordController.text.trim();
                      if (newPass.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password must be at least 6 characters.'), backgroundColor: AppTheme.warning),
                        );
                        return;
                      }
                      
                      setDialogState(() => isVerifying = true);
                      try {
                        await FirebaseFirestore.instance.collection('users').doc(nicResetController.text.trim()).update({
                          'password': newPass,
                        });
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password reset successfully! You can now log in.'), backgroundColor: AppTheme.success),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isVerifying = false);
                      }
                    }
                  },
                  child: isVerifying 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : Text(isVerified ? 'Reset Password' : 'Verify Identity'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _nicController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor, // Official Light Base
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
                    left: -size.width * 0.2 + (50 * _bgController.value),
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
                    right: -size.width * 0.2 - (50 * _bgController.value),
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
                    top: size.height * 0.3 - (50 * _bgController.value),
                    right: -size.width * 0.1 + (50 * _bgController.value),
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with subtle official shadow
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Image.asset(
                          'assets/images/logo.png',
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.account_balance, 
                            size: 45, 
                            color: AppTheme.primaryColor
                          ),
                        ),
                      ),
                    ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack).fadeIn(duration: 800.ms),
                    
                    const SizedBox(height: 20),
                    
                    // Title
                    Text(
                      'GovQ Portal',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ).animate().fade(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                    
                    const SizedBox(height: 6),
                    Text(
                      'Digital Citizen Services',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                    ).animate().fade(duration: 600.ms, delay: 300.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                    
                    const SizedBox(height: 48),
                    
                    // Premium Official Glassmorphic Login Card
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
                                'Sign In',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: AppTheme.primaryDark,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),
                              
                              // Custom NIC Input
                              TextFormField(
                                controller: _nicController,
                                style: const TextStyle(color: AppTheme.textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'NIC Number',
                                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                                  hintText: 'Enter your NIC',
                                  hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
                                  prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.primaryColor),
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
                              ).animate().fade(duration: 500.ms, delay: 400.ms).slideX(begin: -0.1, end: 0, curve: Curves.easeOutQuad),
                              
                              const SizedBox(height: 16),
                              
                              // Custom Password Input
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                style: const TextStyle(color: AppTheme.textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                                  hintText: 'Enter your password',
                                  hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
                                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryColor),
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
                              ).animate().fade(duration: 500.ms, delay: 500.ms).slideX(begin: -0.1, end: 0, curve: Curves.easeOutQuad),
                              
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _showForgotPasswordDialog,
                                  style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                                  child: const Text('Forgot Password?', style: TextStyle(fontWeight: FontWeight.w600)),
                                ),
                              ).animate().fade(duration: 500.ms, delay: 550.ms),
                              
                              const SizedBox(height: 16),
                              
                              // Login Button
                              ElevatedButton(
                                onPressed: _isLoading ? null : _login,
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
                                      'LOGIN',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700, 
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                              ).animate().fade(duration: 500.ms, delay: 600.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutQuart),
                              
                              const SizedBox(height: 24),
                              
                              // Register Link
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                ),
                                child: const Text(
                                  'New Citizen? Register Here',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ).animate().fade(duration: 500.ms, delay: 700.ms),
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
