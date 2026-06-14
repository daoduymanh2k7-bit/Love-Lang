// lib/features/bucket_list/presentation/widgets/bucket_item_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/bucket_item_entity.dart';
import '../providers/bucket_list_provider.dart';
import 'add_edit_bucket_item_sheet.dart';
import 'complete_bucket_item_dialog.dart';

class BucketItemCard extends ConsumerWidget {
  final BucketItemEntity item;
  final String currentUserId;

  const BucketItemCard({
    super.key,
    required this.item,
    required this.currentUserId,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditBucketItemSheet(
        coupleId: item.coupleId,
        currentUserId: currentUserId,
        existingItem: item,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF252535) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D3A);
    final subColor = isDark ? Colors.white54 : Colors.black45;
    final doneColor = isDark ? Colors.white38 : Colors.black26;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Xóa mục tiêu?'),
            content:
                Text('Bạn có chắc muốn xóa "${item.title}" không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white),
                child: const Text('Xóa'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref
            .read(bucketListNotifierProvider.notifier)
            .deleteItem(item.coupleId, item.id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onLongPress: item.isDone ? null : () => _openEdit(context),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Checkbox / done icon
                  _AnimatedCheckbox(
                    isDone: item.isDone,
                    onTap: item.isDone
                        ? null
                        : () => showCompleteItemDialog(
                              context: context,
                              ref: ref,
                              item: item,
                            ),
                  ),
                  const SizedBox(width: 12),

                  // Nội dung
                  if (item.completionImageUrl != null) ...[
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(item.completionImageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: item.isDone ? doneColor : textColor,
                            decoration: item.isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        if (item.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: item.isDone ? doneColor : subColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (item.isDone && item.completedAt != null) ...[
                              Icon(Icons.check_circle_rounded,
                                  size: 12,
                                  color: Colors.green.shade400),
                              const SizedBox(width: 4),
                              Text(
                                'Hoàn thành ${_formatDate(item.completedAt)}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade400),
                              ),
                            ] else ...[
                              Icon(Icons.calendar_today_rounded,
                                  size: 11, color: subColor),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(item.createdAt),
                                style:
                                    TextStyle(fontSize: 11, color: subColor),
                              ),
                            ],
                            if (item.linkedAlbumId != null) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.photo_album_rounded,
                                  size: 12,
                                  color: Color(0xFFE8889A)),
                              const SizedBox(width: 3),
                              const Text(
                                'Có kỷ niệm',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFE8889A),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Nút edit (chỉ hiện khi chưa done)
                  if (!item.isDone)
                    IconButton(
                      icon: Icon(Icons.edit_outlined,
                          size: 18, color: subColor),
                      onPressed: () => _openEdit(context),
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated checkbox — chuyển đổi mượt mà giữa trạng thái done / todo.
class _AnimatedCheckbox extends StatelessWidget {
  final bool isDone;
  final VoidCallback? onTap;

  const _AnimatedCheckbox({required this.isDone, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDone
              ? Colors.green.shade400
              : Colors.transparent,
          border: Border.all(
            color: isDone
                ? Colors.green.shade400
                : const Color(0xFFE8889A),
            width: 2,
          ),
        ),
        child: isDone
            ? const Icon(Icons.check_rounded,
                size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}
