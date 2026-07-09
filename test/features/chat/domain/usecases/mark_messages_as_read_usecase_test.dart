// test/features/chat/domain/usecases/mark_messages_as_read_usecase_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:love_lang/features/chat/domain/usecases/mark_messages_as_read_usecase.dart';

import '../../chat_test_mocks.dart';

void main() {
  late MockChatRepository repository;
  late MarkMessagesAsReadUseCase usecase;

  setUp(() {
    repository = MockChatRepository();
    usecase = MarkMessagesAsReadUseCase(repository);
  });

  test('coupleId và readerId hợp lệ -> gọi repository.markMessagesAsRead',
      () async {
    when(() => repository.markMessagesAsRead(any(), any()))
        .thenAnswer((_) async {});

    await usecase.call('couple-1', 'user-a');

    verify(() => repository.markMessagesAsRead('couple-1', 'user-a'))
        .called(1);
  });

  test('coupleId rỗng -> KHÔNG gọi repository, không ném lỗi (return sớm)',
      () async {
    await usecase.call('', 'user-a');

    verifyNever(() => repository.markMessagesAsRead(any(), any()));
  });

  test('readerId rỗng -> KHÔNG gọi repository, không ném lỗi (return sớm)',
      () async {
    await usecase.call('couple-1', '');

    verifyNever(() => repository.markMessagesAsRead(any(), any()));
  });

  test('lỗi từ repository được ném lại nguyên vẹn cho caller', () async {
    when(() => repository.markMessagesAsRead(any(), any()))
        .thenThrow(Exception('firestore lỗi'));

    expect(
      () => usecase.call('couple-1', 'user-a'),
      throwsException,
    );
  });
}