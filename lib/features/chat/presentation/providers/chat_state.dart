// lib/features/chat/presentation/providers/chat_state.dart

/// Trạng thái của tiến trình gửi tin nhắn (Text, Voice, Nudge)
sealed class ChatSendState {
  const ChatSendState();
}

final class ChatSendInitial extends ChatSendState {
  const ChatSendInitial();
}

final class ChatSendLoading extends ChatSendState {
  const ChatSendLoading();
}

final class ChatSendSuccess extends ChatSendState {
  const ChatSendSuccess();
}

final class ChatSendError extends ChatSendState {
  final String message;
  const ChatSendError(this.message);
}
