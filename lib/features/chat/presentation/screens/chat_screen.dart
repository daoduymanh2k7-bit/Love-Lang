// lib/features/chat/presentation/screens/chat_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../core/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:love_lang/features/chat/domain/entities/message_entity.dart';
import 'package:love_lang/features/chat/presentation/providers/chat_provider.dart';
import 'package:love_lang/features/chat/presentation/providers/chat_state.dart';
import 'package:love_lang/features/chat/presentation/widgets/message_bubble.dart';
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tổ ấm của chúng mình ❤️',
            style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.pink.shade50,
        foregroundColor: Colors.pinkAccent,
        elevation: 0,
        actions: [
          Consumer(builder: (context, ref, _) {
            final nudgeCountAsync =
                ref.watch(nudgeCountProvider(widget.coupleId));
            return nudgeCountAsync.when(
              data: (count) => InkWell(
                onTap: _sendNudge,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('❤️ x$count',
                      style: const TextStyle(
                          color: Colors.pinkAccent,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const Icon(Icons.error),
            );
          }),
        ],
      ),
      body: Column(
        children: [
          // ─── Khung Chat ───
          Expanded(
            child: messagesStream.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.pinkAccent)),
              error: (err, stack) => Center(child: Text('Lỗi: $err')),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Hãy gửi lời chào ngọt ngào nhất nào!',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                final filtered = messages.where((m) => !m.isNudge).toList();
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Không có tin nhắn nào.',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                // Vì list đang hiển thị `reverse: true` (index 0 = mới nhất),
                // tin nhắn cuối cùng do MÌNH gửi là tin đầu tiên gặp trong
                // list mà senderId == myUid.
                final lastMyMessageIndex =
                    filtered.indexWhere((m) => m.senderId == widget.myUid);

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final message = filtered[index];
                    final isMe = message.senderId == widget.myUid;
                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                      showReadReceipt: isMe && index == lastMyMessageIndex,
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
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
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
                        color:
                            isSending ? Colors.grey.shade300 : Colors.grey),
                    onPressed: isSending ? null : _showImageSourceSheet,
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
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendText(),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Nút Send / Hold-to-record
                  GestureDetector(
                    onLongPress: isSending ? null : _startRecording,
                    onLongPressUp: isSending ? null : _stopRecording,
                    onTap: isSending ? null : _sendText,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSending
                            ? Colors.grey.shade300
                            : (_isRecording
                                ? Colors.redAccent
                                : Colors.pinkAccent),
                        shape: BoxShape.circle,
                      ),
                      child: isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _isRecording ? Icons.mic : Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
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