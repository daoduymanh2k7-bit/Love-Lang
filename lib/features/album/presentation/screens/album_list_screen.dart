import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/album_entity.dart';
import '../providers/album_provider.dart';
import '../providers/album_state.dart';
import 'album_detail_screen.dart';

class AlbumListScreen extends ConsumerWidget {
  final String coupleId;
  final String currentUserId;

  const AlbumListScreen({
    super.key,
    required this.coupleId,
    required this.currentUserId,
  });

  void _showCreateAlbumDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tạo Album Kỷ Niệm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Tên Album (vd: Mùa hè 2026)'),
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
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                
                final newAlbum = AlbumEntity(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  coupleId: coupleId,
                  title: titleController.text.trim(),
                  coverUrl: 'https://picsum.photos/400/400', // Placeholder cover
                  description: descController.text.trim(),
                  createdAt: DateTime.now(),
                );
                
                ref.read(albumNotifierProvider.notifier).createAlbum(newAlbum);
                Navigator.pop(context);
              },
              child: const Text('Tạo mới'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsStream = ref.watch(albumsProvider(coupleId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? null : const Color(0xFFFBE4D8);
    final cardColor = isDark ? null : const Color(0xFFFFF7EC);
    final accentColor = const Color(0xFFE8889A);

    // Lắng nghe trạng thái tạo album để báo lỗi hoặc thành công (nếu cần)
    ref.listen<AlbumState>(albumNotifierProvider, (previous, next) {
      if (next is AlbumError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Kho Ảnh Kỷ Niệm', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : accentColor),
      ),
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
              childAspectRatio: 0.85,
            ),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AlbumDetailScreen(
                        album: album,
                        currentUserId: currentUserId,
                      ),
                    ),
                  );
                },
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
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Consumer(
                            builder: (context, ref, child) {
                              final photosStream = ref.watch(photosProvider(album.id));
                              return photosStream.when(
                                data: (photos) {
                                  if (photos.isEmpty) {
                                    return Container(
                                      color: isDark ? Colors.white12 : Colors.grey[100],
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: isDark ? Colors.white38 : Colors.grey,
                                        size: 40,
                                      ),
                                    );
                                  }
                                  return CachedNetworkImage(
                                    imageUrl: photos.first.url,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  );
                                },
                                loading: () => const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                error: (err, stack) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              album.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${album.createdAt.day}/${album.createdAt.month}/${album.createdAt.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : Colors.grey.shade600,
                              ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAlbumDialog(context, ref),
        backgroundColor: accentColor,
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text('Tạo Album'),
      ),
    );
  }
}
