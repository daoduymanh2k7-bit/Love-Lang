import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:love_lang/core/presentation/providers/main_tab_provider.dart';
import 'package:love_lang/features/home/presentation/screens/home_screen.dart';
import 'package:love_lang/features/chat/presentation/screens/chat_screen.dart';
import 'package:love_lang/features/diary/presentation/screens/diary_list_screen.dart';
import 'package:love_lang/features/album/presentation/screens/album_list_screen.dart';
import 'package:love_lang/features/bucket_list/presentation/screens/bucket_list_screen.dart';
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

class _MainScreenState extends ConsumerState<MainScreen> {
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Khởi tạo các màn hình tính năng chính, bao bọc trong IndexedStack 
    // để giữ nguyên trạng thái State và scroll position khi chuyển tab.
    _screens = [
      HomeScreen(
        coupleId: widget.coupleId,
        currentUserId: widget.currentUserId,
      ),
      ChatScreen(
        coupleId: widget.coupleId,
        myUid: widget.currentUserId,
      ),
      DiaryListScreen(
        coupleId: widget.coupleId,
        currentUserId: widget.currentUserId,
      ),
      AlbumListScreen(
        coupleId: widget.coupleId,
        currentUserId: widget.currentUserId,
      ),
      BucketListScreen(
        coupleId: widget.coupleId,
        currentUserId: widget.currentUserId,
      ),
      ProfileScreen(
        coupleId: widget.coupleId,
        currentUserId: widget.currentUserId,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainTabProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Sử dụng IndexedStack giúp tránh việc render lại các tab chưa được focus
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Trang chủ', currentIndex, isDark),
                _buildNavItem(1, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Nhắn tin', currentIndex, isDark),
                _buildNavItem(2, Icons.favorite_rounded, Icons.favorite_outline_rounded, 'Nhật ký', currentIndex, isDark),
                _buildNavItem(3, Icons.photo_album_rounded, Icons.photo_album_outlined, 'Kỷ niệm', currentIndex, isDark),
                _buildNavItem(4, Icons.checklist_rounded, Icons.checklist_outlined, 'Bucket', currentIndex, isDark),
                _buildNavItem(5, Icons.person_rounded, Icons.person_outline_rounded, 'Cá nhân', currentIndex, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
    int currentIndex,
    bool isDark,
  ) {
    final isSelected = currentIndex == index;
    const activeColor = Color(0xFFE8889A);
    final inactiveColor = isDark ? Colors.white60 : Colors.black45;

    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(mainTabProvider.notifier).state = index;
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 16 : 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : inactiveColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}


