import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:love_lang/features/album/presentation/screens/album_list_screen.dart';
import 'package:love_lang/features/diary/presentation/screens/diary_list_screen.dart';
import 'package:love_lang/features/bucket_list/presentation/screens/bucket_list_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  final String coupleId;
  final String currentUserId;

  const LibraryScreen({
    super.key,
    required this.coupleId,
    required this.currentUserId,
  });

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Thư viện',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF7A4A3A),
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: const Color(0xFFF4C0D1),
            borderRadius: BorderRadius.circular(12),
          ),
          labelColor: const Color(0xFFC1694F),
          unselectedLabelColor: const Color(0xFFA07060),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(icon: Icon(Icons.photo_album_outlined), text: 'Album'),
            Tab(icon: Icon(Icons.favorite_outline), text: 'Nhật ký'),
            Tab(icon: Icon(Icons.checklist_outlined), text: 'Bucket'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AlbumListScreen(
            coupleId: widget.coupleId,
            currentUserId: widget.currentUserId,
          ),
          DiaryListScreen(
            coupleId: widget.coupleId,
            currentUserId: widget.currentUserId,
          ),
          BucketListScreen(
            coupleId: widget.coupleId,
            currentUserId: widget.currentUserId,
          ),
        ],
      ),
    );
  }
}
