import '../repositories/album_repository.dart';

class DeleteAlbumUseCase {
  final AlbumRepository _repository;
  const DeleteAlbumUseCase(this._repository);

  Future<void> call(String albumId) {
    return _repository.deleteAlbum(albumId);
  }
}
