import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/diary_provider.dart';
import 'diary_editor_screen.dart';

class DiaryListScreen extends ConsumerWidget {
  final String coupleId;
  final String currentUserId;

  const DiaryListScreen({
    super.key,
    required this.coupleId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diaryStream = ref.watch(diaryEntriesProvider((coupleId: coupleId, currentUserId: currentUserId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhật ký Tình yêu'),
        centerTitle: true,
      ),
      body: diaryStream.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có bài nhật ký nào.\nHãy viết kỷ niệm đầu tiên nhé!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              // Có thể dùng thông tin isMyEntry để custom giao diện
              // ignore: unused_local_variable
              final isMyEntry = entry.authorId == currentUserId;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                entry.mood,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              ),
                            ],
                          ),
                          if (entry.isPrivate)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.lock, size: 14, color: Colors.purple.shade300),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Chỉ mình tôi',
                                    style: TextStyle(fontSize: 12, color: Colors.purple.shade400),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        entry.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.content,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Đã có lỗi xảy ra: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DiaryEditorScreen(
                coupleId: coupleId,
                currentUserId: currentUserId,
              ),
            ),
          );
        },
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.edit),
      ),
    );
  }
}
