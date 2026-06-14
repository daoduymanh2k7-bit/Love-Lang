import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:love_lang/features/pairing/presentation/providers/pairing_provider.dart';
import 'package:love_lang/features/chat/presentation/providers/chat_provider.dart';

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

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _heartAnimController;
  final List<_FloatingHeart> _floatingHearts = [];

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    super.dispose();
  }

  void _triggerNudge() async {
    // Thêm các trái tim bay
    setState(() {
      for (int i = 0; i < 6; i++) {
        _floatingHearts.add(_FloatingHeart(
          key: UniqueKey(),
          startX: 0.7 + (i * 0.05), // Quanh khu vực nút bấm
          delayMs: i * 150,
        ));
      }
    });

    try {
      await ref.read(chatSendNotifierProvider.notifier).sendNudge(
        widget.coupleId,
        widget.currentUserId,
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
    final coupleAsync = ref.watch(watchCoupleProvider(widget.coupleId));

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // 1. Full-screen background
              Positioned.fill(
                child: Image.asset(
                  'assets/images/lobby_illustration.png',
                  fit: BoxFit.cover,
                ),
              ),

              // 2. Days together counter overlay
              coupleAsync.when(
                loading: () => Positioned(
                  left: constraints.maxWidth * 0.35,
                  top: constraints.maxHeight * 0.04,
                  width: constraints.maxWidth * (0.58 - 0.35),
                  height: constraints.maxHeight * (0.21 - 0.04),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7EC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE8889A),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFE8889A),
                        ),
                      ),
                    ),
                  ),
                ),
                error: (err, stack) => Positioned(
                  left: constraints.maxWidth * 0.35,
                  top: constraints.maxHeight * 0.04,
                  width: constraints.maxWidth * (0.58 - 0.35),
                  height: constraints.maxHeight * (0.21 - 0.04),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7EC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE8889A),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.error, size: 16, color: Color(0xFFE8889A)),
                    ),
                  ),
                ),
                data: (couple) {
                  if (couple == null) return const SizedBox();
                  final days = DateTime.now().difference(couple.pairedAt).inDays;

                  return Positioned(
                    left: constraints.maxWidth * 0.35,
                    top: constraints.maxHeight * 0.04,
                    width: constraints.maxWidth * (0.58 - 0.35),
                    height: constraints.maxHeight * (0.21 - 0.04),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7EC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE8889A),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Yêu nhau được',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFE8889A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$days ngày',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFE8889A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // 3. Floating hearts animation overlays
              ..._floatingHearts.map((heart) {
                return _FloatingHeartWidget(
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

              // 4. Nudge button
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
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
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FloatingHeart {
  final Key key;
  final double startX;
  final int delayMs;

  _FloatingHeart({
    required this.key,
    required this.startX,
    required this.delayMs,
  });
}

class _FloatingHeartWidget extends StatefulWidget {
  final double startX;
  final int delayMs;
  final VoidKeyCallback onComplete;

  const _FloatingHeartWidget({
    super.key,
    required this.startX,
    required this.delayMs,
    required this.onComplete,
  });

  @override
  State<_FloatingHeartWidget> createState() => _FloatingHeartWidgetState();
}

typedef VoidKeyCallback = void Function();

class _FloatingHeartWidgetState extends State<_FloatingHeartWidget> with SingleTickerProviderStateMixin {
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
