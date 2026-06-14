import '../entities/photo_entity.dart';
import '../repositories/album_repository.dart';

class WatchPhotosUseCase {
  final AlbumRepository _repository;

  const WatchPhotosUseCase(this._repository);

  Stream<List<PhotoEntity>> call(String albumId) {
    return _repository.watchPhotos(albumId);
  }
}
