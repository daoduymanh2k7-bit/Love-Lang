// test/features/chat/domain/usecases/watch_messages_usecase_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:love_lang/features/chat/domain/entities/message_entity.dart';
import 'package:love_lang/features/chat/domain/usecases/watch_messages_usecase.dart';

import '../../chat_test_mocks.dart';

void main() {
  late MockChatRepository repository;
  late WatchMessagesUseCase usecase;

  setUp(() {
    repository = MockChatRepository();
    usecase = WatchMessagesUseCase(repository);
  });

  test('coupleId hợp lệ -> trả về đúng stream từ repository', () async {
    final messages = [buildMessage(id: 'm1'), buildMessage(id: 'm2')];
    when(() => repository.watchMessages('couple-1'))
        .thenAnswer((_) => Stream.value(messages));

    final result = usecase.call('couple-1');

    await expectLater(result, emits(messages));
    verify(() => repository.watchMessages('couple-1')).called(1);
  });

  test('coupleId rỗng -> ném ArgumentError ngay lập tức (không tạo stream)',
      () {
    expect(() => usecase.call(''), throwsArgumentError);
    verifyNever(() => repository.watchMessages(any()));
  });

  test('lỗi trong stream của repository được truyền nguyên vẹn xuống dưới',
      () async {
    when(() => repository.watchMessages('couple-1'))
        .thenAnswer((_) => Stream.error(Exception('firestore lỗi')));

    final result = usecase.call('couple-1');

    await expectLater(result, emitsError(isException));
  });
}