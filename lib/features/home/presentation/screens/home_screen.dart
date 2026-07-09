import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:love_lang/features/home/presentation/providers/home_provider.dart';
import 'package:love_lang/features/home/presentation/widgets/couple_illustration_card.dart';
import 'package:love_lang/features/home/presentation/widgets/floating_heart.dart';
import 'package:love_lang/features/home/presentation/widgets/memory_carousel_section.dart';

/// Màn hình Home.
///
/// Chỉ còn chịu trách nhiệm bố cục tổng thể (layout) và điều phối các
/// section con. Các trách nhiệm khác đã được tách ra:
/// - Hiệu ứng trái tim bay: [FloatingHeartWidget] (widgets/floating_heart.dart)
/// - Section album: [MemoryCarouselSection] (widgets/memory_carousel_section.dart)
/// - Card minh họa: [CoupleIllustrationCard] (widgets/couple_illustration_card.dart)
/// - Logic gửi nudge (vốn thuộc feature chat): [homeNudgeControllerProvider]
///   (providers/home_provider.dart)
class HomeScreen extends ConsumerStatefulWidget {
  final String coupleId;
  final String currentUserId;

  const HomeScreen({
    super.key,
    required this.coupleId,
    required this.currentUserId,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<FloatingHeart> _floatingHearts = [];

  Future<void> _triggerNudge() async {
    setState(() {
      for (int i = 0; i < 6; i++) {
        _floatingHearts.add(FloatingHeart(
          key: UniqueKey(),
          startX: 0.7 + (i * 0.05),
          delayMs: i * 150,
        ));
      }
    });

    try {
      await ref.read(homeNudgeControllerProvider).sendNudge(
            coupleId: widget.coupleId,
            currentUserId: widget.currentUserId,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.favorite, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Đã chọc đối phương! 💕',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFE8889A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFBE4D8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Main scrollable content
          SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const SizedBox(height: 24),

                  // SECTION 2: Memory Carousel
                  MemoryCarouselSection(coupleId: widget.coupleId),

                  // SECTION 3: Couple Illustration Card
                  CoupleIllustrationCard(isDark: isDark),
                ],
              ),
            ),
          ),

          // Floating hearts animation overlays
          ..._floatingHearts.map((heart) {
            return FloatingHeartWidget(
              key: heart.key,
              startX: heart.startX,
              delayMs: heart.delayMs,
              onComplete: () {
                setState(() {
                  _floatingHearts.removeWhere((h) => h.key == heart.key);
                });
              },
            );
          }),

          // Floating Nudge Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _triggerNudge,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8889A),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE8889A).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
