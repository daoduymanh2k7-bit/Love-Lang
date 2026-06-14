// lib/features/bucket_list/presentation/widgets/complete_bucket_item_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/bucket_item_entity.dart';
import '../providers/bucket_list_provider.dart';
import '../../../album/domain/entities/album_entity.dart';
import '../../../album/presentation/providers/album_provider.dart';

/// Dialog hiện khi tick "hoàn thành" một bucket item.
/// Hỏi người dùng có muốn tạo album kỷ niệm liên kết không.
Future<void> showCompleteItemDialog({
  required BuildContext context,
  required WidgetRef ref,
  required BucketItemEntity item,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => _CompleteItemDialog(item: item),
  );
}

class _CompleteItemDialog extends ConsumerStatefulWidget {
  final BucketItemEntity item;
  const _CompleteItemDialog({required this.item});

  @override
  ConsumerState<_CompleteItemDialog> createState() =>
      _CompleteItemDialogState();
}

class _CompleteItemDialogState extends ConsumerState<_CompleteItemDialog> {
  bool _isLoading = false;

  Future<void> _completeWithoutAlbum() async {
    setState(() => _isLoading = true);
    await ref
        .read(bucketListNotifierProvider.notifier)
        .markDone(widget.item.coupleId, widget.item.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _completeWithAlbum() async {
    // Đóng dialog trước
    if (mounted) Navigator.pop(context);

    // Mở bottom sheet để đặt tên album
    if (!mounted) return;
    final albumTitle = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateAlbumSheet(suggestedTitle: widget.item.title),
    );

    if (albumTitle == null || albumTitle.trim().isEmpty) {
      // Người dùng huỷ → vẫn đánh dấu done nhưng không tạo album
      await ref
          .read(bucketListNotifierProvider.notifier)
          .markDone(widget.item.coupleId, widget.item.id);
      return;
    }

    // Tạo album
    final newAlbum = AlbumEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      coupleId: widget.item.coupleId,
      title: albumTitle.trim(),
      coverUrl: 'https://picsum.photos/seed/${widget.item.id}/400/400',
      description: 'Kỷ niệm: ${widget.item.title}',
      createdAt: DateTime.now(),
    );

    final albumId =
        await ref.read(albumNotifierProvider.notifier).createAlbum(newAlbum);

    // Đánh dấu done + gắn albumId
    await ref
        .read(bucketListNotifierProvider.notifier)
        .markDone(widget.item.coupleId, widget.item.id,
            linkedAlbumId: albumId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji celebration
          const Text('🎉', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          const Text(
            'Chúc mừng!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '"${widget.item.title}"',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white70 : Colors.black54,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn đã hoàn thành mục tiêu này!\nMuốn lưu vào Kỷ niệm không?',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: _isLoading
          ? [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(color: Color(0xFFE8889A)),
              ),
            ]
          : [
              // Nút "Không"
              OutlinedButton(
                onPressed: _completeWithoutAlbum,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Không, cảm ơn'),
              ),
              // Nút "Tạo kỷ niệm"
              ElevatedButton.icon(
                onPressed: _completeWithAlbum,
                icon: const Icon(Icons.photo_album_rounded, size: 18),
                label: const Text('Tạo kỷ niệm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8889A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
    );
  }
}

/// Bottom sheet để người dùng đặt tên album kỷ niệm.
class _CreateAlbumSheet extends StatefulWidget {
  final String suggestedTitle;
  const _CreateAlbumSheet({required this.suggestedTitle});

  @override
  State<_CreateAlbumSheet> createState() => _CreateAlbumSheetState();
}

class _CreateAlbumSheetState extends State<_CreateAlbumSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.suggestedTitle);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E2C) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '📸 Đặt tên album kỷ niệm',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Tên album...',
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF8F8FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Bỏ qua'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _ctrl.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8889A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Tạo Album'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
