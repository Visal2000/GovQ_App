import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingScreen extends StatefulWidget {
  final String serviceName;
  const BookingScreen({super.key, required this.serviceName});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with SingleTickerProviderStateMixin {
  DateTime? _selectedDate;
  String? _selectedSlot;
  late AnimationController _bgController;

  final List<String> _slots = [
    '09:00 AM - 10:00 AM (5 tokens left)',
    '10:00 AM - 11:00 AM (12 tokens left)',
    '11:00 AM - 12:00 PM (8 tokens left)',
    '01:00 PM - 02:00 PM (15 tokens left)',
    '02:00 PM - 03:00 PM (Available)',
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.primaryDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null; // reset slot when date changes
      });
    }
  }

  bool _isBooking = false;

  void _confirmBooking() async {
    if (_selectedDate != null && _selectedSlot != null) {
      setState(() { _isBooking = true; });
      try {
        final tokensRef = FirebaseFirestore.instance.collection('tokens');
        
        String prefix = 'A';
        if (_selectedSlot!.contains('09:00 AM')) prefix = 'A';
        else if (_selectedSlot!.contains('10:00 AM')) prefix = 'B';
        else if (_selectedSlot!.contains('11:00 AM')) prefix = 'C';
        else if (_selectedSlot!.contains('01:00 PM')) prefix = 'D';
        else if (_selectedSlot!.contains('02:00 PM')) prefix = 'E';

        final querySnapshot = await tokensRef.where('slot', isEqualTo: _selectedSlot).get();
        final count = querySnapshot.docs.length + 1;
        final tokenStr = '$prefix-${count.toString().padLeft(3, '0')}';

        await tokensRef.doc(tokenStr).set({
          'token': tokenStr,
          'service': widget.serviceName,
          'status': 'waiting',
          'counter': '1',
          'stageName': 'Document Submission',
          'timestamp': FieldValue.serverTimestamp(),
          'date': _selectedDate!.toIso8601String(),
          'slot': _selectedSlot,
        });

        if (mounted) {
          Navigator.pop(context, {
            'date': _selectedDate,
            'slot': _selectedSlot,
            'token': tokenStr,
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error booking token: $e')));
        }
        setState(() { _isBooking = false; });
      }
    }
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
        title: const Text('Book Appointment', style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
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
                    top: -size.height * 0.1 + (100 * _bgController.value),
                    right: -size.width * 0.2 + (50 * _bgController.value),
                    child: Container(
                      width: size.width * 0.9,
                      height: size.width * 0.9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withOpacity(0.2),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -size.height * 0.1 - (100 * _bgController.value),
                    left: -size.width * 0.1 - (50 * _bgController.value),
                    child: Container(
                      width: size.width * 0.8,
                      height: size.width * 0.8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accentColor.withOpacity(0.25),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.white.withOpacity(0.5)),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Selected Service:',
                    style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8), fontSize: 16),
                  ).animate().fade(duration: 500.ms).slideY(begin: -0.2),
                  const SizedBox(height: 8),
                  Text(
                    widget.serviceName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                  ).animate().fade(delay: 100.ms).slideY(begin: -0.2),
                  
                  const SizedBox(height: 32),
                  
                  // Step 1: Select Date (Glassmorphic)
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
                            BoxShadow(color: AppTheme.primaryColor.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 5))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.primaryLight,
                                  radius: 14,
                                  child: Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Select Date',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            InkWell(
                              onTap: _selectDate,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedDate == null
                                          ? 'Choose a date from the calendar'
                                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                      style: TextStyle(
                                        color: _selectedDate == null ? AppTheme.textSecondary.withOpacity(0.5) : AppTheme.primaryDark,
                                        fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fade(delay: 200.ms).slideY(begin: 0.1),

                  if (_selectedDate != null) ...[
                    const SizedBox(height: 24),
                    // Step 2: Select Slot
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
                              BoxShadow(color: AppTheme.primaryColor.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 5))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppTheme.primaryLight,
                                    radius: 14,
                                    child: Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Select Hourly Slot',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ..._slots.map((slot) {
                                final isSelected = _selectedSlot == slot;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedSlot = slot;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor.withOpacity(0.5),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary.withOpacity(0.5),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              slot,
                                              style: TextStyle(
                                                color: isSelected ? AppTheme.primaryDark : AppTheme.textSecondary,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ).animate().fade(delay: 300.ms).slideX(begin: 0.1);
                              }),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
                  ],

                  const SizedBox(height: 40),
                  
                  ElevatedButton(
                    onPressed: (_selectedDate != null && _selectedSlot != null && !_isBooking) ? _confirmBooking : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 5,
                      disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                    child: _isBooking 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('CONFIRM BOOKING', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ).animate().fade(delay: 400.ms).scale(begin: const Offset(0.9, 0.9)),
                  
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
