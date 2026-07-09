// lib/features/chat/presentation/providers/chat_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:love_lang/core/error/failures.dart';
import 'package:love_lang/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:love_lang/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:love_lang/features/chat/domain/entities/message_entity.dart';
import 'package:love_lang/features/chat/domain/repositories/chat_repository.dart';
import 'package:love_lang/features/chat/domain/usecases/mark_messages_as_read_usecase.dart';
import 'package:love_lang/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:love_lang/features/chat/domain/usecases/send_nudge_usecase.dart';
import 'package:love_lang/features/chat/domain/usecases/watch_messages_usecase.dart';
import 'package:love_lang/features/chat/domain/usecases/watch_nudge_count_usecase.dart';
import 'package:love_lang/features/chat/presentation/providers/chat_state.dart';

final chatSendNotifierProvider =
    AutoDisposeNotifierProvider<ChatSendNotifier, ChatSendState>(
        ChatSendNotifier.new);

// ─── DI Providers ────────────────────────────────────────────────────────────

final chatRemoteDatasourceProvider = Provider<ChatRemoteDatasource>((ref) {
  return ChatRemoteDatasourceImpl(
    firestore: FirebaseFirestore.instance,
  );
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ref.read(chatRemoteDatasourceProvider));
});

final watchMessagesUseCaseProvider = Provider<WatchMessagesUseCase>((ref) {
  return WatchMessagesUseCase(ref.read(chatRepositoryProvider));
});

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.read(chatRepositoryProvider));
});

final sendNudgeUseCaseProvider = Provider<SendNudgeUseCase>((ref) {
  return SendNudgeUseCase(ref.read(chatRepositoryProvider));
});

final watchNudgeCountUseCaseProvider = Provider<WatchNudgeCountUseCase>((ref) {
  return WatchNudgeCountUseCase(ref.read(chatRepositoryProvider));
});

final markMessagesAsReadUseCaseProvider =
    Provider<MarkMessagesAsReadUseCase>((ref) {
  return MarkMessagesAsReadUseCase(ref.read(chatRepositoryProvider));
});

// ─── Stream Provider (Realtime Chat) ──────────────────────────────────────────

/// Cung cấp luồng dữ liệu tin nhắn realtime. Cần truyền vào coupleId.
/// Sử dụng autoDispose theo chuẩn, family để truyền id.
final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<MessageEntity>, String>((ref, coupleId) {
  final usecase = ref.read(watchMessagesUseCaseProvider);
  return usecase(coupleId);
});

// ─── State Notifier (Gửi tin nhắn) ──────────────────────────────────────────

/// Notifier quản lý trạng thái tải/lỗi khi gửi tin nhắn hoặc upload ghi âm.
class ChatSendNotifier extends AutoDisposeNotifier<ChatSendState> {
  @override
  ChatSendState build() {
    return const ChatSendInitial();
  }

  /// Gửi tin nhắn Text thông thường
  Future<void> sendText(
      String coupleId, String senderId, String content) async {
    state = const ChatSendLoading();
    try {
      final usecase = ref.read(sendMessageUseCaseProvider);
      final message = MessageEntity(
        id: '',
        senderId: senderId,
        coupleId: coupleId,
        content: content,
        type: MessageType.text,
        timestamp: DateTime.now(), // Override bằng serverTimestamp ở Data layer
      );
      await usecase(message);
      state = const ChatSendSuccess();
    } on Failure catch (e) {
      state = ChatSendError(e.message);
    } catch (e) {
      state = ChatSendError('Lỗi gửi tin nhắn: $e');
    }
  }

  /// Gửi tin nhắn Chọc ghẹo (Nudge) – chỉ tăng bộ đếm nudge, không tạo message.
  /// `senderId` hiện chưa dùng tới (nudge không gắn với người gửi cụ thể ở
  /// tầng lưu trữ) nhưng vẫn giữ trong chữ ký để không phá vỡ lời gọi hiện có
  /// và phòng khi cần ghi nhận ai là người nudge trong tương lai.
  Future<void> sendNudge(String coupleId, String senderId) async {
    state = const ChatSendLoading();
    try {
      final usecase = ref.read(sendNudgeUseCaseProvider);
      await usecase(coupleId);
      state = const ChatSendSuccess();
    } on Failure catch (e) {
      state = ChatSendError(e.message);
    } catch (e) {
      state = ChatSendError('Lỗi gửi Nudge: $e');
    }
  }

  /// Gửi file ghi âm (Voice message)
  Future<void> sendVoice(
      String coupleId, String senderId, String filePath) async {
    state = const ChatSendLoading();
    try {
      final usecase = ref.read(sendMessageUseCaseProvider);
      await usecase.sendVoice(coupleId, senderId, filePath);
      state = const ChatSendSuccess();
    } on Failure catch (e) {
      state = ChatSendError(e.message);
    } catch (e) {
      state = ChatSendError('Lỗi gửi ghi âm: $e');
    }
  }

  /// Gửi file ảnh (Image message)
  Future<void> sendImage(
      String coupleId, String senderId, String filePath) async {
    state = const ChatSendLoading();
    try {
      final usecase = ref.read(sendMessageUseCaseProvider);
      await usecase.sendImage(coupleId, senderId, filePath);
      state = const ChatSendSuccess();
    } on Failure catch (e) {
      state = ChatSendError(e.message);
    } catch (e) {
      state = ChatSendError('Lỗi gửi ảnh: $e');
    }
  }
}

/// Số lần nudge realtime giữa 2 người trong cặp đôi.
/// Đi qua [WatchNudgeCountUseCase] -> [ChatRepository] thay vì đọc thẳng
/// Firestore, để tầng presentation không phụ thuộc trực tiếp vào cấu trúc
/// dữ liệu (field name, collection path) ở tầng data.
final nudgeCountProvider =
    StreamProvider.autoDispose.family<int, String>((ref, coupleId) {
  final usecase = ref.read(watchNudgeCountUseCaseProvider);
  return usecase(coupleId);
});