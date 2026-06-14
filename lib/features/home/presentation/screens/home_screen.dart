import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:love_lang/core/presentation/providers/main_tab_provider.dart';
import 'package:love_lang/features/pairing/presentation/providers/pairing_provider.dart';
import 'package:love_lang/features/chat/presentation/providers/chat_provider.dart';
import 'package:love_lang/features/album/presentation/providers/album_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:love_lang/core/constants/firestore_paths.dart';

final homeUserDocProvider = StreamProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, uid) {
  return FirebaseFirestore.instance
      .doc(FirestorePaths.userDoc(uid))
      .snapshots()
      .map((doc) => doc.data());
});

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
  late final PageController _albumPageController;
  int _currentAlbumPage = 0;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _albumPageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    _albumPageController.dispose();
    super.dispose();
  }

  void _triggerNudge() async {
    setState(() {
      for (int i = 0; i < 6; i++) {
        _floatingHearts.add(_FloatingHeart(
          key: UniqueKey(),
          startX: 0.7 + (i * 0.05),
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
    final albumsAsync = ref.watch(albumsProvider(widget.coupleId));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFBE4D8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Main scrollable content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // SECTION 1: Anniversary Card (Header)
                  _buildAnniversaryCard(coupleAsync, isDark),
                  
                  const SizedBox(height: 24),
                  
                  // SECTION 2: Memory Carousel
                  _buildMemoryCarouselSection(albumsAsync, isDark),
                  
                  const SizedBox(height: 24),
                  
                  // SECTION 3: Couple Illustration Card
                  _buildCoupleIllustrationCard(isDark),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Floating hearts animation overlays
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

  Widget _buildAnniversaryCard(AsyncValue<dynamic> coupleAsync, bool isDark) {
    return coupleAsync.when(
      loading: () => _buildCardShimmer(),
      error: (err, stack) => _buildCardError(err.toString()),
      data: (couple) {
        if (couple == null) return const SizedBox();
        final days = DateTime.now().difference(couple.pairedAt).inDays;
        
        final partnerUid = couple.uid1 == widget.currentUserId ? couple.uid2 : couple.uid1;
        final myUserAsync = ref.watch(homeUserDocProvider(widget.currentUserId));
        final partnerUserAsync = ref.watch(homeUserDocProvider(partnerUid));

        final String myName = myUserAsync.value?['displayName'] as String? ?? 'Bạn';
        final String partnerName = partnerUserAsync.value?['displayName'] as String? ?? 'Đối phương';

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD6E8), Color(0xFFE0C3FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE0C3FC).withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      myName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6D4C41),
                      ),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Icon(
                      Icons.favorite,
                      color: Color(0xFFE8889A),
                      size: 28,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      partnerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6D4C41),
                      ),
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Bên nhau được',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5D4037),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$days',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE8889A),
                      shadows: [
                        Shadow(
                          color: Colors.white,
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ngày',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardShimmer() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFFE8889A)),
      ),
    );
  }

  Widget _buildCardError(String err) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Center(
        child: Text('Lỗi tải dữ liệu: $err', style: TextStyle(color: Colors.red.shade700)),
      ),
    );
  }

  Widget _buildMemoryCarouselSection(AsyncValue<List<dynamic>> albumsAsync, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            'Album kỷ niệm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF6D4C41),
            ),
          ),
        ),
        albumsAsync.when(
          loading: () => const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator(color: Color(0xFFE8889A))),
          ),
          error: (err, stack) => Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text('Lỗi: $err')),
          ),
          data: (albums) {
            if (albums.isEmpty) {
              return GestureDetector(
                onTap: () {
                  ref.read(mainTabProvider.notifier).state = 3; // Switch to AlbumListScreen tab
                },
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C3E) : const Color(0xFFFFF7EC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE8889A).withValues(alpha: 0.5),
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 40, color: Color(0xFFE8889A)),
                      SizedBox(height: 8),
                      Text(
                        'Chưa có album nào. Tạo ngay nào!',
                        style: TextStyle(
                          color: Color(0xFFE8889A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                SizedBox(
                  height: 180,
                  child: PageView.builder(
                    controller: _albumPageController,
                    itemCount: albums.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentAlbumPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      return GestureDetector(
                        onTap: () {
                          ref.read(mainTabProvider.notifier).state = 3; // Switch to Album tab
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: album.coverUrl.isNotEmpty
                                      ? Image.network(
                                          album.coverUrl,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: const Color(0xFFFFF7EC),
                                          child: const Icon(
                                            Icons.photo_library,
                                            size: 48,
                                            color: Color(0xFFE8889A),
                                          ),
                                        ),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.7),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 16,
                                  left: 16,
                                  right: 16,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        album.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (album.description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          album.description,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (albums.length > 1) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      albums.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentAlbumPage == index
                              ? const Color(0xFFE8889A)
                              : const Color(0xFFE8889A).withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCoupleIllustrationCard(bool isDark) {
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
            padding: const EdgeInsets.only(left: 20.0, top: 20.0, right: 20.0, bottom: 8.0),
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
