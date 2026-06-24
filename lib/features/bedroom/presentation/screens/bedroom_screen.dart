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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/library_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
