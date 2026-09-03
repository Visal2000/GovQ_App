import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_screen.dart';
import 'booking_screen.dart';
import 'history_screen.dart';
import '../global.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  String? _selectedDepartment;
  String? _selectedService;
  bool _hasActiveToken = false;
  bool _isBlocked = false;
  bool _isCheckedIn = false;
  int _currentStage = 0;
  bool _isLoadingToken = true;
  DateTime? _bookedDate;
  String? _bookedSlot;
  late AnimationController _bgController;
  StreamSubscription<DocumentSnapshot>? _myTokenSubscription;
  
  String _liveServingToken = '--';
  String _liveNextToken = '--';
  String _myToken = 'A-104';

  final Map<String, List<String>> _departmentServices = {
    'Department of Registration of Persons (NIC)': [
      'New ID - One Day Service',
      'New ID - Normal Service',
      'ID Renewal / Amendment',
      'Lost ID Replacement'
    ],
  };

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 25),
    )..repeat(reverse: true);

    FirebaseFirestore.instance
        .collection('queues')
        .doc('tv_display')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data()!;
        setState(() {
          _liveServingToken = data['activeToken']?['token'] ?? '--';
          if (data['nextTokens'] != null && (data['nextTokens'] as List).isNotEmpty) {
            _liveNextToken = data['nextTokens'][0]['token'] ?? '--';
          } else {
            _liveNextToken = '--';
          }
        });
      }
    });

    _checkExistingToken();
  }

  Future<void> _checkExistingToken() async {
    if (loggedInUserNIC.isEmpty) {
      if (mounted) setState(() => _isLoadingToken = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tokens')
          .where('userNIC', isEqualTo: loggedInUserNIC)
          .where('status', whereIn: ['waiting', 'serving'])
          .get();

      if (snapshot.docs.isNotEmpty) {
        final activeDoc = snapshot.docs.first;
        final data = activeDoc.data();
        
        if (mounted) {
          setState(() {
            _hasActiveToken = true;
            _myToken = data['token'] ?? _myToken;
            _bookedSlot = data['slot'];
            _selectedService = data['service']?.split(' - ').last ?? '';
            _selectedDepartment = data['service']?.split(' - ').first ?? '';
            if (data['date'] != null) {
              _bookedDate = DateTime.parse(data['date']);
            }
          });
          _listenToMyToken(_myToken);
        }
      }
    } catch (e) {
      debugPrint("Error checking existing token: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingToken = false;
        });
      }
    }
  }

  void _listenToMyToken(String tokenStr) {
    _myTokenSubscription?.cancel();
    _myTokenSubscription = FirebaseFirestore.instance
        .collection('tokens')
        .doc(tokenStr)
        .snapshots()
        .listen((snap) {
      if (snap.exists && snap.data() != null) {
        final data = snap.data()!;
        if (data['status'] == 'completed' || 
            data['status'] == 'skipped' || 
            data['status'] == 'cancelled') {
          setState(() {
            _hasActiveToken = false;
            _isCheckedIn = false;
          });
          _myTokenSubscription?.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Your token has been ${data['status']}.'),
                backgroundColor: AppTheme.primaryColor,
              ),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _myTokenSubscription?.cancel();
    super.dispose();
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    loggedInUserNIC = '';
    loggedInUserName = '';
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _bookToken() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          serviceName: '$_selectedDepartment - $_selectedService',
        ),
      ),
    );

    if (result is Map) {
      setState(() {
        _hasActiveToken = true;
        _isCheckedIn = false;
        _bookedDate = result['date'];
        _bookedSlot = result['slot'];
        if (result['token'] != null) {
          _myToken = result['token'];
        }
      });

      _listenToMyToken(_myToken);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token successfully booked!')),
        );
      }
    }
  }

  void _cancelToken() async {
    if (_bookedDate == null || _bookedSlot == null) return;
    
    try {
      final parts = _bookedSlot!.split(' - ');
      final startTimeStr = parts[0];
      
      final timeParts = startTimeStr.split(' ');
      final hm = timeParts[0].split(':');
      int hour = int.parse(hm[0]);
      final int min = int.parse(hm[1]);
      if (timeParts[1] == 'PM' && hour != 12) hour += 12;
      if (timeParts[1] == 'AM' && hour == 12) hour = 0;
      
      final slotDateTime = DateTime(_bookedDate!.year, _bookedDate!.month, _bookedDate!.day, hour, min);
      final now = DateTime.now();
      
      if (slotDateTime.difference(now).inHours < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cancellation Failed: You cannot cancel a token within 4 hours of the scheduled time.'),
            backgroundColor: AppTheme.danger,
          ),
        );
        return;
      }
      
      await FirebaseFirestore.instance.collection('tokens').doc(_myToken).update({'status': 'cancelled'});
      
      setState(() {
        _hasActiveToken = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token cancelled successfully.')),
      );
    } catch (e) {
      debugPrint('Error cancelling token: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cancel token.'), backgroundColor: AppTheme.danger),
      );
    }
  }

  void _simulateNoShow() {
    setState(() {
      _hasActiveToken = false;
      _isCheckedIn = false;
      _isBlocked = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulated No-Show: Account blocked for 7 days.'),
        backgroundColor: AppTheme.danger,
      ),
    );
  }

  void _checkIn() {
    setState(() {
      _isCheckedIn = true;
      _currentStage = 0; // Waiting in lobby
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checked In successfully. The lobby display will call you shortly.'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _nextStage() {
    if (_currentStage < 3) {
      setState(() {
        _currentStage++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Token called to Stage $_currentStage!'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    } else {
      _simulateCompleteToken();
    }
  }

  void _simulateCompleteToken() {
    setState(() {
      _hasActiveToken = false;
      _isCheckedIn = false;
      _currentStage = 0;
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Token Completed', style: TextStyle(color: AppTheme.primaryColor)),
        content: const Text('The counter has finished processing your token. Your session is now closed.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularServiceCard(String title, String desc, IconData icon, Color color) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryDark)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: AppTheme.textSecondary, height: 1.4))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isToday = _bookedDate != null && 
                         _bookedDate!.year == DateTime.now().year && 
                         _bookedDate!.month == DateTime.now().month && 
                         _bookedDate!.day == DateTime.now().day;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ).animate().fade().scale(delay: 300.ms),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.primaryColor),
              accountName: const Text('Visal Hewage', style: TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: const Text('visal@example.com'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: AppTheme.primaryColor, size: 40),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: AppTheme.primaryDark),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context); // close drawer
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: AppTheme.primaryDark),
              title: const Text('Booking History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent, color: AppTheme.primaryDark),
              title: const Text('Contact Support'),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.danger),
              title: const Text('Logout', style: TextStyle(color: AppTheme.danger)),
              onTap: _logout,
            ),
          ],
        ),
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
                    top: -size.height * 0.1 + (150 * _bgController.value),
                    left: -size.width * 0.1 - (100 * _bgController.value),
                    child: Container(
                      width: size.width * 1.2,
                      height: size.width * 1.2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryLight.withOpacity(0.15),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -size.height * 0.2 - (150 * _bgController.value),
                    right: -size.width * 0.2 + (100 * _bgController.value),
                    child: Container(
                      width: size.width,
                      height: size.width,
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
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: Container(color: Colors.white.withOpacity(0.5)),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8), fontSize: 16),
                            ),
                            Text(
                              'Visal Hewage',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: AppTheme.primaryDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.accentColor, width: 2),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/logo.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fade(duration: 600.ms).slideY(begin: -0.2),
                  
                  const SizedBox(height: 32),

                  if (_isLoadingToken)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(color: AppTheme.primaryColor),
                      ),
                    )
                  else if (_hasActiveToken)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.5)),
                            boxShadow: [
                              BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'MY BOOKING',
                                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                  ),
                                  if (isToday)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white24,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.circle, color: AppTheme.accentLight, size: 10),
                                          SizedBox(width: 6),
                                          Text('LIVE QUEUE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                                     .fade(begin: 0.5, end: 1.0, duration: 1.seconds)
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white24,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text('UPCOMING', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Your Token: $_myToken',
                                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$_selectedDepartment\n$_selectedService',
                                style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
                              ),
                              const SizedBox(height: 24),
                              
                              // Live Queue Status Section
                              if (isToday) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Currently Serving:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                          Text(_liveServingToken, style: const TextStyle(color: AppTheme.accentLight, fontWeight: FontWeight.bold, fontSize: 18)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Next Token:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                          Text(_liveNextToken, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                        ],
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12.0),
                                        child: Divider(color: Colors.white24, height: 1),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Your Time Slot', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                              const SizedBox(height: 4),
                                              Text(_bookedSlot ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          const Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text('Est. Wait', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                              SizedBox(height: 4),
                                              Text('15 mins', style: TextStyle(color: AppTheme.accentLight, fontWeight: FontWeight.bold, fontSize: 16)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline, color: AppTheme.accentLight),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Live queue tracking will be available here on ${_bookedDate?.day}/${_bookedDate?.month}/${_bookedDate?.year}.',
                                          style: const TextStyle(color: Colors.white, height: 1.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              
                              if (isToday)
                                if (!_isCheckedIn)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _checkIn,
                                      icon: const Icon(Icons.how_to_reg, color: AppTheme.primaryDark),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.accentColor,
                                        foregroundColor: AppTheme.primaryDark,
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 5,
                                      ),
                                      label: const Text('I HAVE ARRIVED (CHECK-IN)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                    ),
                                  ).animate().fade().scale(delay: 200.ms)
                                else
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _currentStage == 0 ? Colors.green.withOpacity(0.2) : AppTheme.accentColor.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: _currentStage == 0 ? Colors.greenAccent : Colors.white),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          _currentStage == 0 ? Icons.check_circle : Icons.notifications_active, 
                                          color: _currentStage == 0 ? Colors.greenAccent : AppTheme.primaryDark, 
                                          size: 32
                                        ).animate(target: _currentStage > 0 ? 1 : 0).shake(),
                                        const SizedBox(height: 8),
                                        Text(
                                          _currentStage == 0 ? 'Checked In - Waiting in Lobby' : 'PROCEED TO COUNTER', 
                                          style: TextStyle(
                                            color: _currentStage == 0 ? Colors.white : AppTheme.primaryDark, 
                                            fontWeight: FontWeight.bold, 
                                            fontSize: 18
                                          )
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _currentStage == 0 
                                            ? 'Please wait until your number is called for Document Submission.' 
                                            : _currentStage == 1 
                                              ? 'Counter 1: Document Submission\nPlease go to Counter 1 now.'
                                              : _currentStage == 2
                                                ? 'Counter 4: Payment\nPlease pay your processing fee.'
                                                : 'Counter 6: Collection\nYour ID is ready for collection.', 
                                          textAlign: TextAlign.center, 
                                          style: TextStyle(
                                            color: _currentStage == 0 ? Colors.white70 : AppTheme.primaryDark.withOpacity(0.8), 
                                            fontSize: 14,
                                            fontWeight: _currentStage > 0 ? FontWeight.bold : FontWeight.normal
                                          )
                                        ),
                                      ],
                                    ),
                                  ).animate().fade().scale(),
                                  
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _cancelToken,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white54),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: const Text('Cancel Token'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: _simulateNoShow,
                                      style: TextButton.styleFrom(foregroundColor: AppTheme.accentLight),
                                      child: const Text('No-Show', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton(
                                      onPressed: _isCheckedIn ? _nextStage : null,
                                      style: TextButton.styleFrom(foregroundColor: _isCheckedIn ? Colors.amberAccent : Colors.grey),
                                      child: Text(_currentStage < 3 ? 'Simulate Next Counter' : 'Simulate Finish', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ).animate().fade(duration: 600.ms).slideY(begin: 0.2, curve: Curves.easeOutQuart)
                  else if (_isBlocked)
                    // Blocked User Section
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.danger, width: 2),
                            boxShadow: [
                              BoxShadow(color: AppTheme.danger.withOpacity(0.15), blurRadius: 25, offset: const Offset(0, 10))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.block, color: AppTheme.danger, size: 64),
                              const SizedBox(height: 16),
                              const Text(
                                'Account Blocked',
                                style: TextStyle(color: AppTheme.danger, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'You missed a scheduled appointment without cancelling it at least 4 hours in advance. As per government policy, you cannot book a new token for 7 days.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.primaryDark, fontSize: 15, height: 1.5),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.danger.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Unblocks on: ${'7 days from now'}', // In a real app this would be a formatted date
                                  style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 24),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isBlocked = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Block lifted (Debug).')),
                                  );
                                },
                                child: const Text('Reset Block (Simulate Time Passed)', style: TextStyle(color: AppTheme.primaryColor)),
                              )
                            ],
                          ),
                        ),
                      ),
                    ).animate().fade(duration: 600.ms, delay: 200.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart)
                  else
                    // New Booking Section
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(color: AppTheme.primaryColor.withOpacity(0.08), blurRadius: 25, offset: const Offset(0, 10))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.calendar_month, color: AppTheme.primaryColor),
                                  SizedBox(width: 12),
                                  Text(
                                    'Book New Appointment',
                                    style: TextStyle(color: AppTheme.primaryDark, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              
                              // Department Dropdown
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Select Department',
                                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                                  prefixIcon: const Icon(Icons.account_balance, color: AppTheme.primaryColor),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppTheme.borderColor.withOpacity(0.5))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
                                ),
                                value: _selectedDepartment,
                                items: _departmentServices.keys.map((dept) {
                                  return DropdownMenuItem(value: dept, child: Text(dept, overflow: TextOverflow.ellipsis));
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDepartment = value;
                                    _selectedService = null; // reset service
                                  });
                                },
                                isExpanded: true,
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Service Dropdown
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Select Service',
                                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                                  prefixIcon: const Icon(Icons.description_outlined, color: AppTheme.primaryColor),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppTheme.borderColor.withOpacity(0.5))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
                                ),
                                value: _selectedService,
                                items: _selectedDepartment == null 
                                  ? [] 
                                  : _departmentServices[_selectedDepartment]!.map((service) {
                                      return DropdownMenuItem(value: service, child: Text(service, overflow: TextOverflow.ellipsis));
                                    }).toList(),
                                onChanged: _selectedDepartment == null ? null : (value) {
                                  setState(() {
                                    _selectedService = value;
                                  });
                                },
                                isExpanded: true,
                                disabledHint: const Text('Please select a department first'),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              ElevatedButton(
                                onPressed: _selectedService != null ? _bookToken : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 5,
                                ),
                                child: const Text('PROCEED TO BOOKING', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fade(duration: 600.ms, delay: 200.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),

                  const SizedBox(height: 40),

                  // Popular Services Section
                  const Text(
                    'Popular Services',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                  ).animate().fade(delay: 400.ms),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    height: 180,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildPopularServiceCard('Passport', 'New Issuance & Renewal', Icons.flight_takeoff, Colors.blue.shade700),
                        _buildPopularServiceCard('Driving License', 'New, Renewal & Updates', Icons.drive_eta, Colors.green.shade700),
                        _buildPopularServiceCard('Civil Registry', 'Birth & Marriage Certs', Icons.family_restroom, Colors.orange.shade700),
                        _buildPopularServiceCard('Pensions', 'Registration & Inquiries', Icons.account_balance_wallet, Colors.purple.shade700),
                      ].animate(interval: 100.ms).fade(delay: 500.ms).slideX(begin: 0.2, curve: Curves.easeOutQuad),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Important Information Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: AppTheme.primaryDark),
                            SizedBox(width: 8),
                            Text('Booking Guidelines', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(Icons.check_circle_outline, 'Tokens are issued strictly for an hourly slot. Please arrive on time.'),
                        _buildInfoRow(Icons.rule, '4-Hour Cancellation Rule: You cannot cancel a token within 4 hours of the slot.'),
                        _buildInfoRow(Icons.warning_amber_rounded, 'No-Show Policy: Missing an appointment without cancelling results in a 7-day booking block.'),
                      ],
                    ),
                  ).animate().fade(delay: 700.ms).slideY(begin: 0.1),

                  const SizedBox(height: 40),

                  // Contact Details
                  const Text(
                    'Need Help?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                  ).animate().fade(delay: 800.ms),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(backgroundColor: AppTheme.primaryLight, child: Icon(Icons.call, color: Colors.white)),
                          title: Text('GovQ Hotline 1919', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                          subtitle: Text('Toll-free, 24/7 Support'),
                        ),
                        Divider(height: 24),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(backgroundColor: AppTheme.accentColor, child: Icon(Icons.email, color: AppTheme.primaryDark)),
                          title: Text('support@govq.lk', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                          subtitle: Text('Average response time: 2 hours'),
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 900.ms).slideY(begin: 0.1),

                  const SizedBox(height: 40),
                  
                  // Footer Logo
                  Center(
                    child: Opacity(
                      opacity: 0.5,
                      child: Column(
                        children: [
                          Image.asset('assets/images/logo.png', height: 40, errorBuilder: (c, e, s) => const Icon(Icons.account_balance, color: AppTheme.primaryColor)),
                          const SizedBox(height: 8),
                          const Text('GovQ © 2026. All Rights Reserved.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ).animate().fade(delay: 1000.ms),
                  
                  const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
