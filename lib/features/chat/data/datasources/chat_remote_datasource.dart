// lib/features/chat/data/datasources/chat_remote_datasource.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:love_lang/core/constants/firestore_paths.dart';
import 'package:love_lang/core/error/exceptions.dart';
import 'package:love_lang/features/chat/data/models/message_model.dart';
import 'package:love_lang/features/chat/domain/entities/message_entity.dart';

abstract interface class ChatRemoteDatasource {
  Stream<List<MessageModel>> watchMessages(String coupleId);
  Future<void> sendMessage(MessageModel message);
  Future<void> sendVoiceMessage(
      String coupleId, String senderId, String filePath);
  Future<void> sendImageMessage(
      String coupleId, String senderId, String filePath);

  /// Tăng số lần "nudge" (chọc ghẹo) giữa 2 người trong document `couples/{coupleId}`.
  Future<void> incrementNudgeCount(String coupleId);

  /// Lắng nghe realtime số lần nudge hiện tại.
  Stream<int> watchNudgeCount(String coupleId);

  /// Đánh dấu các tin nhắn CHƯA đọc, KHÔNG do [readerId] gửi, là đã đọc.
  Future<void> markMessagesAsRead(String coupleId, String readerId);
}

class ChatRemoteDatasourceImpl implements ChatRemoteDatasource {
  final FirebaseFirestore _firestore;

  ChatRemoteDatasourceImpl({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

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
      // 1. Upload file ghi âm lên Cloudinary.
      // Lưu ý: Cloudinary xử lý file audio (m4a, mp3...) dưới resourceType
      // "Video" (pipeline video/audio chung), không phải "Raw".
      final cloudinary =
          CloudinaryPublic('dq3bk50q9', 'love_lang_bucket', cache: false);
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Video,
        ),
      );

      // 2. Gửi tin nhắn chứa URL file voice
      final message = MessageModel(
        id: '', // Firestore sẽ gen ID
        senderId: senderId,
        coupleId: coupleId,
        content: response.secureUrl, // Gắn Link âm thanh vào content
        type: MessageType.voice,
        timestamp: DateTime
            .now(), // Tạm thời để lấy kiểu, sẽ dùng serverTimestamp khi set
      );

      await sendMessage(message);
    } on CloudinaryException catch (e) {
      throw ServerException(
          message: 'Không thể gửi tin nhắn thoại: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Lỗi không xác định: $e');
    }
  }

  @override
  Future<void> sendImageMessage(
      String coupleId, String senderId, String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw const ServerException(message: 'File ảnh không tồn tại.');
    }

    try {
      // 1. Upload ảnh lên Cloudinary (cùng cloud/preset với tính năng Album)
      final cloudinary =
          CloudinaryPublic('dq3bk50q9', 'love_lang_bucket', cache: false);
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      // 2. Gửi tin nhắn chứa URL ảnh (secureUrl)
      final message = MessageModel(
        id: '', // Firestore sẽ gen ID
        senderId: senderId,
        coupleId: coupleId,
        content: response.secureUrl, // Gắn Link ảnh vào content
        type: MessageType.image,
        timestamp: DateTime
            .now(), // Tạm thời để lấy kiểu, sẽ dùng serverTimestamp khi set
      );

      await sendMessage(message);
    } on CloudinaryException catch (e) {
      throw ServerException(message: 'Không thể gửi ảnh: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Lỗi không xác định: $e');
    }
  }

  @override
  Future<void> incrementNudgeCount(String coupleId) async {
    try {
      final coupleRef = _firestore.doc(FirestorePaths.coupleDoc(coupleId));
      await coupleRef.update({
        FirestorePaths.coupleNudgeCount: FieldValue.increment(1),
      });
    } on FirebaseException catch (e) {
      throw ServerException(message: 'Không thể gửi nudge: ${e.message}');
    }
  }

  @override
  Stream<int> watchNudgeCount(String coupleId) {
    return _firestore
        .doc(FirestorePaths.coupleDoc(coupleId))
        .snapshots()
        .map((snap) => (snap.data()?[FirestorePaths.coupleNudgeCount] as int?) ?? 0);
  }

  @override
  Future<void> markMessagesAsRead(String coupleId, String readerId) async {
    try {
      // Chỉ lấy các tin nhắn CHƯA đọc, sau đó lọc client-side để loại bỏ
      // tin nhắn do chính [readerId] gửi (tránh phải tạo composite index
      // cho việc kết hợp where != và where == trên Firestore).
      final snapshot = await _firestore
          .collection(FirestorePaths.messages(coupleId))
          .where('isRead', isEqualTo: false)
          .get();

      final unreadFromOther = snapshot.docs
          .where((doc) => doc.data()['senderId'] != readerId)
          .toList();

      if (unreadFromOther.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in unreadFromOther) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerException(
          message: 'Không thể cập nhật trạng thái đã đọc: ${e.message}');
    }
  }
}