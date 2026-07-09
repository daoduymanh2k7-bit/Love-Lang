import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:love_lang/features/pairing/presentation/providers/pairing_provider.dart';
import '../../domain/entities/milestone_entity.dart';
import '../providers/milestone_provider.dart';

class MilestoneScreen extends ConsumerStatefulWidget {
  final String coupleId;
  final String currentUserId;

  const MilestoneScreen({
    super.key,
    required this.coupleId,
    required this.currentUserId,
  });

  @override
  ConsumerState<MilestoneScreen> createState() => _MilestoneScreenState();
}

class _MilestoneScreenState extends ConsumerState<MilestoneScreen>
    with TickerProviderStateMixin {
  late final PageController _milestonePageController;
  int _currentMilestonePage = 0;

  @override
  void initState() {
    super.initState();
    _milestonePageController = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _milestonePageController.dispose();
    super.dispose();
  }

  void _showAddEditMilestoneBottomSheet([MilestoneEntity? milestone]) {
    final titleController = TextEditingController(text: milestone?.title);
    DateTime selectedDate = milestone?.date ?? DateTime.now();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7EC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        milestone == null
                            ? 'Thêm cột mốc mới'
                            : 'Chỉnh sửa cột mốc',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6D4C41),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Tên cột mốc',
                      hintText: 'Ví dụ: Lần đầu gặp nhau, Ngày đính hôn',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      if (!mounted) return;
                      final currentContext = context;
                      final picked = await showDatePicker(
                        context: currentContext,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFFE8889A),
                                onPrimary: Colors.white,
                                surface: Color(0xFFFFF7EC),
                                onSurface: Color(0xFF6D4C41),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ngày: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: const TextStyle(
                                fontSize: 16, color: Color(0xFF6D4C41)),
                          ),
                          const Icon(Icons.calendar_today,
                              color: Color(0xFFE8889A)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8889A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (!mounted) return;
                      final currentContext = context;
                      final title = titleController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          const SnackBar(
                              content: Text('Vui lòng nhập tên cột mốc')),
                        );
                        return;
                      }
                      final navigator = Navigator.of(currentContext);
                      final notifier =
                          ref.read(milestoneActionsProvider.notifier);
                      if (milestone == null) {
                        await notifier.addMilestone(
                          widget.coupleId,
                          title: title,
                          date: selectedDate,
                        );
                      } else {
                        await notifier.updateMilestone(
                          widget.coupleId,
                          milestone.id,
                          title: title,
                          date: selectedDate,
                        );
                      }
                      navigator.pop();
                    },
                    child: Text(
                      milestone == null ? 'Thêm cột mốc' : 'Lưu thay đổi',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteMilestone(MilestoneEntity milestone) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc muốn xóa cột mốc "${milestone.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                if (!mounted) return;
                final navigator = Navigator.of(context);
                await ref
                    .read(milestoneActionsProvider.notifier)
                    .deleteMilestone(widget.coupleId, milestone.id);
                if (!mounted) return;
                navigator.pop();
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final coupleAsync = ref.watch(watchCoupleProvider(widget.coupleId));
    final milestonesAsync =
        ref.watch(milestonesProvider(widget.coupleId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return coupleAsync.when(
      loading: () => _buildCardShimmer(),
      error: (err, stack) => _buildCardError(err.toString()),
      data: (couple) {
        if (couple == null) return const SizedBox();
        return milestonesAsync.when(
          loading: () => _buildCardShimmer(),
          error: (err, stack) => _buildCardError(err.toString()),
          data: (customMilestones) {
            final List<MilestoneEntity> milestones =
                List.from(customMilestones);
            final hasDefault = milestones.any((m) => m.isDefault);
            if (!hasDefault) {
              milestones.insert(
                0,
                MilestoneEntity(
                  id: 'default',
                  title: 'Ngày yêu nhau',
                  date: couple.pairedAt,
                  isDefault: true,
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      left: 4.0, bottom: 12.0, right: 8.0),
                  child: Row(
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Cột mốc kỷ niệm',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF6D4C41),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: () => _showAddEditMilestoneBottomSheet(),
                            icon: const Icon(Icons.add_circle_outline,
                                color: Color(0xFFE8889A), size: 28),
                            tooltip: 'Thêm cột mốc mới',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 220,
                  child: PageView.builder(
                    controller: _milestonePageController,
                    itemCount: milestones.length,
                    onPageChanged: (index) =>
                        setState(() => _currentMilestonePage = index),
                    itemBuilder: (context, index) {
                      final milestone = milestones[index];
                      final now = DateTime.now();
                      final milestoneDateOnly = DateTime(milestone.date.year,
                          milestone.date.month, milestone.date.day);
                      final nowDateOnly =
                          DateTime(now.year, now.month, now.day);
                      final diffDays =
                          milestoneDateOnly.difference(nowDateOnly).inDays;
                      final isFuture = diffDays > 0;
                      final absDays = diffDays.abs();
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD6E8), Color(0xFFE0C3FC)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE0C3FC)
                                  .withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 24),
                        child: Stack(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  milestone.title,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF5D4037)),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      isFuture ? 'Còn ' : 'Đã qua ',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF5D4037)),
                                    ),
                                    Text(
                                      '$absDays',
                                      style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFE8889A),
                                          shadows: [
                                            Shadow(
                                                color: Colors.white,
                                                offset: Offset(1.5, 1.5),
                                                blurRadius: 3)
                                          ]),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isFuture ? ' ngày' : ' ngày',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF5D4037)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (!milestone.isDefault)
                              Positioned(
                                top: 0,
                                left: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFF6D4C41)
                                          .withValues(alpha: 0.05),
                                      width: 2,
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Color(0xFF5D4037), size: 20),
                                    onPressed: () =>
                                        _showAddEditMilestoneBottomSheet(milestone),
                                    tooltip: 'Chỉnh sửa',
                                    padding: const EdgeInsets.all(10),
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                  ),
                                ),
                              ),
                            if (!milestone.isDefault)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.redAccent.withValues(alpha: 0.06),
                                      width: 2,
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_forever,
                                        color: Colors.redAccent, size: 20),
                                    onPressed: () =>
                                        _confirmDeleteMilestone(milestone),
                                    tooltip: 'Xóa',
                                    padding: const EdgeInsets.all(10),
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (milestones.length > 1) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        milestones.length,
                        (index) => Container(
                              width: 8,
                              height: 8,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentMilestonePage == index
                                    ? const Color(0xFFE8889A)
                                    : const Color(0xFFE8889A)
                                        .withValues(alpha: 0.3),
                              ),
                            )),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCardShimmer() => Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24)),
      child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFE8889A))));

  Widget _buildCardError(String err) => Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red.shade200)),
      child: Center(
          child: Text('Lỗi tải dữ liệu: $err',
              style: TextStyle(color: Colors.red.shade700))));
}
