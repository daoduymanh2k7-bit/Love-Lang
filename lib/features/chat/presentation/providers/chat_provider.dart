// lib/features/chat/presentation/providers/chat_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:love_lang/core/error/failures.dart';
import 'package:love_lang/core/services/audio_service.dart';
import 'package:love_lang/core/services/sound_effect.dart';
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
import 'package:love_lang/features/sound/presentation/providers/sound_settings_provider.dart';

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

  /// Phát sound effect theo đúng cài đặt hiện tại của người dùng (bật/tắt +
  /// âm lượng). Gọi sau khi 1 hành động gửi thành công.
  void _playSfx(SoundEffect effect) {
    final settings = ref.read(soundSettingsNotifierProvider);
    ref.read(audioServiceProvider).playSfx(
          effect,
          volume: settings.sfxVolume,
          enabled: settings.sfxEnabled,
        );
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
      _playSfx(SoundEffect.message);
    } on Failure catch (e) {
      state = ChatSendError(e.message);
    } catch (e) {
      state = ChatSendError('Lỗi gửi tin nhắn: $e');
    }
  }

  /// Gửi tin nhắn Sticker (URL ảnh từ GIPHY).
  Future<void> sendSticker(
      String coupleId, String senderId, String stickerUrl) async {
    state = const ChatSendLoading();
    try {
      final usecase = ref.read(sendMessageUseCaseProvider);
      final message = MessageEntity(
        id: '',
        senderId: senderId,
        coupleId: coupleId,
        content: stickerUrl,
        type: MessageType.sticker,
        timestamp: DateTime.now(),
      );
      await usecase(message);
      state = const ChatSendSuccess();
      _playSfx(SoundEffect.message);
    } on Failure catch (e) {
      state = ChatSendError(e.message);
    } catch (e) {
      state = ChatSendError('Lỗi gửi sticker: $e');
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
      // SFX nudge chỉ phát ở phía người gửi — phía nhận đã có hiệu ứng rung
      // máy riêng (xem `nudgeCountProvider` listener trong chat_screen.dart),
      // tránh chồng lặp cảm giác phản hồi.
      _playSfx(SoundEffect.nudge);
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
      _playSfx(SoundEffect.message);
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
      _playSfx(SoundEffect.message);
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