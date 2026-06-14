// lib/features/bucket_list/presentation/screens/bucket_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bucket_list_provider.dart';
import '../widgets/bucket_item_card.dart';
import '../widgets/add_edit_bucket_item_sheet.dart';

class BucketListScreen extends ConsumerStatefulWidget {
  final String coupleId;
  final String currentUserId;

  const BucketListScreen({
    super.key,
    required this.coupleId,
    required this.currentUserId,
  });

  @override
  ConsumerState<BucketListScreen> createState() => _BucketListScreenState();
}

class _BucketListScreenState extends ConsumerState<BucketListScreen>
    with SingleTickerProviderStateMixin {
  bool _showDoneSection = true;

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditBucketItemSheet(
        coupleId: widget.coupleId,
        currentUserId: widget.currentUserId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemsAsync = ref.watch(bucketItemsProvider(widget.coupleId));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12121E) : const Color(0xFFF5F5FA),
      body: itemsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFE8889A)),
        ),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
        data: (items) {
          final todo = items.where((i) => !i.isDone).toList();
          final done = items.where((i) => i.isDone).toList();
          final total = items.length;
          final doneCount = done.length;

          return CustomScrollView(
            slivers: [
              // ─── Header SliverAppBar ────────────────────────────────────
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor:
                    isDark ? const Color(0xFF1E1E2C) : Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeader(
                      isDark, doneCount, total, context),
                  collapseMode: CollapseMode.parallax,
                ),
                // Title chỉ hiện khi collapsed
                title: const Text(
                  'Bucket List',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                centerTitle: true,
                // FAB trong header
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_rounded,
                        color: Color(0xFFE8889A)),
                    onPressed: _openAddSheet,
                    tooltip: 'Thêm mục tiêu',
                  ),
                ],
              ),

              // ─── Danh sách chưa làm ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.radio_button_unchecked,
                          size: 18, color: Color(0xFFE8889A)),
                      const SizedBox(width: 8),
                      Text(
                        'Chưa làm (${todo.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (todo.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: _EmptyTodo(onAdd: _openAddSheet),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => BucketItemCard(
                        item: todo[i],
                        currentUserId: widget.currentUserId,
                      ),
                      childCount: todo.length,
                    ),
                  ),
                ),

              // ─── Divider ────────────────────────────────────────────────
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // ─── Section "Đã hoàn thành" có thể thu/mở ─────────────────
              if (done.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () =>
                          setState(() => _showDoneSection = !_showDoneSection),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 18, color: Colors.green.shade400),
                          const SizedBox(width: 8),
                          Text(
                            'Đã hoàn thành (${done.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.green.shade400,
                            ),
                          ),
                          const Spacer(),
                          AnimatedRotation(
                            duration: const Duration(milliseconds: 200),
                            turns: _showDoneSection ? 0 : -0.25,
                            child: Icon(Icons.expand_more_rounded,
                                color: Colors.green.shade400),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_showDoneSection)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => BucketItemCard(
                          item: done[i],
                          currentUserId: widget.currentUserId,
                        ),
                        childCount: done.length,
                      ),
                    ),
                  ),
              ],

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        backgroundColor: const Color(0xFFE8889A),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Thêm mục tiêu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildHeader(
      bool isDark, int doneCount, int total, BuildContext context) {
    final progress = total == 0 ? 0.0 : doneCount / total;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8889A), Color(0xFF9B6BB5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                '🌟 Bucket List',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Những điều muốn làm cùng nhau',
                style: TextStyle(
                  fontSize: 14,
                  // ignore: deprecated_member_use
color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 20),

              // Progress
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          total == 0
                              ? 'Chưa có mục tiêu nào'
                              : 'Đã hoàn thành $doneCount / $total mục tiêu',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOut,
                            builder: (_, value, __) =>
                                LinearProgressIndicator(
                              value: value,
                              minHeight: 8,
                              // ignore: deprecated_member_use
backgroundColor: Colors.white.withValues(alpha: 0.3),
                              valueColor: const AlwaysStoppedAnimation(
                                  Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Phần trăm hoàn thành
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      total == 0
                          ? '0%'
                          : '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget hiển thị khi chưa có mục tiêu nào.
class _EmptyTodo extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyTodo({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // ignore: deprecated_member_use
color: const Color(0xFFE8889A).withValues(alpha: 0.3),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          const Text('✨', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          const Text(
            'Chưa có mục tiêu nào!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hãy thêm những điều bạn muốn\nlàm cùng người ấy nhé 💕',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm mục tiêu đầu tiên'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8889A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
