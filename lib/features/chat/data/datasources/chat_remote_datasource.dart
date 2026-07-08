// lib/features/chat/data/datasources/chat_remote_datasource.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:love_lang/core/constants/firestore_paths.dart';
import 'package:love_lang/core/error/exceptions.dart';
import 'package:love_lang/features/chat/data/models/message_model.dart';
import 'package:love_lang/features/chat/domain/entities/message_entity.dart';

abstract interface class ChatRemoteDatasource {
  Stream<List<MessageModel>> watchMessages(String coupleId);
  Future<void> sendMessage(MessageModel message);
  Future<void> sendVoiceMessage(
      String coupleId, String senderId, String filePath);
}

class ChatRemoteDatasourceImpl implements ChatRemoteDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ChatRemoteDatasourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  @override
  Stream<List<MessageModel>> watchMessages(String coupleId) {
    // Truy vấn collection `chats/{coupleId}/messages`
    // Sắp xếp giảm dần theo timestamp, lấy 30 tin nhắn mới nhất
    return _firestore
        .collection(FirestorePaths.messages(coupleId))
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    try {
      final docRef = _firestore
          .collection(FirestorePaths.messages(message.coupleId))
          .doc();
      await docRef.set(message.toMapWithServerTimestamp());
    } on FirebaseException catch (e) {
      throw ServerException(message: 'Không thể gửi tin nhắn: ${e.message}');
    }
  }

  @override
  Future<void> sendVoiceMessage(
      String coupleId, String senderId, String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw const ServerException(message: 'File ghi âm không tồn tại.');
    }

    try {
      // 1. Upload file lên Firebase Storage
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final storageRef =
          _storage.ref().child('couples/$coupleId/chats/voices/$fileName');

      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // 2. Gửi tin nhắn chứa URL file voice
      final message = MessageModel(
        id: '', // Firestore sẽ gen ID
        senderId: senderId,
        coupleId: coupleId,
        content: downloadUrl, // Gắn Link âm thanh vào content
        type: MessageType.voice,
        timestamp: DateTime
            .now(), // Tạm thời để lấy kiểu, sẽ dùng serverTimestamp khi set
      );

      await sendMessage(message);
    } on FirebaseException catch (e) {
      throw ServerException(
          message: 'Không thể gửi tin nhắn thoại: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Lỗi không xác định: $e');
    }
  }
}
