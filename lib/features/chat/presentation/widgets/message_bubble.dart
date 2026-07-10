// lib/features/chat/presentation/widgets/message_bubble.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:love_lang/features/chat/domain/entities/message_entity.dart';

class MessageBubble extends StatefulWidget {
  final MessageEntity message;
  final bool isMe;

  /// Chữ cái đầu tên đối phương, hiện trong avatar khi không có tin nhắn
  /// nào của chính mình bị hiện avatar (chat 1-1 chỉ cần avatar đối phương).
  final String partnerInitial;

  /// true nếu đây là tin ĐẦU TIÊN trong 1 cụm tin liên tiếp cùng người gửi
  /// (cách nhau chưa tới vài phút) — quyết định bo góc "đỉnh cụm".
  final bool isFirstInGroup;

  /// true nếu đây là tin CUỐI CÙNG (gần hiện tại nhất) trong cụm — quyết
  /// định có hiện avatar + giờ gửi hay không, giống Messenger.
  final bool isLastInGroup;

  /// Chỉ true cho tin nhắn CUỐI CÙNG mà chính người dùng hiện tại đã gửi.
  /// Dùng để hiện chữ "Đã xem" giống Messenger/Zalo — không hiện lặp lại
  /// trên toàn bộ các tin nhắn cũ để tránh rối giao diện.
  final bool showReadReceipt;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.partnerInitial = '?',
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.showReadReceipt = false,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    // Hiệu ứng fade + trượt nhẹ khi 1 bong bóng tin nhắn xuất hiện lần đầu
    // (tin mới gửi/nhận) — chỉ chạy 1 lần lúc khởi tạo widget, không lặp
    // lại mỗi lần rebuild nhờ AnimationController gắn với State.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(_fade);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: _buildContent(context)),
    );
  }

  Widget _buildContent(BuildContext context) {
    final message = widget.message;
    final isMe = widget.isMe;
    final colorScheme = Theme.of(context).colorScheme;

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
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.vibration,
                      color: colorScheme.onPrimaryContainer, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    isMe
                        ? 'Bạn đã gửi một cú chọc ghẹo 👆'
                        : 'Nửa kia vừa chọc ghẹo bạn! 👆',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
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

    // Bo góc kiểu Messenger: góc "dính" với tin liền trước/sau CÙNG cụm bo
    // nhỏ lại (4), góc còn lại bo tròn đều (18) để tạo cảm giác chuỗi tin
    // nhắn dính liền nhau.
    final bubbleRadius = BorderRadius.only(
      topLeft: Radius.circular(!isMe && !widget.isFirstInGroup ? 4 : 18),
      topRight: Radius.circular(isMe && !widget.isFirstInGroup ? 4 : 18),
      bottomLeft: Radius.circular(!isMe && !widget.isLastInGroup ? 4 : 18),
      bottomRight: Radius.circular(isMe && !widget.isLastInGroup ? 4 : 18),
    );

    // Các loại tin nhắn thông thường (Text, Voice, Image)
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: widget.isFirstInGroup ? 10 : 2,
        bottom: 2,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Chat 1-1 chỉ cần biết "đối phương" là ai -> không hiện
              // avatar cho tin nhắn của chính mình, chỉ đối phương mới có,
              // và chỉ ở tin CUỐI CÙNG của mỗi cụm (giống Messenger).
              if (!isMe) ...[
                _buildAvatar(colorScheme),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: message.isSticker
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                  decoration: message.isSticker
                      ? null
                      : BoxDecoration(
                          color: isMe
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: bubbleRadius,
                        ),
                  child: _buildMessageContent(colorScheme),
                ),
              ),
            ],
          ),
          // Giờ gửi chỉ hiện dưới tin CUỐI CÙNG của mỗi cụm, không lặp lại
          // ở từng dòng để tránh rối mắt.
          if (widget.isLastInGroup)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                right: isMe ? 4 : 0,
                left: isMe ? 0 : 36,
              ),
              child: Text(
                _formatTime(message.timestamp),
                style: TextStyle(fontSize: 11, color: colorScheme.outline),
              ),
            ),
          // Chỉ hiện ở tin nhắn cuối cùng do MÌNH gửi, và chỉ khi đối
          // phương đã thực sự đọc (isRead == true).
          if (widget.showReadReceipt && isMe && message.isRead)
            Padding(
              padding: const EdgeInsets.only(right: 4, top: 2),
              child: Text(
                'Đã xem',
                style: TextStyle(fontSize: 11, color: colorScheme.outline),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme) {
    // Không phải tin cuối cùng của cụm -> chừa khoảng trống bằng avatar để
    // các bong bóng trong cùng cụm vẫn thẳng hàng với nhau.
    if (!widget.isLastInGroup) {
      return const SizedBox(width: 28);
    }
    return CircleAvatar(
      radius: 14,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        widget.partnerInitial,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildMessageContent(ColorScheme colorScheme) {
    final message = widget.message;
    final isMe = widget.isMe;

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

    if (message.isSticker) {
      // Sticker GIPHY -> hiển thị to (kiểu Messenger), không bọc bong bóng
      // màu nền, không có padding (đã xử lý ở Container cha).
      return CachedNetworkImage(
        imageUrl: message.content,
        width: 130,
        height: 130,
        fit: BoxFit.contain,
        placeholder: (context, url) => const SizedBox(
          width: 130,
          height: 130,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => const SizedBox(
          width: 80,
          height: 80,
          child: Icon(Icons.broken_image_outlined, size: 40),
        ),
      );
    }

    // Mặc định Text
    return Text(
      message.content,
      style: TextStyle(
        color: isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
        fontSize: 15,
        height: 1.3,
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
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

  // Đánh dấu player vừa phát xong (completed), phân biệt với trạng thái
  // "đang pause giữa chừng". Lý do cần cờ riêng: sau khi completed, ở nhiều
  // thiết bị/nền tảng, native player (ExoPlayer trên Android, AVPlayer trên
  // iOS) coi "completed" là trạng thái kết thúc vòng đời phát — gọi seek()
  // rồi resume() không đảm bảo khởi động lại được, vì resume() chỉ được
  // thiết kế để "tiếp tục" một player đang pause (còn giữ buffer), không phải
  // để "phát lại từ đầu" một player đã completed. Đây là lý do lần fix trước
  // (chỉ seek(0) rồi resume()) vẫn không ăn thua.
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo player (chỉ để load duration hiển thị trước, không phát)
    _audioPlayer.setSourceUrl(widget.audioUrl);

    // Lắng nghe thay đổi trạng thái
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Khi audio phát xong tự nhiên: KHÔNG cố gắng seek+resume ở đây nữa vì
    // không đáng tin cậy trên mọi nền tảng. Thay vào đó chỉ đánh dấu
    // `_isCompleted = true` — lần bấm play tiếp theo sẽ gọi `play()` (khởi
    // tạo lại từ đầu hoàn toàn) thay vì `resume()`.
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
          _isCompleted = true;
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
      return;
    }

    if (_isCompleted) {
      // Đã phát xong trước đó -> không dùng resume() (không đáng tin cậy để
      // "phát lại từ đầu" trên player đã completed). Gọi play() với
      // UrlSource để audioplayers tự setSource + seek(0) + start lại từ đầu
      // một cách chắc chắn trên mọi nền tảng (Android/iOS/web).
      _isCompleted = false;
      await _audioPlayer.play(UrlSource(widget.audioUrl));
    } else {
      // Đang pause giữa chừng (chưa phát hết) -> resume() để tiếp tục đúng
      // vị trí đang dừng, không bị tua về đầu.
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
    final colorScheme = Theme.of(context).colorScheme;
    final color =
        widget.isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant;

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
    final colorScheme = Theme.of(context).colorScheme;
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
            color: colorScheme.surfaceContainerHighest,
            child: Icon(Icons.broken_image_outlined,
                color: colorScheme.onSurfaceVariant),
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