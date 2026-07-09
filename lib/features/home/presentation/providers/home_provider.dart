import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:love_lang/features/chat/presentation/providers/chat_provider.dart';

/// Provider trung gian (facade) cho màn hình Home.
///
/// Lý do tồn tại: HomeScreen cần gửi "nudge" (chọc đối phương), nhưng logic
/// gửi nudge thực sự thuộc về domain của feature `chat`. Thay vì để
/// HomeScreen import thẳng `chatSendNotifierProvider` (coupling chéo feature
/// ở tầng presentation), ta gói lại thao tác đó tại đây. Nhờ vậy:
/// - HomeScreen chỉ biết đến `homeNudgeControllerProvider`.
/// - Nếu sau này cách gửi nudge thay đổi (vd: qua usecase riêng của home),
///   chỉ cần sửa ở file này.
final homeNudgeControllerProvider =
    Provider<HomeNudgeController>((ref) => HomeNudgeController(ref));

class HomeNudgeController {
  final Ref _ref;
  HomeNudgeController(this._ref);

  Future<void> sendNudge({
    required String coupleId,
    required String currentUserId,
  }) {
    return _ref
        .read(chatSendNotifierProvider.notifier)
        .sendNudge(coupleId, currentUserId);
  }
}
