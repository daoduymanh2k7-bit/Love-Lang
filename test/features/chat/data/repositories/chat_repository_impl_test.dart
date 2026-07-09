// test/features/chat/data/repositories/chat_repository_impl_test.dart
//
// Test ChatRepositoryImpl bằng cách mock ChatRemoteDatasource (không đụng
// tới Firestore thật) — đúng tinh thần Clean Architecture: repository chỉ
// map dữ liệu + dịch exception -> failure, không tự thực hiện I/O.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:love_lang/core/error/exceptions.dart';
import 'package:love_lang/core/error/failures.dart';
import 'package:love_lang/features/chat/data/models/message_model.dart';
import 'package:love_lang/features/chat/data/repositories/chat_repository_impl.dart';

import '../../chat_test_mocks.dart';

void main() {
  late MockChatRemoteDatasource datasource;
  late ChatRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(fallbackMessageModel);
  });

  setUp(() {
    datasource = MockChatRemoteDatasource();
    repository = ChatRepositoryImpl(datasource);
  });

  group('watchMessages()', () {
    test('map đúng Stream<List<MessageModel>> sang Stream<List<MessageEntity>>',
        () async {
      final models = [
        MessageModel(
          id: 'm1',
          senderId: 'user-a',
          coupleId: 'couple-1',
          content: 'hi',
          type: MessageModel.fromEntity(buildMessage()).type,
          timestamp: DateTime(2024, 1, 1),
        ),
      ];
      when(() => datasource.watchMessages('couple-1'))
          .thenAnswer((_) => Stream.value(models));

      final result = repository.watchMessages('couple-1');

      await expectLater(result, emits(models));
    });
  });

  group('sendMessage()', () {
    test('thành công -> chuyển entity thành model rồi gọi datasource',
        () async {
      final message = buildMessage();
      when(() => datasource.sendMessage(any())).thenAnswer((_) async {});

      await repository.sendMessage(message);

      final captured =
          verify(() => datasource.sendMessage(captureAny())).captured.single
              as MessageModel;
      expect(captured.id, message.id);
      expect(captured.senderId, message.senderId);
      expect(captured.coupleId, message.coupleId);
      expect(captured.content, message.content);
      expect(captured.type, message.type);
    });

    test('ServerException từ datasource -> ném lại ServerFailure cùng message',
        () async {
      when(() => datasource.sendMessage(any()))
          .thenThrow(const ServerException(message: 'Mất kết nối'));

      await expectLater(
        () => repository.sendMessage(buildMessage()),
        throwsA(isA<ServerFailure>()
            .having((f) => f.message, 'message', 'Mất kết nối')),
      );
    });

    test('exception lạ (không phải ServerException) -> vẫn bọc thành ServerFailure',
        () async {
      when(() => datasource.sendMessage(any()))
          .thenThrow(StateError('unexpected'));

      await expectLater(
        () => repository.sendMessage(buildMessage()),
        throwsA(isA<ServerFailure>()),
      );
    });
  });

  group('sendVoiceMessage()', () {
    test('thành công -> gọi đúng datasource với đúng tham số', () async {
      when(() => datasource.sendVoiceMessage(any(), any(), any()))
          .thenAnswer((_) async {});

      await repository.sendVoiceMessage('couple-1', 'user-a', '/tmp/v.m4a');

      verify(() => datasource.sendVoiceMessage(
          'couple-1', 'user-a', '/tmp/v.m4a')).called(1);
    });

    test('ServerException -> ném lại ServerFailure', () async {
      when(() => datasource.sendVoiceMessage(any(), any(), any())).thenThrow(
          const ServerException(message: 'Không thể tải file ghi âm'));

      await expectLater(
        () => repository.sendVoiceMessage('couple-1', 'user-a', '/tmp/v.m4a'),
        throwsA(isA<ServerFailure>().having(
            (f) => f.message, 'message', 'Không thể tải file ghi âm')),
      );
    });
  });

  group('sendImageMessage()', () {
    test('thành công -> gọi đúng datasource với đúng tham số', () async {
      when(() => datasource.sendImageMessage(any(), any(), any()))
          .thenAnswer((_) async {});

      await repository.sendImageMessage('couple-1', 'user-a', '/tmp/i.jpg');

      verify(() => datasource.sendImageMessage(
          'couple-1', 'user-a', '/tmp/i.jpg')).called(1);
    });

    test('ServerException -> ném lại ServerFailure', () async {
      when(() => datasource.sendImageMessage(any(), any(), any()))
          .thenThrow(const ServerException(message: 'Không thể tải ảnh'));

      await expectLater(
        () => repository.sendImageMessage('couple-1', 'user-a', '/tmp/i.jpg'),
        throwsA(isA<ServerFailure>()
            .having((f) => f.message, 'message', 'Không thể tải ảnh')),
      );
    });
  });

  group('incrementNudgeCount()', () {
    test('thành công -> gọi datasource.incrementNudgeCount', () async {
      when(() => datasource.incrementNudgeCount(any()))
          .thenAnswer((_) async {});

      await repository.incrementNudgeCount('couple-1');

      verify(() => datasource.incrementNudgeCount('couple-1')).called(1);
    });

    test('ServerException -> ném lại ServerFailure', () async {
      when(() => datasource.incrementNudgeCount(any()))
          .thenThrow(const ServerException(message: 'Không thể gửi nudge'));

      await expectLater(
        () => repository.incrementNudgeCount('couple-1'),
        throwsA(isA<ServerFailure>()
            .having((f) => f.message, 'message', 'Không thể gửi nudge')),
      );
    });
  });

  group('watchNudgeCount()', () {
    test('truyền thẳng (passthrough) stream từ datasource', () async {
      when(() => datasource.watchNudgeCount('couple-1'))
          .thenAnswer((_) => Stream.fromIterable([0, 3, 5]));

      final result = repository.watchNudgeCount('couple-1');

      await expectLater(result, emitsInOrder([0, 3, 5]));
    });
  });

  group('markMessagesAsRead()', () {
    test('thành công -> gọi datasource.markMessagesAsRead', () async {
      when(() => datasource.markMessagesAsRead(any(), any()))
          .thenAnswer((_) async {});

      await repository.markMessagesAsRead('couple-1', 'user-a');

      verify(() => datasource.markMessagesAsRead('couple-1', 'user-a'))
          .called(1);
    });

    test('ServerException -> ném lại ServerFailure cùng message', () async {
      when(() => datasource.markMessagesAsRead(any(), any())).thenThrow(
          const ServerException(message: 'Không thể cập nhật trạng thái'));

      await expectLater(
        () => repository.markMessagesAsRead('couple-1', 'user-a'),
        throwsA(isA<ServerFailure>().having(
            (f) => f.message, 'message', 'Không thể cập nhật trạng thái')),
      );
    });
  });
}