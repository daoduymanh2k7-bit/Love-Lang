import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/album_entity.dart';
import '../../domain/entities/photo_entity.dart';
import '../providers/album_provider.dart';
import '../providers/album_state.dart';

class AlbumDetailScreen extends ConsumerStatefulWidget {
  final AlbumEntity album;
  final String currentUserId;

  const AlbumDetailScreen({
    super.key,
    required this.album,
    required this.currentUserId,
  });

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
  final PageController _pageController = PageController();
  double _currentPage = 0.0;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page != null) {
        setState(() {
          _currentPage = _pageController.page!;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      final paths = images.map((e) => e.path).toList();
      ref.read(albumNotifierProvider.notifier).uploadPhotos(
            albumId: widget.album.id,
            coupleId: widget.album.coupleId,
            uploaderId: widget.currentUserId,
            localFilePaths: paths,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final photosStream = ref.watch(photosProvider(widget.album.id));
    final albumState = ref.watch(albumNotifierProvider);
    final isUploading = albumState is AlbumLoading;

    // Hiển thị trạng thái upload
    ref.listen<AlbumState>(albumNotifierProvider, (previous, next) {
      if (next is AlbumLoaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tải ảnh lên thành công!'),
              backgroundColor: Colors.green),
        );
      } else if (next is AlbumError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.album.title,
            style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isUploading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.add_a_photo),
              onPressed: _pickAndUploadImages,
            ),
        ],
      ),
      body: photosStream.when(
        data: (photos) {
          // Nếu album rỗng, tạo vài ảnh placeholder để trải nghiệm hiệu ứng lật trang 3D
          final displayPhotos = photos.isNotEmpty
              ? photos
              : List.generate(
                  5,
                  (index) => PhotoEntity(
                    id: 'dummy_$index',
                    albumId: widget.album.id,
                    uploadedById: 'system',
                    url:
                        'https://picsum.photos/seed/${widget.album.id}_$index/600/800',
                    description: 'Ảnh kỉ niệm $index',
                    createdAt: DateTime.now(),
                  ),
                );

          if (photos.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Album đang trống. Đang hiển thị ảnh mẫu (Placeholder). Hãy nhấn icon Camera để thêm ảnh thật!'),
                  duration: Duration(seconds: 4),
                ),
              );
            });
          }

          return Center(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: PageView.builder(
                controller: _pageController,
                itemCount: displayPhotos.length,
                itemBuilder: (context, index) {
                  // Toán học tính toán góc lật trang 3D
                  // _currentPage là vị trí hiện tại (vd: 0.5, 1.0)
                  // Góc lật (value) được tính dựa trên độ lệch giữa _currentPage và index của trang
                  double value = (_currentPage - index);

                  // Giới hạn giá trị lật trong khoảng -1 đến 1 để tránh lỗi hình ảnh
                  value = value.clamp(-1.0, 1.0);

                  // Tính toán góc quay Y (rotateY) - quay tối đa 90 độ (pi / 2)
                  final double angle = value * pi / 2;

                  return Transform(
                    // Thiết lập ma trận biến đổi 3D (Matrix4)
                    // setEntry(3, 2, 0.001) tạo ra hiệu ứng phối cảnh (Perspective),
                    // giúp cho trục Z (chiều sâu) được bẻ cong, tạo cảm giác 3D.
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    alignment: value > 0
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          // Đổ bóng (Shadow) tạo chiều sâu cho khung viền của ảnh khi lật
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: Offset(value * 20,
                                10), // Bóng dịch chuyển theo góc lật
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Hình ảnh thực tế
                            Image.network(
                              displayPhotos[index].url,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                child: Icon(Icons.broken_image,
                                    color: Colors.white, size: 50),
                              ),
                            ),

                            // Lớp phủ Gradient (Gradient Overlay) tạo độ mờ (Shading) khi trang bị gấp lại
                            // Khi lật trang, góc gấp sẽ tối lại giống như cuốn sách giấy thật
                            Positioned.fill(
                              child: Opacity(
                                opacity: value.abs().clamp(0.0,
                                    0.6), // Càng lật nhiều càng tối (tối đa 60%)
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black,
                                        Colors.transparent,
                                        Colors.black,
                                      ],
                                      stops: [0.0, 0.5, 1.0],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                  ),
                                ),
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
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, stack) => Center(
            child:
                Text('Lỗi: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}
