// lib/features/chat/data/models/message_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:love_lang/features/chat/domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.senderId,
    required super.coupleId,
    required super.content,
    required super.type,
    required super.timestamp,
    super.isRead,
  });

  factory MessageModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) throw StateError('Message document rỗng');

    DateTime parsedTimestamp = DateTime.now();
    if (data['timestamp'] != null) {
      if (data['timestamp'] is Timestamp) {
        parsedTimestamp = (data['timestamp'] as Timestamp).toDate();
      } else if (data['timestamp'] is DateTime) {
        parsedTimestamp = data['timestamp'];
      }
    }

    MessageType parsedType = switch (data['type']) {
      'text' => MessageType.text,
      'image' => MessageType.image,
      'voice' => MessageType.voice,
      'nudge' => MessageType.nudge,
      'sticker' => MessageType.sticker,
      _ => MessageType.text,
    };

    return MessageModel(
      id: doc.id, // Dùng document ID từ Firestore
      senderId: data['senderId'] as String,
      coupleId: data['coupleId'] as String,
      content: data['content'] as String? ?? '',
      type: parsedType,
      timestamp: parsedTimestamp,
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMapWithServerTimestamp() {
    return {
      'senderId': senderId,
      'coupleId': coupleId,
      'content': content,
      'type': type.name, // Lấy tên chuỗi của enum
      'timestamp': FieldValue
          .serverTimestamp(), // CỰC KỲ QUAN TRỌNG: Đồng bộ thời gian qua server
      'isRead': isRead,
    };
  }

  factory MessageModel.fromEntity(MessageEntity entity) {
    return MessageModel(
      id: entity.id,
      senderId: entity.senderId,
      coupleId: entity.coupleId,
      content: entity.content,
      type: entity.type,
      timestamp: entity.timestamp,
      isRead: entity.isRead,
    );
  }
}