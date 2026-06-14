sealed class DiaryState {
  const DiaryState();
}

class DiaryInitial extends DiaryState {
  const DiaryInitial();
}

class DiaryLoading extends DiaryState {
  const DiaryLoading();
}

class DiaryLoaded extends DiaryState {
  const DiaryLoaded();
}

class DiaryError extends DiaryState {
  final String message;
  const DiaryError(this.message);
}
