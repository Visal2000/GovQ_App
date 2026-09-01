import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/formal_card.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'booking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _services = [
    'National Identity Card Renewal',
    'Passport Application',
    'Birth Certificate Copy',
    'Vehicle Revenue License',
  ];
  
  String? _selectedService;
  bool _hasActiveToken = false;

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _bookToken() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(serviceName: _selectedService!),
      ),
    );

    if (result == true) {
      setState(() {
        _hasActiveToken = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token successfully booked!')),
        );
      }
    }
  }

  void _cancelToken() {
    setState(() {
      _hasActiveToken = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Token cancelled successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GovQ Citizen Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/bg.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Welcome back, Visal',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select a service below to book your token.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  if (_hasActiveToken) ...[
                    FormalCard(
                      borderColor: AppTheme.accentColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Active Token',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'Confirmed',
                                  style: TextStyle(
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'A-045',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Text(
                            'National Identity Card Renewal',
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Scheduled Time:', style: TextStyle(color: AppTheme.textSecondary)),
                              Text('10:00 AM - 11:00 AM', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Current Serving:', style: TextStyle(color: AppTheme.textSecondary)),
                              Text('A-042', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: _cancelToken,
                            icon: const Icon(Icons.cancel, color: AppTheme.danger),
                            label: const Text('Cancel Token', style: TextStyle(color: AppTheme.danger)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.danger),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Note: Tokens can only be cancelled 4 hours prior to the slot.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Book a New Token',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FormalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Select Service',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedService,
                            items: _services.map((service) {
                              return DropdownMenuItem(
                                value: service,
                                child: Text(service),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedService = value;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _selectedService != null ? _bookToken : null,
                            child: const Text('Check Availability & Book'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
