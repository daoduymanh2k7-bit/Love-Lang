import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
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
  final ImagePicker _picker = ImagePicker();
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;

  static const accentColor = Color(0xFFE8889A);

  // ── Upload ─────────────────────────────────────────────────────────────────

  Future<void> _pickAndUploadImages() async {
    try {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có quyền truy cập thư viện ảnh')),
        );
        return;
      }
    } catch (_) {}

    final List<XFile> picked = await _picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1080,
      maxHeight: 1080,
    );
    if (picked.isEmpty) return;

    await ref.read(albumNotifierProvider.notifier).uploadPhotos(
          albumId: widget.album.id,
          coupleId: widget.album.coupleId,
          uploaderId: widget.currentUserId,
          localFilePaths: picked.map((e) => e.path).toList(),
        );
  }

  // ── Selection mode ─────────────────────────────────────────────────────────

  void _toggleSelection(String photoId) {
    setState(() {
      if (_selectedIds.contains(photoId)) {
        _selectedIds.remove(photoId);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(photoId);
      }
    });
  }

  void _enterSelectionMode(String photoId) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(photoId);
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    final ids = List<String>.from(_selectedIds);
    final confirm = await _showConfirmDialog(
      'Xóa ${ids.length} ảnh?',
      'Ảnh đã xóa không thể khôi phục.',
    );
    if (!confirm) return;
    _cancelSelection();
    await ref
        .read(albumNotifierProvider.notifier)
        .deletePhotos(widget.album.id, ids);
  }

  // ── Xóa ảnh đơn (từ fullscreen) ───────────────────────────────────────────

  Future<void> _deleteSinglePhoto(PhotoEntity photo) async {
    final confirm =
        await _showConfirmDialog('Xóa ảnh này?', 'Không thể hoàn tác.');
    if (!confirm) return;
    if (!mounted) return;
    Navigator.pop(context); // đóng fullscreen
    await ref
        .read(albumNotifierProvider.notifier)
        .deletePhoto(widget.album.id, photo.id);
  }

  // ── Album menu (3 chấm AppBar) ─────────────────────────────────────────────

  void _showAlbumMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline,
                  color: accentColor),
              title: const Text('Đổi tên album'),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title:
                  const Text('Xóa album', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteAlbumConfirm();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog() {
    final controller = TextEditingController(text: widget.album.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi tên album'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tên mới'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isEmpty) return;
              ref
                  .read(albumNotifierProvider.notifier)
                  .updateAlbum(widget.album.id, title: newTitle);
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAlbumConfirm() async {
    final confirm = await _showConfirmDialog(
      'Xóa album "${widget.album.title}"?',
      'Toàn bộ ảnh trong album sẽ bị xóa vĩnh viễn.',
    );
    if (!confirm) return;
    if (!mounted) return;
    final success = await ref
        .read(albumNotifierProvider.notifier)
        .deleteAlbum(widget.album.id);
    if (success && mounted) Navigator.pop(context);
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Hủy')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Xóa', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Mở fullscreen ─────────────────────────────────────────────────────────

  void _openFullscreen(List<PhotoEntity> photos, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenViewer(
          photos: photos,
          initialIndex: initialIndex,
          onDelete: _deleteSinglePhoto,
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final photosStream = ref.watch(photosProvider(widget.album.id));
    final albumState = ref.watch(albumNotifierProvider);
    final isUploading = albumState is AlbumLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? null : const Color(0xFFFBE4D8);
    final cardColor = isDark ? null : const Color(0xFFFFF7EC);

    ref.listen<AlbumState>(albumNotifierProvider, (previous, next) {
      if (next is AlbumLoaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Thành công!'), backgroundColor: Colors.green),
        );
        ref.invalidate(photosProvider(widget.album.id));
      } else if (next is AlbumError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _selectionMode
          ? AppBar(
              backgroundColor: accentColor,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _cancelSelection,
              ),
              title: Text(
                'Đã chọn ${_selectedIds.length}',
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _deleteSelected,
                ),
              ],
            )
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                widget.album.title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              iconTheme:
                  IconThemeData(color: isDark ? Colors.white : accentColor),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.more_vert,
                      color: isDark ? Colors.white : Colors.black87),
                  onPressed: _showAlbumMenu,
                ),
              ],
            ),
      body: photosStream.when(
        data: (photos) {
          if (photos.isEmpty && !isUploading) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_outlined,
                      size: 64,
                      color: isDark ? Colors.white38 : Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có ảnh nào.\nNhấn + để thêm ảnh!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _pickAndUploadImages,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Thêm ảnh'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: accentColor),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            // Thêm 1 ô "+" ở cuối khi không ở selection mode
            itemCount: photos.length + (_selectionMode ? 0 : 1),
            itemBuilder: (context, index) {
              // Ô thêm ảnh
              if (!_selectionMode && index == photos.length) {
                return GestureDetector(
                  onTap: isUploading ? null : _pickAndUploadImages,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor ?? const Color(0xFFFFF7EC),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isUploading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: accentColor),
                            )
                          : const Icon(Icons.add, color: accentColor, size: 32),
                    ),
                  ),
                );
              }

              final photo = photos[index];
              final isSelected = _selectedIds.contains(photo.id);

              return GestureDetector(
                onTap: () {
                  if (_selectionMode) {
                    _toggleSelection(photo.id);
                  } else {
                    _openFullscreen(photos, index);
                  }
                },
                onLongPress: () {
                  if (!_selectionMode) _enterSelectionMode(photo.id);
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: photo.id,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: photo.url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: Colors.grey[200]),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image,
                                color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    // Overlay selection
                    if (_selectionMode)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected
                              ? accentColor.withValues(alpha: 0.4)
                              : Colors.transparent,
                        ),
                      ),
                    if (_selectionMode)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? accentColor : Colors.white70,
                            border: Border.all(
                                color: isSelected ? accentColor : Colors.grey,
                                width: 1.5),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }
}

// ── Fullscreen viewer ──────────────────────────────────────────────────────

class _FullscreenViewer extends StatefulWidget {
  final List<PhotoEntity> photos;
  final int initialIndex;
  final Future<void> Function(PhotoEntity) onDelete;

  const _FullscreenViewer({
    required this.photos,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  State<_FullscreenViewer> createState() => _FullscreenViewerState();
}

class _FullscreenViewerState extends State<_FullscreenViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.photos.length;
    final photo = widget.photos[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        iconTheme: const IconThemeData(color: Colors.white),
        // Hiển thị "3/12"
        title: Text(
          '${_currentIndex + 1}/$total',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Xóa ảnh',
            onPressed: () => widget.onDelete(photo),
          ),
        ],
      ),
      body: GestureDetector(
        // Swipe xuống → đóng
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            Navigator.pop(context);
          }
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: total,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (context, index) {
            final p = widget.photos[index];
            return Hero(
              tag: p.id,
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: p.url,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image,
                        color: Colors.white, size: 64),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
