// lib/features/chat/domain/entities/message_entity.dart

/// Loại tin nhắn hỗ trợ trong phòng chat.
enum MessageType {
  text,
  image,
  voice,
  nudge, // Tin nhắn chọc ghẹo (rung máy)
  sticker, // Sticker lấy từ GIPHY, content là URL ảnh
}

/// Entity đại diện cho một tin nhắn thuần túy ở tầng Domain.
class MessageEntity {
  final String id;
  final String senderId;
  final String coupleId;
  final String content; // Nội dung text, hoặc URL hình ảnh/voice
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;

  const MessageEntity({
    required this.id,
    required this.senderId,
    required this.coupleId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  bool get isText => type == MessageType.text;
  bool get isImage => type == MessageType.image;
  bool get isVoice => type == MessageType.voice;
  bool get isNudge => type == MessageType.nudge;
  bool get isSticker => type == MessageType.sticker;

  MessageEntity copyWith({
    String? id,
    String? senderId,
    String? coupleId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      coupleId: coupleId ?? this.coupleId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}