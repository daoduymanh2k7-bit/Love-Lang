// test/features/chat/domain/usecases/send_nudge_usecase_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:love_lang/features/chat/domain/usecases/send_nudge_usecase.dart';

import '../../chat_test_mocks.dart';

void main() {
  late MockChatRepository repository;
  late SendNudgeUseCase usecase;

  setUp(() {
    repository = MockChatRepository();
    usecase = SendNudgeUseCase(repository);
  });

  test('coupleId hợp lệ -> gọi repository.incrementNudgeCount', () async {
    when(() => repository.incrementNudgeCount(any()))
        .thenAnswer((_) async {});

    await usecase.call('couple-1');

    verify(() => repository.incrementNudgeCount('couple-1')).called(1);
  });

  test('coupleId rỗng -> ném ArgumentError, KHÔNG gọi repository', () async {
    expect(() => usecase.call(''), throwsArgumentError);
    verifyNever(() => repository.incrementNudgeCount(any()));
  });

  test('lỗi từ repository được ném lại nguyên vẹn cho caller', () async {
    when(() => repository.incrementNudgeCount(any()))
        .thenThrow(Exception('network down'));

    expect(() => usecase.call('couple-1'), throwsException);
  });
}