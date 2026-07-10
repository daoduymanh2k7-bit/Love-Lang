// lib/features/chat/presentation/screens/chat_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../core/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:love_lang/features/chat/domain/entities/message_entity.dart';
import 'package:love_lang/features/chat/presentation/providers/chat_provider.dart';
import 'package:love_lang/features/chat/presentation/providers/chat_state.dart';
import 'package:love_lang/features/chat/presentation/widgets/message_bubble.dart';
import 'package:love_lang/features/chat/presentation/widgets/sticker_picker_sheet.dart';
import 'package:love_lang/features/pairing/presentation/providers/pairing_provider.dart';
import 'package:love_lang/features/profile/presentation/screens/profile_screen.dart'
    show partnerUserProvider;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:vibration/vibration.dart';
import 'package:path_provider/path_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  // Thực tế 2 giá trị này sẽ được cung cấp qua Auth/Route
  final String coupleId;
  final String myUid;

  const ChatScreen({
    super.key,
    required this.coupleId,
    required this.myUid,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Trạng thái foreground/background của app, được cập nhật chủ động qua
  // didChangeAppLifecycleState() thay vì tính lại mỗi lần build() (cách cũ
  // có thể không phản ánh đúng thời điểm app thực sự chuyển trạng thái).
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  bool get _isAppInForeground =>
      _appLifecycleState == AppLifecycleState.resumed;

  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    WidgetsBinding.instance.addObserver(this);
    // Lấy trạng thái hiện tại ngay khi khởi tạo (trước khi có callback đầu tiên)
    _appLifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;

    // `ref.listen` (trên WidgetRef) không hỗ trợ `fireImmediately`, nên lần
    // tải dữ liệu đầu tiên phải được bù thủ công ở đây, ngay sau frame đầu
    // tiên (đảm bảo context đã mounted và ref sẵn sàng).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  // ─── Đánh Dấu Tin Nhắn Đã Đọc ─────────────────────────────────────────────
  void _markMessagesAsRead() {
    if (!mounted || !_isAppInForeground) return;
    ref
        .read(markMessagesAsReadUseCaseProvider)
        .call(widget.coupleId, widget.myUid)
        .catchError((e) {
      debugPrint('Không thể đánh dấu tin nhắn đã đọc: $e');
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    setState(() => _appLifecycleState = state);
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _audioRecorder.dispose();
    super.dispose();
  }

  // ─── Gửi Tin Nhắn Văn Bản ──────────────────────────────────────────────────
  void _sendText() {
    // Chặn gửi liên tục khi đang có 1 tin nhắn khác đang gửi dở.
    if (ref.read(chatSendNotifierProvider) is ChatSendLoading) return;

    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    ref
        .read(chatSendNotifierProvider.notifier)
        .sendText(widget.coupleId, widget.myUid, text);
    _msgController.clear();
  }

  // ─── Gửi Chọc Ghẹo (Nudge) ────────────────────────────────────────────────
  void _sendNudge() {
    if (ref.read(chatSendNotifierProvider) is ChatSendLoading) {
      _showBusySnackBar();
      return;
    }
    ref
        .read(chatSendNotifierProvider.notifier)
        .sendNudge(widget.coupleId, widget.myUid);
  }

  // ─── Gửi Ảnh (Chọn từ Thư viện / Chụp ảnh) ────────────────────────────────
  Future<void> _pickAndSendImage(ImageSource source) async {
    if (ref.read(chatSendNotifierProvider) is ChatSendLoading) {
      _showBusySnackBar();
      return;
    }

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70, // nén sẵn trước khi upload, đỡ tốn dung lượng
        maxWidth: 1600,
      );
      if (picked == null) return; // Người dùng huỷ chọn ảnh

      ref
          .read(chatSendNotifierProvider.notifier)
          .sendImage(widget.coupleId, widget.myUid, picked.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chọn ảnh: $e')),
      );
    }
  }

  // ─── Gửi Sticker (chọn từ GIPHY) ───────────────────────────────────────────
  Future<void> _openStickerPicker() async {
    if (ref.read(chatSendNotifierProvider) is ChatSendLoading) {
      _showBusySnackBar();
      return;
    }

    final stickerUrl = await showStickerPickerSheet(context);
    if (stickerUrl == null) return; // Người dùng đóng sheet không chọn gì

    if (!mounted) return;
    ref
        .read(chatSendNotifierProvider.notifier)
        .sendSticker(widget.coupleId, widget.myUid, stickerUrl);
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndSendImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Chụp ảnh mới'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndSendImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Logic Ghi Âm (Hold to record) ───────────────────────────────────────
  Future<void> _startRecording() async {
    if (ref.read(chatSendNotifierProvider) is ChatSendLoading) {
      _showBusySnackBar();
      return;
    }

    final hasPermission = await _audioRecorder.hasPermission();

    if (!hasPermission) {
      if (!mounted) return;

      // Phân biệt "từ chối" (có thể xin lại) và "từ chối vĩnh viễn"
      // (phải vào Settings) để đưa ra hướng dẫn đúng cho người dùng.
      final micStatus = await Permission.microphone.status;
      if (!mounted) return;

      if (micStatus.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Bạn đã tắt quyền micro. Vào Cài đặt để bật lại nhé.'),
            action: SnackBarAction(
              label: 'Mở Cài đặt',
              onPressed: openAppSettings,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Cần quyền truy cập micro để ghi âm tin nhắn thoại.'),
          ),
        );
      }
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/voice_temp.m4a';

      // Xóa file cũ nếu có
      final file = File(filePath);
      if (file.existsSync()) file.deleteSync();

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );
      setState(() => _isRecording = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể bắt đầu ghi âm: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return; // Tránh gọi stop() khi chưa từng start()
    setState(() => _isRecording = false);

    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        // Upload file vừa ghi
        ref
            .read(chatSendNotifierProvider.notifier)
            .sendVoice(widget.coupleId, widget.myUid, path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể dừng ghi âm: $e')),
      );
    }
  }

  // ─── Xử lý Rung Thiết Bị ──────────────────────────────────────────────────
  Future<void> _handleDeviceVibration() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      // Rung máy 500ms để thông báo đối phương đang chọc ghẹo
      Vibration.vibrate(duration: 500, amplitude: 255);
    }
  }

  // ─── Thông báo khi người dùng thao tác lúc đang gửi dở tin nhắn khác ──────
  void _showBusySnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Đang gửi, vui lòng đợi một chút nhé...'),
          duration: Duration(seconds: 1),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for chat messages updates (no vibration logic needed)
    // Listen for nudge count changes to trigger device vibration
    ref.listen<AsyncValue<int>>(nudgeCountProvider(widget.coupleId),
        (previous, next) async {
      if (next.hasValue && previous?.hasValue == true) {
        final newCount = next.value!;
        final oldCount = previous!.value!;
        if (newCount > oldCount) {
          if (_isAppInForeground) {
            await _handleDeviceVibration();
          } else {
            await NotificationService.showNudge();
          }
        }
      }
    });

    // Lắng nghe trạng thái gửi tin nhắn (text/ảnh/voice/nudge) để báo lỗi
    // cho người dùng — trước đây gửi thất bại sẽ im lặng, không có thông báo.
    ref.listen<ChatSendState>(chatSendNotifierProvider, (previous, next) {
      if (next is ChatSendError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.message),
              backgroundColor: Colors.redAccent,
            ),
          );
      }
    });

    // Mỗi khi danh sách tin nhắn thay đổi (có tin nhắn mới, KHÔNG tính lần
    // tải đầu tiên — lần đó đã được xử lý riêng trong initState vì
    // `ref.listen` ở đây không hỗ trợ `fireImmediately`) VÀ người dùng đang
    // thực sự mở màn hình này (app ở foreground), đánh dấu tin nhắn đã đọc.
    ref.listen<AsyncValue<List<MessageEntity>>>(
      chatMessagesProvider(widget.coupleId),
      (previous, next) {
        if (!next.hasValue) return;
        _markMessagesAsRead();
      },
    );

    final messagesStream = ref.watch(chatMessagesProvider(widget.coupleId));

    // Trạng thái gửi hiện tại, dùng để khoá các nút gửi/đính kèm/ghi âm
    // trong lúc 1 tin nhắn khác đang được gửi đi.
    final sendState = ref.watch(chatSendNotifierProvider);
    final isSending = sendState is ChatSendLoading;

    final colorScheme = Theme.of(context).colorScheme;

    // Tên & chữ cái đầu của đối phương, dùng cho cả AppBar và avatar trong
    // các bong bóng chat. Chat 1-1 chỉ có đúng 1 đối phương nên lấy thẳng
    // từ CoupleEntity, không cần chọn ai trong danh sách.
    final coupleAsync = ref.watch(watchCoupleProvider(widget.coupleId));
    final partnerName = coupleAsync.maybeWhen(
          data: (couple) {
            if (couple == null) return null;
            final partnerUid = couple.partnerUidOf(widget.myUid);
            final partnerDocAsync = ref.watch(partnerUserProvider(partnerUid));
            return partnerDocAsync.maybeWhen(
              data: (doc) => doc?['displayName'] as String?,
              orElse: () => null,
            );
          },
          orElse: () => null,
        ) ??
        'Người ấy';
    final partnerInitial =
        partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                partnerInitial,
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Consumer(builder: (context, ref, _) {
              final nudgeCountAsync =
                  ref.watch(nudgeCountProvider(widget.coupleId));
              return nudgeCountAsync.when(
                data: (count) => InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _sendNudge,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('❤️ x$count',
                        style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const Icon(Icons.error),
              );
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Khung Chat ───
          Expanded(
            child: messagesStream.when(
              loading: () => Center(
                  child:
                      CircularProgressIndicator(color: colorScheme.primary)),
              error: (err, stack) => Center(child: Text('Lỗi: $err')),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text('Hãy gửi lời chào ngọt ngào nhất nào!',
                        style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  );
                }

                final filtered = messages.where((m) => !m.isNudge).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text('Không có tin nhắn nào.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  );
                }

                // Vì list đang hiển thị `reverse: true` (index 0 = mới nhất),
                // tin nhắn cuối cùng do MÌNH gửi là tin đầu tiên gặp trong
                // list mà senderId == myUid.
                final lastMyMessageIndex =
                    filtered.indexWhere((m) => m.senderId == widget.myUid);

                // Gom tin nhắn liên tiếp cùng người gửi (cách nhau < 3 phút)
                // thành từng cụm kiểu Messenger, đồng thời chèn dải phân
                // cách ngày ("Hôm nay", "Hôm qua"...) giữa các cụm khác ngày.
                final items = _buildChatItems(
                  filtered: filtered,
                  myUid: widget.myUid,
                  lastMyMessageIndex: lastMyMessageIndex,
                );

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item.dateLabel != null) {
                      return _DateSeparator(label: item.dateLabel!);
                    }
                    final message = item.message!;
                    return MessageBubble(
                      key: ValueKey(message.id),
                      message: message,
                      isMe: message.senderId == widget.myUid,
                      partnerInitial: partnerInitial,
                      isFirstInGroup: item.isFirstInGroup,
                      isLastInGroup: item.isLastInGroup,
                      showReadReceipt: item.showReadReceipt,
                    );
                  },
                );
              },
            ),
          ),

          // ─── Khung Nhập Liệu ───
          SafeArea(
            bottom: false,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  12, 8, 12, 8 + 72 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Nút đính kèm ảnh
                  IconButton(
                    icon: Icon(Icons.add_photo_alternate,
                        color: (isSending || _isRecording)
                            ? colorScheme.onSurface.withValues(alpha: 0.3)
                            : colorScheme.onSurfaceVariant),
                    onPressed:
                        (isSending || _isRecording) ? null : _showImageSourceSheet,
                  ),

                  // Nút chọn sticker (GIPHY) -> mở bottom sheet chọn, gửi
                  // ngay khi người dùng tap 1 sticker trong lưới.
                  IconButton(
                    icon: Icon(Icons.emoji_emotions_outlined,
                        color: (isSending || _isRecording)
                            ? colorScheme.onSurface.withValues(alpha: 0.3)
                            : colorScheme.onSurfaceVariant),
                    onPressed: (isSending || _isRecording)
                        ? null
                        : _openStickerPicker,
                  ),

                  // Nút ghi âm riêng: bấm để bắt đầu ghi, bấm lại để dừng
                  // và gửi ngay — độc lập với thao tác GIỮ trên nút gửi
                  // bên dưới (vẫn giữ nguyên cách cũ), cho người dùng thêm
                  // 1 cách ghi âm không cần giữ tay liên tục.
                  IconButton(
                    icon: Icon(
                      _isRecording ? Icons.stop_circle : Icons.mic_none,
                      color: _isRecording
                          ? colorScheme.error
                          : (isSending
                              ? colorScheme.onSurface.withValues(alpha: 0.3)
                              : colorScheme.onSurfaceVariant),
                    ),
                    onPressed: isSending
                        ? null
                        : (_isRecording ? _stopRecording : _startRecording),
                  ),

                  // Text Input
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: _isRecording
                            ? 'Đang ghi âm...'
                            : 'Nhập tin nhắn...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendText(),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Nút Send / Hold-to-record
                  _SendButton(
                    isSending: isSending,
                    isRecording: _isRecording,
                    color: colorScheme.primary,
                    recordingColor: colorScheme.error,
                    disabledColor: colorScheme.onSurface.withValues(alpha: 0.2),
                    onTap: isSending ? null : _sendText,
                    onLongPress: isSending ? null : _startRecording,
                    onLongPressUp: isSending ? null : _stopRecording,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Gom nhóm tin nhắn + dải ngày (kiểu Messenger) ─────────────────────────
//
// `filtered` được sắp xếp MỚI NHẤT trước (index 0 = mới nhất) vì ListView
// dùng `reverse: true`. "newer" (filtered[i-1]) luôn gần hiện tại hơn
// "older" (filtered[i+1]).

class _ChatListItem {
  final MessageEntity? message;
  final String? dateLabel;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool showReadReceipt;

  const _ChatListItem.message({
    required this.message,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.showReadReceipt,
  }) : dateLabel = null;

  const _ChatListItem.date(this.dateLabel)
      : message = null,
        isFirstInGroup = false,
        isLastInGroup = false,
        showReadReceipt = false;
}

List<_ChatListItem> _buildChatItems({
  required List<MessageEntity> filtered,
  required String myUid,
  required int lastMyMessageIndex,
}) {
  const groupGap = Duration(minutes: 3);

  bool sameGroup(MessageEntity? a, MessageEntity b) {
    if (a == null) return false;
    if (a.senderId != b.senderId) return false;
    return a.timestamp.difference(b.timestamp).abs() < groupGap;
  }

  final items = <_ChatListItem>[];
  for (var i = 0; i < filtered.length; i++) {
    final current = filtered[i];
    final newer = i > 0 ? filtered[i - 1] : null; // gần hiện tại hơn
    final older = i + 1 < filtered.length ? filtered[i + 1] : null; // cũ hơn

    items.add(_ChatListItem.message(
      message: current,
      isFirstInGroup: !sameGroup(older, current),
      isLastInGroup: !sameGroup(newer, current),
      showReadReceipt: current.senderId == myUid && i == lastMyMessageIndex,
    ));

    // `current` là tin CŨ NHẤT trong ngày của nó khi tin cũ hơn kế tiếp
    // (nếu có) rơi vào một ngày khác -> chèn dải ngày ngay phía trên.
    final isOldestOfDay =
        older == null || !_isSameDay(older.timestamp, current.timestamp);
    if (isOldestOfDay) {
      items.add(_ChatListItem.date(_formatDateLabel(current.timestamp)));
    }
  }
  return items;
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _formatDateLabel(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(date).inDays;
  if (diff == 0) return 'Hôm nay';
  if (diff == 1) return 'Hôm qua';

  const months = [
    'Th1', 'Th2', 'Th3', 'Th4', 'Th5', 'Th6', //
    'Th7', 'Th8', 'Th9', 'Th10', 'Th11', 'Th12', //
  ];
  final label = '${dt.day} ${months[dt.month - 1]}';
  return dt.year == now.year ? label : '$label ${dt.year}';
}

class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Nút Gửi / Giữ Để Ghi Âm — có hiệu ứng scale nhẹ khi nhấn ──────────────

class _SendButton extends StatefulWidget {
  final bool isSending;
  final bool isRecording;
  final Color color;
  final Color recordingColor;
  final Color disabledColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onLongPressUp;

  const _SendButton({
    required this.isSending,
    required this.isRecording,
    required this.color,
    required this.recordingColor,
    required this.disabledColor,
    required this.onTap,
    required this.onLongPress,
    required this.onLongPressUp,
  });

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isSending
        ? widget.disabledColor
        : (widget.isRecording ? widget.recordingColor : widget.color);

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onLongPress: widget.onLongPress,
      onLongPressUp: widget.onLongPressUp,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: widget.isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  widget.isRecording ? Icons.mic : Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
        ),
      ),
    );
  }
}