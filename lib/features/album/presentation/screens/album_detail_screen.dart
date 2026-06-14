
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/entities/album_entity.dart';

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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickAndUploadImages() async {
    // Request permission for gallery access on Android
    try {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission denied to access photos')),
        );
        return;
      }
    } catch (_) {
      // ignore if permission package not available
    }
    final List<XFile> picked = await _picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1080,
      maxHeight: 1080,
    );
    if (picked.isEmpty) {
      return;
    }
    final paths = picked.map((e) => e.path).toList();
    await ref.read(albumNotifierProvider.notifier).uploadPhotos(
      albumId: widget.album.id,
      coupleId: widget.album.coupleId,
      uploaderId: widget.currentUserId,
      localFilePaths: paths,
    );
  }

  @override
  Widget build(BuildContext context) {
    final photosStream = ref.watch(photosProvider(widget.album.id));
    final albumState = ref.watch(albumNotifierProvider);
    final isUploading = albumState is AlbumLoading;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? null : const Color(0xFFFBE4D8);
    final cardColor = isDark ? null : const Color(0xFFFFF7EC);
    final accentColor = const Color(0xFFE8889A);

    // Hiển thị trạng thái upload
    ref.listen<AlbumState>(albumNotifierProvider, (previous, next) {
      if (next is AlbumLoaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tải ảnh lên thành công!'),
              backgroundColor: Colors.green),
        );
        // Invalidate photo stream to refresh UI
        ref.invalidate(photosProvider(widget.album.id));
      } else if (next is AlbumError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.album.title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : accentColor),
        centerTitle: true,
      ),
      body: photosStream.when(
        data: (photos) {
          final displayPhotos = photos;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: displayPhotos.length + 1,
            itemBuilder: (context, index) {
              if (index == displayPhotos.length) {
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
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accentColor,
                              ),
                            )
                          : Icon(
                              Icons.add,
                              color: accentColor,
                              size: 32,
                            ),
                    ),
                  ),
                );
              }

              final photo = displayPhotos[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        backgroundColor: Colors.black,
                        appBar: AppBar(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          iconTheme: const IconThemeData(color: Colors.white),
                        ),
                        body: Center(
                          child: InteractiveViewer(
                            child: CachedNetworkImage(
                              imageUrl: photo.url,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const CircularProgressIndicator(),
                              errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: photo.id,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: photo.url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDark ? Colors.white12 : Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDark ? Colors.white12 : Colors.grey[200],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: accentColor)),
        error: (err, stack) => Center(
            child:
                Text('Lỗi: $err', style: TextStyle(color: accentColor))),
      ),
    );
  }
}
