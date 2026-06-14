import '../entities/album_entity.dart';
import '../repositories/album_repository.dart';

class CreateAlbumUseCase {
  final AlbumRepository _repository;

  const CreateAlbumUseCase(this._repository);

  Future<void> call(AlbumEntity album) {
    return _repository.createAlbum(album);
  }
}
