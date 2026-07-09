// test/features/chat/domain/usecases/send_message_usecase_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:love_lang/features/chat/domain/entities/message_entity.dart';
import 'package:love_lang/features/chat/domain/usecases/send_message_usecase.dart';

import '../../chat_test_mocks.dart';

void main() {
  late MockChatRepository repository;
  late SendMessageUseCase usecase;

  setUpAll(() {
    // Đăng ký 1 lần cho toàn bộ file: cần thiết vì `any()` được dùng cho
    // tham số kiểu MessageEntity trong `call()`.
    registerFallbackValue(fallbackMessageEntity);
  });

  setUp(() {
    repository = MockChatRepository();
    usecase = SendMessageUseCase(repository);
  });

  group('call()', () {
    test('gửi tin nhắn text hợp lệ -> gọi repository.sendMessage', () async {
      final message = buildMessage(content: 'Chào em');
      when(() => repository.sendMessage(any())).thenAnswer((_) async {});

      await usecase.call(message);

      verify(() => repository.sendMessage(message)).called(1);
    });

    test('content rỗng + type != nudge -> ném ArgumentError, KHÔNG gọi repo',
        () async {
      final message = buildMessage(content: '', type: MessageType.text);

      expect(() => usecase.call(message), throwsArgumentError);
      verifyNever(() => repository.sendMessage(any()));
    });

    test('content rỗng + type == nudge -> vẫn hợp lệ, gọi repository',
        () async {
      final message = buildMessage(content: '', type: MessageType.nudge);
      when(() => repository.sendMessage(any())).thenAnswer((_) async {});

      await usecase.call(message);

      verify(() => repository.sendMessage(message)).called(1);
    });
  });

  group('sendVoice()', () {
    test('filePath hợp lệ -> gọi repository.sendVoiceMessage', () async {
      when(() => repository.sendVoiceMessage(any(), any(), any()))
          .thenAnswer((_) async {});

      await usecase.sendVoice('couple-1', 'user-a', '/tmp/voice.m4a');

      verify(() => repository.sendVoiceMessage(
          'couple-1', 'user-a', '/tmp/voice.m4a')).called(1);
    });

    test('filePath rỗng -> ném ArgumentError, KHÔNG gọi repo', () async {
      expect(
        () => usecase.sendVoice('couple-1', 'user-a', ''),
        throwsArgumentError,
      );
      verifyNever(() => repository.sendVoiceMessage(any(), any(), any()));
    });
  });

  group('sendImage()', () {
    test('filePath hợp lệ -> gọi repository.sendImageMessage', () async {
      when(() => repository.sendImageMessage(any(), any(), any()))
          .thenAnswer((_) async {});

      await usecase.sendImage('couple-1', 'user-a', '/tmp/photo.jpg');

      verify(() => repository.sendImageMessage(
          'couple-1', 'user-a', '/tmp/photo.jpg')).called(1);
    });

    test('filePath rỗng -> ném ArgumentError, KHÔNG gọi repo', () async {
      expect(
        () => usecase.sendImage('couple-1', 'user-a', ''),
        throwsArgumentError,
      );
      verifyNever(() => repository.sendImageMessage(any(), any(), any()));
    });
  });
}