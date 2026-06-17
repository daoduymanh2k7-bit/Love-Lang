import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BedroomScreen extends ConsumerWidget {
  final String coupleId;
  final String currentUserId;

  const BedroomScreen({
    super.key,
    required this.coupleId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('🛏️', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              'Phòng ngủ',
              style: TextStyle(fontSize: 20, color: Color(0xFF7A4A3A)),
            ),
            Text(
              'Sắp ra mắt...',
              style: TextStyle(color: Color(0xFFA07060)),
            ),
          ],
        ),
      ),
    );
  }
}
