import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../global.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryDark),
        title: const Text('Booking History', style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tokens')
                  .where('userNIC', isEqualTo: loggedInUserNIC)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading history.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No booking history found.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  );
                }

                final docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  final timeA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  final timeB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  if (timeA == null) return 1;
                  if (timeB == null) return -1;
                  return timeB.compareTo(timeA);
                });

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final token = data['token'] ?? '--';
                    final service = data['service'] ?? 'Unknown Service';
                    final dateStr = data['date'] != null ? data['date'].toString().split('T')[0] : '';
                    final slot = data['slot'] ?? '';
                    final status = (data['status'] ?? 'waiting').toString().toUpperCase();
                    
                    final department = service.split(' - ').first;
                    final serviceType = service.split(' - ').last;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: ClipRRect(
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
                                    Text(
                                      'TOKEN $token',
                                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white24,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '$department\n$serviceType',
                                  style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Date', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Text(dateStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text('Time Slot', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Text(slot, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fade(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.1);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
