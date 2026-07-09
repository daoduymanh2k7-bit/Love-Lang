import 'package:flutter/material.dart';

/// Data model cho một trái tim đang bay lên (dùng khi trigger nudge).
class FloatingHeart {
  final Key key;
  final double startX;
  final int delayMs;

  FloatingHeart({
    required this.key,
    required this.startX,
    required this.delayMs,
  });
}

typedef VoidKeyCallback = void Function();

/// Widget hiển thị 1 icon trái tim bay lên rồi biến mất, dùng cho hiệu ứng
/// "nudge" ở màn hình Home. Tách riêng khỏi HomeScreen để có thể tái sử dụng
/// và test độc lập.
class FloatingHeartWidget extends StatefulWidget {
  final double startX;
  final int delayMs;
  final VoidKeyCallback onComplete;

  const FloatingHeartWidget({
    super.key,
    required this.startX,
    required this.delayMs,
    required this.onComplete,
  });

  @override
  State<FloatingHeartWidget> createState() => _FloatingHeartWidgetState();
}

class _FloatingHeartWidgetState extends State<FloatingHeartWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _yAnim;
  late final Animation<double> _opacityAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _yAnim = Tween<double>(begin: 0.0, end: -200.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _scaleAnim = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.forward().then((_) => widget.onComplete());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final startY = MediaQuery.of(context).padding.top + 32;

        return Positioned(
          left: screenWidth * widget.startX - 12,
          top: startY + _yAnim.value,
          child: Opacity(
            opacity: _opacityAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: const Icon(
                Icons.favorite,
                color: Color(0xFFE8889A),
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }
}
