import '../entities/album_entity.dart';
import '../repositories/album_repository.dart';

class WatchAlbumsUseCase {
  final AlbumRepository _repository;

  const WatchAlbumsUseCase(this._repository);

  Stream<List<AlbumEntity>> call(String coupleId) {
    return _repository.watchAlbums(coupleId);
  }
}
