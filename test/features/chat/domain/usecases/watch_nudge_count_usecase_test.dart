// test/features/chat/domain/usecases/watch_nudge_count_usecase_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:love_lang/features/chat/domain/usecases/watch_nudge_count_usecase.dart';

import '../../chat_test_mocks.dart';

void main() {
  late MockChatRepository repository;
  late WatchNudgeCountUseCase usecase;

  setUp(() {
    repository = MockChatRepository();
    usecase = WatchNudgeCountUseCase(repository);
  });

  test('coupleId hợp lệ -> trả về đúng stream đếm nudge từ repository',
      () async {
    when(() => repository.watchNudgeCount('couple-1'))
        .thenAnswer((_) => Stream.fromIterable([0, 1, 2]));

    final result = usecase.call('couple-1');

    await expectLater(result, emitsInOrder([0, 1, 2]));
    verify(() => repository.watchNudgeCount('couple-1')).called(1);
  });

  test('coupleId rỗng -> ném ArgumentError ngay lập tức', () {
    expect(() => usecase.call(''), throwsArgumentError);
    verifyNever(() => repository.watchNudgeCount(any()));
  });
}