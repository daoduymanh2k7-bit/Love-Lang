import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:love_lang/features/album/presentation/screens/album_list_screen.dart';
import 'package:love_lang/features/diary/presentation/screens/diary_list_screen.dart';
import 'package:love_lang/features/bucket_list/presentation/screens/bucket_list_screen.dart';
import 'package:love_lang/features/home/presentation/screens/milestone_screen.dart';

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

  // TODO: đổi lại thành true khi muốn hiện lại các icon chức năng (Album, Nhật ký, Bucket, Cột mốc)
  static const bool _showFeatureIcons = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openDiaryDialog(BuildContext context) {
    // ignore: avoid_print
    print('>>> Đã chạm vào vùng đồng hồ, đang mở dialog Nhật ký...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã chạm vào đồng hồ ✅'),
        duration: Duration(milliseconds: 800),
      ),
    );
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.75,
              color: const Color(0xFFFFF7EC),
              child: Stack(
                children: [
                  DiaryListScreen(
                    coupleId: widget.coupleId,
                    currentUserId: widget.currentUserId,
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Color(0xFF7A4A3A)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/library_bg.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.3),
          ),
        ),
        Positioned.fill(
          child: Image.asset(
            'assets/images/library_character_boy_reading.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.3),
          ),
        ),
        Positioned.fill(
          child: Image.asset(
            'assets/images/library_character_girl_reading.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.3),
          ),
        ),
        Positioned.fill(
          child: Image.asset(
            'assets/images/library_decor_calendar_clock.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.3),
          ),
        ),
        Scaffold(
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
        bottom: _showFeatureIcons
            ? TabBar(
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
                  Tab(icon: Icon(Icons.flag_outlined), text: 'Cột mốc'),
                ],
              )
            : null,
      ),
      body: _showFeatureIcons
          ? TabBarView(
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
                MilestoneScreen(
                  coupleId: widget.coupleId,
                  currentUserId: widget.currentUserId,
                ),
              ],
            )
          : const SizedBox.shrink(),
        ),
        // Vùng bấm (rộng hơn hình đồng hồ 1 chút cho dễ bấm) mở popup Nhật ký
        // Đặt SAU Scaffold để nằm trên cùng, không bị Scaffold chặn tap
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return Positioned(
              left: 0,
              top: h * 0.65,
              width: w * 0.46,
              height: h * 0.28,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _openDiaryDialog(context),
              ),
            );
          },
        ),
      ],
    );
  }
}