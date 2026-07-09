import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:love_lang/core/presentation/providers/main_tab_provider.dart';
import 'package:love_lang/features/album/presentation/providers/album_provider.dart';

/// Section "Album kỷ niệm" hiển thị trên màn hình Home.
///
/// Tự quản lý [PageController] và trang hiện tại của carousel, thay vì để
/// HomeScreen (widget cha) giữ state này — giúp HomeScreen không cần biết
/// chi tiết bên trong của carousel.
class MemoryCarouselSection extends ConsumerStatefulWidget {
  final String coupleId;

  const MemoryCarouselSection({super.key, required this.coupleId});

  @override
  ConsumerState<MemoryCarouselSection> createState() =>
      _MemoryCarouselSectionState();
}

class _MemoryCarouselSectionState
    extends ConsumerState<MemoryCarouselSection> {
  late final PageController _albumPageController;
  int _currentAlbumPage = 0;

  @override
  void initState() {
    super.initState();
    _albumPageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _albumPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final albumsAsync = ref.watch(albumsProvider(widget.coupleId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            'Album kỷ niệm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF6D4C41),
            ),
          ),
        ),
        albumsAsync.when(
          loading: () => const SizedBox(
            height: 180,
            child: Center(
                child: CircularProgressIndicator(color: Color(0xFFE8889A))),
          ),
          error: (err, stack) => Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text('Lỗi: $err')),
          ),
          data: (albums) {
            if (albums.isEmpty) {
              return _EmptyAlbumPlaceholder(isDark: isDark);
            }

            return Column(
              children: [
                SizedBox(
                  height: 180,
                  child: PageView.builder(
                    controller: _albumPageController,
                    itemCount: albums.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentAlbumPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      return _AlbumCard(album: album);
                    },
                  ),
                ),
                if (albums.length > 1) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      albums.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentAlbumPage == index
                              ? const Color(0xFFE8889A)
                              : const Color(0xFFE8889A).withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EmptyAlbumPlaceholder extends ConsumerWidget {
  final bool isDark;
  const _EmptyAlbumPlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(mainTabProvider.notifier).state = 3;
      },
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C3E) : const Color(0xFFFFF7EC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE8889A).withValues(alpha: 0.5),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 40, color: Color(0xFFE8889A)),
            SizedBox(height: 8),
            Text(
              'Chưa có album nào. Tạo ngay nào!',
              style: TextStyle(
                color: Color(0xFFE8889A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumCard extends ConsumerWidget {
  final dynamic album;
  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(mainTabProvider.notifier).state = 3;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: album.coverUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: album.coverUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                              child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFFFF7EC),
                        child: const Icon(
                          Icons.photo_library,
                          size: 48,
                          color: Color(0xFFE8889A),
                        ),
                      ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (album.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        album.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
