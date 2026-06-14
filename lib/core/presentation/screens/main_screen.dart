import 'package:flutter/material.dart';
import 'package:love_lang/features/home/presentation/screens/home_screen.dart';
import 'package:love_lang/features/chat/presentation/screens/chat_screen.dart';
import 'package:love_lang/features/diary/presentation/screens/diary_list_screen.dart';
import 'package:love_lang/features/album/presentation/screens/album_list_screen.dart';
import 'package:love_lang/features/profile/presentation/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  final String coupleId;
  final String currentUserId;

  const MainScreen({
    super.key,
    required this.coupleId,
    required this.currentUserId,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

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
      ProfileScreen(
        coupleId: widget.coupleId,
        currentUserId: widget.currentUserId,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sử dụng IndexedStack giúp tránh việc render lại các tab chưa được focus
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.pink.shade50,
        indicatorColor: Colors.pinkAccent.shade100,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.pinkAccent),
            selectedIcon: Icon(Icons.home, color: Colors.white),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline, color: Colors.pinkAccent),
            selectedIcon: Icon(Icons.chat_bubble, color: Colors.white),
            label: 'Nhắn tin',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline, color: Colors.pinkAccent),
            selectedIcon: Icon(Icons.favorite, color: Colors.white),
            label: 'Nhật ký',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_album_outlined, color: Colors.pinkAccent),
            selectedIcon: Icon(Icons.photo_album, color: Colors.white),
            label: 'Kỷ niệm',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: Colors.pinkAccent),
            selectedIcon: Icon(Icons.person, color: Colors.white),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
