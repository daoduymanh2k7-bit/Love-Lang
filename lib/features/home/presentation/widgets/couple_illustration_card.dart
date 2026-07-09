import 'package:flutter/material.dart';

/// Card tĩnh hiển thị hình minh họa "Góc nhỏ của chúng mình" trên Home.
/// Không có state riêng nên tách thành StatelessWidget độc lập.
class CoupleIllustrationCard extends StatelessWidget {
  final bool isDark;

  const CoupleIllustrationCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C3E) : const Color(0xFFFFF7EC),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
                left: 20.0, top: 20.0, right: 20.0, bottom: 8.0),
            child: Row(
              children: [
                const Icon(Icons.home_rounded, color: Color(0xFFE8889A)),
                const SizedBox(width: 8),
                Text(
                  'Góc nhỏ của chúng mình',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF6D4C41),
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: AspectRatio(
              aspectRatio: 1.6,
              child: Image.asset(
                'assets/images/lobby_illustration.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
