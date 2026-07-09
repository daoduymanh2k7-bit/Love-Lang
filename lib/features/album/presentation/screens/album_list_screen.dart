import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../../domain/entities/album_entity.dart';
import '../providers/album_provider.dart';
import '../providers/album_state.dart';
import 'album_detail_screen.dart';

class AlbumListScreen extends ConsumerWidget {
  final String coupleId;
  final String currentUserId;
  final bool showAppBarBackButton;

  const AlbumListScreen({
    super.key,
    required this.coupleId,
    required this.currentUserId,
    this.showAppBarBackButton = true,
  });

  void _showCreateAlbumDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo Album Kỷ Niệm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                  labelText: 'Tên Album (vd: Mùa hè 2026)'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Mô tả ngắn'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              final newAlbum = AlbumEntity(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                coupleId: coupleId,
                title: titleController.text.trim(),
                coverUrl: 'https://picsum.photos/400/400',
                description: descController.text.trim(),
                createdAt: DateTime.now(),
              );
              ref.read(albumNotifierProvider.notifier).createAlbum(newAlbum);
              Navigator.pop(context);
            },
            child: const Text('Tạo mới'),
          ),
        ],
      ),
    );
  }

  void _showAlbumOptions(
      BuildContext context, WidgetRef ref, AlbumEntity album) {
    const accentColor = Color(0xFFE8889A);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline,
                  color: accentColor),
              title: const Text('Đổi tên album'),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(context, ref, album);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined, color: accentColor),
              title: const Text('Đổi ảnh bìa'),
              onTap: () {
                Navigator.pop(ctx);
                _pickNewCover(context, ref, album);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note_outlined, color: accentColor),
              title: const Text('Sửa mô tả'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditDescDialog(context, ref, album);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title:
                  const Text('Xóa album', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteConfirm(context, ref, album);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, WidgetRef ref, AlbumEntity album) {
    final controller = TextEditingController(text: album.title);
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
                  .updateAlbum(album.id, title: newTitle);
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showEditDescDialog(
      BuildContext context, WidgetRef ref, AlbumEntity album) {
    final controller = TextEditingController(text: album.description);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa mô tả'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Mô tả'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              ref.read(albumNotifierProvider.notifier).updateAlbum(
                    album.id,
                    description: controller.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickNewCover(
      BuildContext context, WidgetRef ref, AlbumEntity album) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked == null) return;
    if (!context.mounted) return;
    try {
      final cloudinary =
          CloudinaryPublic('dq3bk50q9', 'love_lang_bucket', cache: false);
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(picked.path,
            resourceType: CloudinaryResourceType.Image),
      );
      if (!context.mounted) return;
      ref
          .read(albumNotifierProvider.notifier)
          .updateAlbum(album.id, coverUrl: response.secureUrl);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lỗi khi tải ảnh bìa lên'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _showDeleteConfirm(
      BuildContext context, WidgetRef ref, AlbumEntity album) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa album?'),
        content: Text(
            'Album "${album.title}" và toàn bộ ảnh bên trong sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(albumNotifierProvider.notifier)
                  .deleteAlbum(album.id);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsStream = ref.watch(albumsProvider(coupleId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? null : Colors.transparent;
    final cardColor = isDark ? null : const Color(0xFFFFF7EC);
    const accentColor = Color(0xFFE8889A);

    ref.listen<AlbumState>(albumNotifierProvider, (previous, next) {
      if (next is AlbumError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: showAppBarBackButton
          ? AppBar(
              title: const Text('Kho Ảnh Kỷ Niệm',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: true,
              iconTheme:
                  IconThemeData(color: isDark ? Colors.white : accentColor),
            )
          : null,
      body: albumsStream.when(
        data: (albums) {
          if (albums.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có album nào.\nHãy tạo album đầu tiên nhé!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.82,
            ),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlbumDetailScreen(
                      album: album,
                      currentUserId: currentUserId,
                    ),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: cardColor ?? Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: Consumer(
                            builder: (context, ref, child) {
                              final photosStream =
                                  ref.watch(photosProvider(album.id));
                              return photosStream.when(
                                data: (photos) {
                                  if (photos.isEmpty) {
                                    return Container(
                                      color: isDark
                                          ? Colors.white12
                                          : Colors.grey[100],
                                      child: Icon(Icons.camera_alt,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.grey,
                                          size: 40),
                                    );
                                  }
                                  return CachedNetworkImage(
                                    imageUrl: photos.first.url,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                          child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image,
                                          color: Colors.grey),
                                    ),
                                  );
                                },
                                loading: () => const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                                error: (err, stack) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 4, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    album.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.more_vert,
                                    size: 20,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey.shade600,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () =>
                                      _showAlbumOptions(context, ref, album),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Consumer(
                              builder: (context, ref, child) {
                                final photosStream =
                                    ref.watch(photosProvider(album.id));
                                final dateStr =
                                    '${album.createdAt.day}/${album.createdAt.month}/${album.createdAt.year}';
                                return photosStream.when(
                                  data: (photos) => Text(
                                    '$dateStr · ${photos.length} ảnh',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  loading: () => Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  error: (_, __) => Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      ),
      floatingActionButton: Padding(
        padding:
            EdgeInsets.only(bottom: 72 + MediaQuery.of(context).padding.bottom),
        child: FloatingActionButton.extended(
          onPressed: () => _showCreateAlbumDialog(context, ref),
          backgroundColor: accentColor,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Tạo Album'),
        ),
      ),
    );
  }
}