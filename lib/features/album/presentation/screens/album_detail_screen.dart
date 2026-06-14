
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
          final displayPhotos = photos;

          if (photos.isEmpty) {
          return const Center(
            child: Text(
              'Chưa có ảnh nào',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          );
        }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
              childAspectRatio: 1,
            ),
            itemCount: displayPhotos.length,
            itemBuilder: (context, index) {
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
                  child: CachedNetworkImage(
                    imageUrl: photo.url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              );
            },
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
