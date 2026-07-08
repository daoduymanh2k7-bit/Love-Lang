// lib/features/bucket_list/presentation/widgets/add_edit_bucket_item_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/bucket_item_entity.dart';
import '../providers/bucket_list_provider.dart';

class AddEditBucketItemSheet extends ConsumerStatefulWidget {
  final String coupleId;
  final String currentUserId;

  /// Nếu null → chế độ thêm mới. Nếu có → chế độ chỉnh sửa.
  final BucketItemEntity? existingItem;

  const AddEditBucketItemSheet({
    super.key,
    required this.coupleId,
    required this.currentUserId,
    this.existingItem,
  });

  @override
  ConsumerState<AddEditBucketItemSheet> createState() =>
      _AddEditBucketItemSheetState();
}

class _AddEditBucketItemSheetState
    extends ConsumerState<AddEditBucketItemSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  bool _isSaving = false;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existingItem?.title ?? '');
    _descCtrl =
        TextEditingController(text: widget.existingItem?.description ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);

    final notifier = ref.read(bucketListNotifierProvider.notifier);

    if (_isEditing) {
      final updated = widget.existingItem!.copyWith(
        title: title,
        description: _descCtrl.text.trim(),
      );
      await notifier.updateItem(updated);
    } else {
      final newItem = BucketItemEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        coupleId: widget.coupleId,
        title: title,
        description: _descCtrl.text.trim(),
        isDone: false,
        createdAt: DateTime.now(),
        createdBy: widget.currentUserId,
      );
      await notifier.addItem(newItem);
    }

    if (mounted) Navigator.pop(context);
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
          // Drag handle
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

          // Tiêu đề sheet
          Text(
            _isEditing ? 'Chỉnh sửa mục tiêu' : 'Thêm mục tiêu mới',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Tên mục tiêu
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Tên mục tiêu *',
              hintText: 'VD: Đi biển cùng nhau, Học nấu ăn...',
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF8F8FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon:
                  const Icon(Icons.flag_rounded, color: Color(0xFFE8889A)),
            ),
          ),
          const SizedBox(height: 14),

          // Mô tả
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Mô tả (tuỳ chọn)',
              hintText: 'Thêm chi tiết...',
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF8F8FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon:
                  const Icon(Icons.notes_rounded, color: Color(0xFFE8889A)),
            ),
          ),
          const SizedBox(height: 24),

          // Nút lưu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8889A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isEditing ? 'Cập nhật' : 'Thêm mục tiêu',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
