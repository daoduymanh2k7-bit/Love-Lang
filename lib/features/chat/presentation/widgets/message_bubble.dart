// lib/features/chat/presentation/widgets/message_bubble.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:love_lang/features/chat/domain/entities/message_entity.dart';

class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;

  /// Chỉ true cho tin nhắn CUỐI CÙNG mà chính người dùng hiện tại đã gửi.
  /// Dùng để hiện chữ "Đã xem" giống Messenger/Zalo — không hiện lặp lại
  /// trên toàn bộ các tin nhắn cũ để tránh rối giao diện.
  final bool showReadReceipt;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showReadReceipt = false,
  });

  @override
  Widget build(BuildContext context) {
    // Nếu là tin nhắn Nudge
    if (message.isNudge) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.pink.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.vibration,
                      color: Colors.pinkAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    isMe
                        ? 'Bạn đã gửi một cú chọc ghẹo 👆'
                        : 'Nửa kia vừa chọc ghẹo bạn! 👆',
                    style: const TextStyle(
                      color: Colors.pinkAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Các loại tin nhắn thông thường (Text, Voice, Image)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) _buildAvatar(),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.pinkAccent : Colors.grey.shade200,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: _buildMessageContent(),
                ),
              ),
              const SizedBox(width: 8),
              if (isMe) _buildAvatar(),
            ],
          ),
          // Chỉ hiện ở tin nhắn cuối cùng do MÌNH gửi, và chỉ khi đối
          // phương đã thực sự đọc (isRead == true).
          if (showReadReceipt && isMe && message.isRead)
            Padding(
              padding: const EdgeInsets.only(right: 4, top: 2),
              child: Text(
                'Đã xem',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 14,
      backgroundColor: isMe ? Colors.pink.shade100 : Colors.blue.shade100,
      child: Icon(
        isMe ? Icons.favorite : Icons.person,
        size: 16,
        color: isMe ? Colors.pinkAccent : Colors.blue,
      ),
    );
  }

  Widget _buildMessageContent() {
    if (message.isVoice) {
      // Tin nhắn Voice -> Hiển thị Audio Player con
      return _VoicePlayerWidget(
        audioUrl: message.content,
        isMe: isMe,
      );
    }

    if (message.isImage) {
      // Tin nhắn Ảnh -> Hiển thị thumbnail, tap để xem full-screen
      return _ImageMessageWidget(imageUrl: message.content);
    }

    // Mặc định Text
    return Text(
      message.content,
      style: TextStyle(
        color: isMe ? Colors.white : Colors.black87,
        fontSize: 15,
      ),
    );
  }
}

// ─── Trình phát Voice thu nhỏ ────────────────────────────────────────────────

class _VoicePlayerWidget extends StatefulWidget {
  final String audioUrl;
  final bool isMe;

  const _VoicePlayerWidget({
    required this.audioUrl,
    required this.isMe,
  });

  @override
  State<_VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState extends State<_VoicePlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Khởi tạo player
    _audioPlayer.setSourceUrl(widget.audioUrl);

    // Lắng nghe thay đổi trạng thái
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Lắng nghe thay đổi vị trí chạy
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    // Lắng nghe tổng thời lượng
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isMe ? Colors.white : Colors.black87;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _togglePlayPause,
          child: Icon(
            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            color: color,
            size: 36,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh tiến trình giả lập
            Container(
              height: 4,
              width: 100,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _duration.inMilliseconds > 0
                    ? _position.inMilliseconds / _duration.inMilliseconds
                    : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDuration(_position),
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        )
      ],
    );
  }
}

// ─── Hiển thị Tin Nhắn Ảnh ───────────────────────────────────────────────────

class _ImageMessageWidget extends StatelessWidget {
  final String imageUrl;

  const _ImageMessageWidget({required this.imageUrl});

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreen(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 180,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 180,
            height: 180,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) => Container(
            width: 180,
            height: 120,
            alignment: Alignment.center,
            color: Colors.grey.shade300,
            child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: CachedNetworkImage(imageUrl: imageUrl),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}