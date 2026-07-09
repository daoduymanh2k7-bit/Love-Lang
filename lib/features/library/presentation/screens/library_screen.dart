import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:love_lang/features/album/presentation/screens/album_list_screen.dart';
import 'package:love_lang/features/diary/presentation/screens/diary_list_screen.dart';
import 'package:love_lang/features/bucket_list/presentation/screens/bucket_list_screen.dart';
import 'package:love_lang/features/milestone/presentation/screens/milestone_screen.dart';

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

  // Trạng thái hiệu ứng "chạm vào đồng hồ": true trong lúc ngón tay còn
  // giữ trên vùng bấm -> ảnh lịch+đồng hồ tối nhẹ và co lại 1 xíu; nhả tay
  // ra thì tự dãn về như cũ (xem AnimatedScale/AnimatedOpacity bên dưới).
  bool _isClockPressed = false;
  bool _isAlbumPressed = false;
  bool _isBoardPressed = false;

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

  void _openMilestoneDialog(BuildContext context) {
    // ignore: avoid_print
    print('>>> Đã chạm vào vùng đồng hồ, đang mở dialog Cột mốc...');
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.75,
              color: const Color(0xFFFFF7EC),
              child: Stack(
                children: [
                  MilestoneScreen(
                    coupleId: widget.coupleId,
                    currentUserId: widget.currentUserId,
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left,
                          color: Color(0xFF7A4A3A), size: 30),
                      tooltip: 'Quay lại',
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

  void _openAlbumDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.75,
              color: const Color(0xFFFFF7EC),
              child: Stack(
                children: [
                  AlbumListScreen(
                    coupleId: widget.coupleId,
                    currentUserId: widget.currentUserId,
                    showAppBarBackButton: false,
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left,
                          color: Color(0xFF7A4A3A), size: 30),
                      tooltip: 'Quay lại',
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

  void _openBucketListDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.75,
              color: const Color(0xFFFFF7EC),
              child: Stack(
                children: [
                  BucketListScreen(
                    coupleId: widget.coupleId,
                    currentUserId: widget.currentUserId,
                    showAppBarBackButton: false,
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left,
                          color: Color(0xFF7A4A3A), size: 30),
                      tooltip: 'Quay lại',
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

  // Kích thước gốc (px) của bộ ảnh library_*.png — TẤT CẢ các lớp ảnh này
  // đều được thiết kế đúng bằng kích thước này (1080x2340), nên toàn bộ
  // Stack ảnh + vùng bấm bên dưới phải được đo theo đúng khung này, rồi
  // scale/crop CẢ KHỐI cùng lúc bằng FittedBox. Nếu để từng Image tự
  // BoxFit.cover riêng lẻ theo kích thước màn hình thật, mỗi máy có tỷ lệ
  // màn hình khác 1080:2340 sẽ bị zoom/crop khác nhau, khiến vùng bấm lệch
  // khỏi hình cái đồng hồ (đây là lỗi "tỷ lệ phóng đại bị sai").
  static const double _designWidth = 1080;
  static const double _designHeight = 2340;

  // Lớp ảnh nền + vùng bấm đồng hồ. Trước đây widget này được đặt làm
  // anh em cùng cấp với Scaffold trong một Stack ngoài cùng, khiến
  // Scaffold (dùng Material loại canvas, luôn hitTestSelf = true) nằm đè
  // lên và nuốt mất mọi tap, kể cả những vùng "trong suốt". Giờ đưa hẳn
  // lớp này vào làm phần tử đầu tiên trong `body` của Scaffold, để chỉ
  // còn một Material duy nhất và tap được truyền xuống đúng GestureDetector.
  Widget _buildBackgroundLayer(BuildContext context) {
    return Positioned.fill(
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: const Alignment(0, -0.3),
        child: SizedBox(
          width: _designWidth,
          height: _designHeight,
          child: Stack(
            children: [
              Image.asset(
                'assets/images/library_bg.png',
                width: _designWidth,
                height: _designHeight,
                fit: BoxFit.fill,
              ),
              AnimatedScale(
                scale: _isBoardPressed ? 0.96 : 1.0,
                duration: Duration(milliseconds: _isBoardPressed ? 100 : 180),
                curve: _isBoardPressed ? Curves.easeOut : Curves.easeOutBack,
                alignment: const Alignment(0.82, -0.57),
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/library_decor_board.png',
                      width: _designWidth,
                      height: _designHeight,
                      fit: BoxFit.fill,
                    ),
                    AnimatedOpacity(
                      opacity: _isBoardPressed ? 1.0 : 0.0,
                      duration:
                          Duration(milliseconds: _isBoardPressed ? 80 : 180),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.14),
                          BlendMode.srcATop,
                        ),
                        child: Image.asset(
                          'assets/images/library_decor_board.png',
                          width: _designWidth,
                          height: _designHeight,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Image.asset(
                'assets/images/library_decor_bookcase.png',
                width: _designWidth,
                height: _designHeight,
                fit: BoxFit.fill,
              ),
              // Hiệu ứng chạm vào album được giữ giống đồng hồ: co nhẹ khi nhấn,
              // tối đi một chút và trở lại bình thường khi thả tay.
              AnimatedScale(
                scale: _isAlbumPressed ? 0.96 : 1.0,
                duration: Duration(milliseconds: _isAlbumPressed ? 100 : 180),
                curve: _isAlbumPressed ? Curves.easeOut : Curves.easeOutBack,
                alignment: const Alignment(0.73, 0.31),
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/library_decor_album.png',
                      width: _designWidth,
                      height: _designHeight,
                      fit: BoxFit.fill,
                    ),
                    AnimatedOpacity(
                      opacity: _isAlbumPressed ? 1.0 : 0.0,
                      duration:
                          Duration(milliseconds: _isAlbumPressed ? 80 : 180),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.14),
                          BlendMode.srcATop,
                        ),
                        child: Image.asset(
                          'assets/images/library_decor_album.png',
                          width: _designWidth,
                          height: _designHeight,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Image.asset(
                'assets/images/library_character_boy_reading.png',
                width: _designWidth,
                height: _designHeight,
                fit: BoxFit.fill,
              ),
              Image.asset(
                'assets/images/library_character_girl_reading.png',
                width: _designWidth,
                height: _designHeight,
                fit: BoxFit.fill,
              ),
              // Ảnh lịch + đồng hồ được bọc trong AnimatedScale để tạo hiệu
              // ứng "bị chạm vào": khi nhấn xuống -> co lại nhẹ (0.96) và
              // tối đi 1 xíu (overlay đen mờ); khi nhả tay -> tự dãn về
              // scale 1.0 với hiệu ứng nảy nhẹ (easeOutBack) như lò xo.
              // Alignment được đặt lệch về phía vùng đồng hồ (góc dưới
              // trái) để tâm co giãn rơi đúng vào đồng hồ thay vì tâm ảnh.
              AnimatedScale(
                scale: _isClockPressed ? 0.96 : 1.0,
                duration: Duration(milliseconds: _isClockPressed ? 100 : 180),
                curve: _isClockPressed ? Curves.easeOut : Curves.easeOutBack,
                alignment: const Alignment(-0.6, 0.63),
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/library_decor_calendar_clock.png',
                      width: _designWidth,
                      height: _designHeight,
                      fit: BoxFit.fill,
                    ),
                    AnimatedOpacity(
                      opacity: _isClockPressed ? 1.0 : 0.0,
                      duration:
                          Duration(milliseconds: _isClockPressed ? 80 : 180),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.14),
                          BlendMode.srcATop,
                        ),
                        child: Image.asset(
                          'assets/images/library_decor_calendar_clock.png',
                          width: _designWidth,
                          height: _designHeight,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Vùng bấm đồng hồ tính theo tọa độ THIẾT KẾ cố định.
              Positioned(
                left: 0,
                top: _designHeight * 0.71,
                width: _designWidth * 0.39,
                height: _designHeight * 0.21,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (_) => setState(() => _isClockPressed = true),
                  onTapCancel: () => setState(() => _isClockPressed = false),
                  onTapUp: (_) => setState(() => _isClockPressed = false),
                  onTap: () => _openMilestoneDialog(context),
                ),
              ),
              // Vùng bấm cho bảng Wish List theo tỷ lệ thiết kế.
              Positioned(
                left: _designWidth * 0.83,
                top: _designHeight * 0.15,
                width: _designWidth * 0.16,
                height: _designHeight * 0.13,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (_) => setState(() => _isBoardPressed = true),
                  onTapCancel: () => setState(() => _isBoardPressed = false),
                  onTapUp: (_) => setState(() => _isBoardPressed = false),
                  onTap: () => _openBucketListDialog(context),
                ),
              ),
              // Vùng bấm cho ảnh album, căn theo tọa độ ước tính X 77%-96%, Y 62%-69%.
              Positioned(
                left: _designWidth * 0.77,
                top: _designHeight * 0.62,
                width: _designWidth * 0.19,
                height: _designHeight * 0.07,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (_) => setState(() => _isAlbumPressed = true),
                  onTapCancel: () => setState(() => _isAlbumPressed = false),
                  onTapUp: (_) => setState(() => _isAlbumPressed = false),
                  onTap: () => _openAlbumDialog(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // Trước đây lớp ảnh nằm ở Stack ngoài Scaffold nên nó vẽ full màn
      // hình, kể cả phần sau AppBar. Giờ ảnh nằm trong `body`, mà mặc định
      // Scaffold chừa khoảng trống cho AppBar rồi mới vẽ body bên dưới ->
      // ảnh bị đẩy xuống đúng bằng chiều cao AppBar (+ status bar).
      // `extendBodyBehindAppBar: true` cho body vẽ full màn hình như cũ,
      // AppBar vẫn nổi lên trên (đã trong suốt sẵn) mà không đẩy ảnh xuống.
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        toolbarHeight: 0,
        automaticallyImplyLeading: false,
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
      body: Stack(
        children: [
          _buildBackgroundLayer(context),
          if (_showFeatureIcons)
            TabBarView(
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
            ),
        ],
      ),
    );
  }
}
