// test/widgets/message_bubble_test.dart
//
// MessageBubble là widget thuần (StatelessWidget), không phụ thuộc Firebase,
// nên có thể test trực tiếp mà không cần mock Firestore/FirebaseAuth.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:love_lang/features/chat/domain/entities/message_entity.dart';
import 'package:love_lang/features/chat/presentation/widgets/message_bubble.dart';

MessageEntity _buildMessage({
  required MessageType type,
  required String content,
}) {
  return MessageEntity(
    id: 'm1',
    senderId: 'u1',
    coupleId: 'c1',
    content: content,
    type: type,
    timestamp: DateTime(2026, 1, 1),
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('MessageBubble', () {
    testWidgets('hiển thị đúng nội dung tin nhắn text', (tester) async {
      final message =
          _buildMessage(type: MessageType.text, content: 'Yêu em nhiều!');

      await tester.pumpWidget(
        _wrap(MessageBubble(message: message, isMe: true)),
      );

      expect(find.text('Yêu em nhiều!'), findsOneWidget);
    });

    testWidgets('tin nhắn nudge hiển thị đúng thông báo và icon rung',
        (tester) async {
      final message = _buildMessage(type: MessageType.nudge, content: '');

      await tester.pumpWidget(
        _wrap(MessageBubble(message: message, isMe: false)),
      );

      // isMe: false -> phải hiện thông báo "đối phương chọc mình",
      // không phải thông báo "mình chọc đối phương".
      expect(find.text('Nửa kia vừa chọc ghẹo bạn! 👆'), findsOneWidget);
      expect(find.text('Bạn đã gửi một cú chọc ghẹo 👆'), findsNothing);
      expect(find.byIcon(Icons.vibration), findsOneWidget);
    });

    testWidgets('không throw exception khi render với isMe = false',
        (tester) async {
      final message = _buildMessage(type: MessageType.text, content: 'Hi');

      await tester.pumpWidget(
        _wrap(MessageBubble(message: message, isMe: false)),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
