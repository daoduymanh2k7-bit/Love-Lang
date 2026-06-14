import '../repositories/album_repository.dart';

class UploadPhotosUseCase {
  final AlbumRepository _repository;

  const UploadPhotosUseCase(this._repository);

  Future<void> call(String albumId, String coupleId, String uploaderId, List<String> localFilePaths) {
    return _repository.uploadPhotos(albumId, coupleId, uploaderId, localFilePaths);
  }
}
