sealed class AlbumState {
  const AlbumState();
}

class AlbumInitial extends AlbumState {
  const AlbumInitial();
}

class AlbumLoading extends AlbumState {
  const AlbumLoading();
}

class AlbumLoaded extends AlbumState {
  const AlbumLoaded();
}

class AlbumError extends AlbumState {
  final String message;
  const AlbumError(this.message);
}
