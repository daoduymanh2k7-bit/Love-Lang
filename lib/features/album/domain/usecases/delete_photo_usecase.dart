import '../repositories/album_repository.dart';

class DeletePhotoUseCase {
  final AlbumRepository _repository;
  const DeletePhotoUseCase(this._repository);

  Future<void> call(String albumId, String photoId) {
    return _repository.deletePhoto(albumId, photoId);
  }
}
