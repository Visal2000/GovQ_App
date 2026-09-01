import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/formal_card.dart';

class BookingScreen extends StatefulWidget {
  final String serviceName;
  const BookingScreen({super.key, required this.serviceName});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _selectedDate;
  String? _selectedSlot;

  final List<String> _slots = [
    '09:00 AM - 10:00 AM (5 tokens left)',
    '10:00 AM - 11:00 AM (12 tokens left)',
    '11:00 AM - 12:00 PM (8 tokens left)',
    '01:00 PM - 02:00 PM (15 tokens left)',
    '02:00 PM - 03:00 PM (Available)',
  ];

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null; // reset slot when date changes
      });
    }
  }

  void _confirmBooking() {
    if (_selectedDate != null && _selectedSlot != null) {
      // Simulate booking confirmation and return true to HomeScreen
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Token'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Service: ${widget.serviceName}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
            ),
            const SizedBox(height: 20),
            FormalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Step 1: Select Date',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                      ),
                      child: Text(
                        _selectedDate == null
                            ? 'Choose Date'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: TextStyle(
                          color: _selectedDate == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedDate != null) ...[
              const SizedBox(height: 20),
              FormalCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Step 2: Select Hourly Slot',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ..._slots.map((slot) {
                      return RadioListTile<String>(
                        title: Text(slot),
                        value: slot,
                        groupValue: _selectedSlot,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (value) {
                          setState(() {
                            _selectedSlot = value;
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_selectedDate != null && _selectedSlot != null) ? _confirmBooking : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
