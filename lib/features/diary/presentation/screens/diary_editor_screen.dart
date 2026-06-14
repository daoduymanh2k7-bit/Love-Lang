import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/diary_entry_entity.dart';
import '../providers/diary_provider.dart';
import '../providers/diary_state.dart';

class DiaryEditorScreen extends ConsumerStatefulWidget {
  final String coupleId;
  final String currentUserId;

  const DiaryEditorScreen({
    super.key,
    required this.coupleId,
    required this.currentUserId,
  });

  @override
  ConsumerState<DiaryEditorScreen> createState() => _DiaryEditorScreenState();
}

class _DiaryEditorScreenState extends ConsumerState<DiaryEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  bool _isPrivate = false;
  String _selectedMood = '😊';

  final List<String> _moods = ['😊', '😍', '😂', '🥺', '😢', '😡', '🥰'];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng nhập đầy đủ tiêu đề và nội dung!')),
      );
      return;
    }

    final entry = DiaryEntryEntity(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(), // Thay cho Uuid() v4
      authorId: widget.currentUserId,
      coupleId: widget.coupleId,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      mood: _selectedMood,
      mediaUrls: const [], // Placeholder, xử lý chọn ảnh Firebase Storage sau
      isPrivate: _isPrivate,
      createdAt: DateTime.now(),
    );

    ref.read(diaryNotifierProvider.notifier).createEntry(entry);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DiaryState>(diaryNotifierProvider, (previous, next) {
      if (next is DiaryLoaded) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu nhật ký thành công!')),
        );
      } else if (next is DiaryError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: Colors.red),
        );
      }
    });

    final state = ref.watch(diaryNotifierProvider);
    final isLoading = state is DiaryLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Viết Kỷ Niệm'),
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _onSave,
              child: const Text('LƯU',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chọn Tâm trạng
            const Text('Tâm trạng hôm nay:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _moods.map((mood) {
                  final isSelected = mood == _selectedMood;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = mood),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.pink.shade50
                            : Colors.grey.shade100,
                        border: Border.all(
                            color: isSelected
                                ? Colors.pinkAccent
                                : Colors.transparent,
                            width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(mood, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Chế độ bí mật
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_outline,
                        color: _isPrivate ? Colors.purple : Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Nhật ký bí mật (Chỉ mình tôi xem)',
                        style: TextStyle(fontSize: 16)),
                  ],
                ),
                Switch(
                  value: _isPrivate,
                  activeThumbColor: Colors.purple,
                  onChanged: (val) => setState(() => _isPrivate = val),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Tiêu đề
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Tiêu đề nhật ký...',
                border: InputBorder.none,
              ),
              enabled: !isLoading,
            ),
            const SizedBox(height: 8),

            // Nội dung
            TextField(
              controller: _contentController,
              maxLines: null,
              minLines: 10,
              style: const TextStyle(fontSize: 16, height: 1.5),
              decoration: const InputDecoration(
                hintText: 'Hôm nay bạn và người ấy thế nào?',
                border: InputBorder.none,
              ),
              enabled: !isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
