import '../repositories/album_repository.dart';

class UpdateAlbumUseCase {
  final AlbumRepository _repository;
  const UpdateAlbumUseCase(this._repository);

  Future<void> call(String albumId,
      {String? title, String? description, String? coverUrl}) {
    return _repository.updateAlbum(albumId,
        title: title, description: description, coverUrl: coverUrl);
  }
}
