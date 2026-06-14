// lib/features/bucket_list/presentation/widgets/complete_bucket_item_dialog.dart

import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/bucket_item_entity.dart';
import '../providers/bucket_list_provider.dart';

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



  Future<void> _completeWithImage() async {
    setState(() => _isLoading = true);
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1080,
      maxHeight: 1080,
    );
    if (picked == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
        final cloudinary = CloudinaryPublic('dq3bk50q9', 'love_lang_bucket');
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final publicId = '${widget.item.id}_$timestamp';
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            picked.path,
            resourceType: CloudinaryResourceType.Image,
            publicId: publicId,
          ),
        );
      final imageUrl = response.secureUrl;
      await ref
          .read(bucketListNotifierProvider.notifier)
          .markDone(widget.item.coupleId, widget.item.id,
              completionImageUrl: imageUrl);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Simple error handling – could show a snackbar
      setState(() => _isLoading = false);
    }
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
              OutlinedButton(
                onPressed: _completeWithoutAlbum,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Bỏ qua'),
              ),
              ElevatedButton.icon(
                onPressed: _completeWithImage,
                icon: const Icon(Icons.photo_camera_rounded, size: 18),
                label: const Text('Thêm ảnh 📷'),
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
