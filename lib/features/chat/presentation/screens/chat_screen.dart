// lib/features/chat/presentation/screens/chat_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../core/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:love_lang/features/chat/presentation/providers/chat_provider.dart';
import 'package:love_lang/features/chat/presentation/widgets/message_bubble.dart';
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

  // Determines if app is in foreground
  bool get _isAppInForeground =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    WidgetsBinding.instance.addObserver(this);
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
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    ref
        .read(chatSendNotifierProvider.notifier)
        .sendText(widget.coupleId, widget.myUid, text);
    _msgController.clear();
  }

  // ─── Gửi Chọc Ghẹo (Nudge) ────────────────────────────────────────────────
  void _sendNudge() {
    ref
        .read(chatSendNotifierProvider.notifier)
        .sendNudge(widget.coupleId, widget.myUid);
  }

  // ─── Logic Ghi Âm (Hold to record) ───────────────────────────────────────
  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
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
    }
  }

  Future<void> _stopRecording() async {
    setState(() => _isRecording = false);
    final path = await _audioRecorder.stop();

    if (path != null) {
      // Upload file vừa ghi
      ref
          .read(chatSendNotifierProvider.notifier)
          .sendVoice(widget.coupleId, widget.myUid, path);
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

    final messagesStream = ref.watch(chatMessagesProvider(widget.coupleId));

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
                  // Nút đính kèm ảnh (Chưa làm theo spec)
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate,
                        color: Colors.grey),
                    onPressed: () {},
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
                    onLongPress: _startRecording,
                    onLongPressUp: _stopRecording,
                    onTap: _sendText,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            _isRecording ? Colors.redAccent : Colors.pinkAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
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
