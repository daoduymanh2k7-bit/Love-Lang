import '../repositories/album_repository.dart';

class DeletePhotosUseCase {
  final AlbumRepository _repository;
  const DeletePhotosUseCase(this._repository);

  Future<void> call(String albumId, List<String> photoIds) {
    return _repository.deletePhotos(albumId, photoIds);
  }
}
