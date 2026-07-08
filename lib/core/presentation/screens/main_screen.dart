import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:love_lang/core/presentation/providers/main_tab_provider.dart';
import 'package:love_lang/features/home/presentation/screens/home_screen.dart';
import 'package:love_lang/features/chat/presentation/screens/chat_screen.dart';
import 'package:love_lang/features/library/presentation/screens/library_screen.dart';
import 'package:love_lang/features/bedroom/presentation/screens/bedroom_screen.dart';
import 'package:love_lang/features/profile/presentation/screens/profile_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  final String coupleId;
  final String currentUserId;

  const MainScreen({
    super.key,
    required this.coupleId,
    required this.currentUserId,
  });

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with TickerProviderStateMixin {
  late final List<Widget> _screens;
  bool _menuOpen = false;
  late AnimationController _rotateController;
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _itemScales;
  late List<Animation<double>> _itemOpacities;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
          coupleId: widget.coupleId, currentUserId: widget.currentUserId),
      ChatScreen(coupleId: widget.coupleId, myUid: widget.currentUserId),
      LibraryScreen(
          coupleId: widget.coupleId, currentUserId: widget.currentUserId),
      BedroomScreen(
          coupleId: widget.coupleId, currentUserId: widget.currentUserId),
    ];

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _itemControllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 250),
      ),
    );

    _itemScales = _itemControllers
        .map(
          (c) => Tween<double>(begin: 0.3, end: 1.0).animate(
            CurvedAnimation(parent: c, curve: Curves.easeOut),
          ),
        )
        .toList();

    _itemOpacities = _itemControllers
        .map(
          (c) => Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: c, curve: Curves.easeOut),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    for (final c in _itemControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggleMenu() {
    setState(() => _menuOpen = !_menuOpen);
    if (_menuOpen) {
      _rotateController.forward();
      for (var i = 0; i < _itemControllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 60), () {
          if (mounted) _itemControllers[i].forward();
        });
      }
    } else {
      _rotateController.reverse();
      for (final c in _itemControllers) {
        c.reverse();
      }
    }
  }

  void _onNavTap(int navIndex) {
    if (navIndex == 2) {
      _toggleMenu();
      return;
    }
    final stackIndex = navIndex < 2 ? navIndex : navIndex - 1;
    ref.read(mainTabProvider.notifier).state = stackIndex;
    if (_menuOpen) {
      setState(() => _menuOpen = false);
      _rotateController.reverse();
      for (final c in _itemControllers) {
        c.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainTabProvider);
    final navHighlight = currentIndex < 2 ? currentIndex : currentIndex + 1;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: currentIndex,
            children: _screens,
          ),
          if (_menuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMenu,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    color: Colors.brown.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          if (_menuOpen) _buildRadialMenu(context),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, Icons.weekend_rounded,
                          Icons.weekend_outlined, 'Phòng khách', navHighlight),
                      _buildNavItem(
                          1,
                          Icons.chat_bubble_rounded,
                          Icons.chat_bubble_outline_rounded,
                          'Trò chuyện',
                          navHighlight),
                      _buildMenuButton(),
                      _buildNavItem(
                          3,
                          Icons.auto_stories_rounded,
                          Icons.auto_stories_outlined,
                          'Thư viện',
                          navHighlight),
                      _buildNavItem(
                          4,
                          Icons.library_books_rounded,
                          Icons.library_books_outlined,
                          'Thư viện mới',
                          navHighlight),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int navIndex,
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
    int currentNavHighlight,
  ) {
    final isSelected = currentNavHighlight == navIndex;
    const activeColor = Color(0xFFC1694F);
    const inactiveColor = Color(0xFFA07060);

    return Expanded(
      child: InkWell(
        onTap: () => _onNavTap(navIndex),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 32,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                color: isSelected ? Colors.white : inactiveColor,
                size: 18,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 7,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton() {
    return Expanded(
      child: InkWell(
        onTap: () => _onNavTap(2),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _rotateController,
              builder: (context, child) => Transform.rotate(
                angle: _rotateController.value * 0.785398,
                child: child,
              ),
              child: Container(
                width: 38,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4C0D1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFFC1694F),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Tuỳ chọn',
              style: TextStyle(
                fontSize: 7,
                color: Color(0xFFA07060),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadialMenu(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final navBottom = 12 + MediaQuery.of(context).padding.bottom;
    final centerX = screenWidth / 2;
    final centerY = screenHeight - navBottom - 44;

    final offsets = [
      Offset(centerX - 65, centerY - 52),
      Offset(centerX, centerY - 80),
      Offset(centerX + 65, centerY - 52),
    ];

    final labels = ['Sắp có', 'Hồ sơ', 'Sắp có'];
    final icons = [Icons.more_horiz, Icons.person_rounded, Icons.more_horiz];
    final isReal = [false, true, false];

    return Stack(
      children: List.generate(3, (i) {
        return Positioned(
          left: offsets[i].dx - 28,
          top: offsets[i].dy - 28,
          child: ScaleTransition(
            scale: _itemScales[i],
            child: FadeTransition(
              opacity: _itemOpacities[i],
              child: GestureDetector(
                onTap: isReal[i]
                    ? () {
                        _toggleMenu();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(
                              coupleId: widget.coupleId,
                              currentUserId: widget.currentUserId,
                            ),
                          ),
                        );
                      }
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isReal[i]
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isReal[i]
                              ? const Color(0xFFC1694F)
                              : Colors.white.withValues(alpha: 0.5),
                          width: isReal[i] ? 2 : 1.5,
                        ),
                        boxShadow: isReal[i]
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        icons[i],
                        color: isReal[i]
                            ? const Color(0xFFC1694F)
                            : Colors.white.withValues(alpha: 0.6),
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 11,
                        color: isReal[i]
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                        fontWeight:
                            isReal[i] ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
