// lib/features/chat/data/repositories/chat_repository_impl.dart

import 'package:love_lang/core/error/exceptions.dart';
import 'package:love_lang/core/error/failures.dart';
import 'package:love_lang/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:love_lang/features/chat/data/models/message_model.dart';
import 'package:love_lang/features/chat/domain/entities/message_entity.dart';
import 'package:love_lang/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDatasource _remoteDatasource;

  ChatRepositoryImpl(this._remoteDatasource);

  @override
  Stream<List<MessageEntity>> watchMessages(String coupleId) {
    // Map Stream từ Data Layer sang Domain Layer Entity
    return _remoteDatasource.watchMessages(coupleId).map(
          (models) => models.cast<MessageEntity>(),
        );
  }

  @override
  Future<void> sendMessage(MessageEntity message) async {
    try {
      final model = MessageModel.fromEntity(message);
      await _remoteDatasource.sendMessage(model);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: 'Lỗi hệ thống: $e');
    }
  }

  @override
  Future<void> sendVoiceMessage(
      String coupleId, String senderId, String filePath) async {
    try {
      await _remoteDatasource.sendVoiceMessage(coupleId, senderId, filePath);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: 'Lỗi upload âm thanh: $e');
    }
  }

  @override
  Future<void> sendImageMessage(
      String coupleId, String senderId, String filePath) async {
    try {
      await _remoteDatasource.sendImageMessage(coupleId, senderId, filePath);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: 'Lỗi upload ảnh: $e');
    }
  }

  @override
  Future<void> incrementNudgeCount(String coupleId) async {
    try {
      await _remoteDatasource.incrementNudgeCount(coupleId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: 'Lỗi gửi nudge: $e');
    }
  }

  @override
  Stream<int> watchNudgeCount(String coupleId) {
    return _remoteDatasource.watchNudgeCount(coupleId);
  }

  @override
  Future<void> markMessagesAsRead(String coupleId, String readerId) async {
    try {
      await _remoteDatasource.markMessagesAsRead(coupleId, readerId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: 'Lỗi cập nhật trạng thái đã đọc: $e');
    }
  }
}