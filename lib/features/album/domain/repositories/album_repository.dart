import '../entities/album_entity.dart';
import '../entities/photo_entity.dart';

abstract interface class AlbumRepository {
  Stream<List<AlbumEntity>> watchAlbums(String coupleId);
  Stream<List<PhotoEntity>> watchPhotos(String albumId);
  Future<void> createAlbum(AlbumEntity album);
  Future<void> uploadPhotos(String albumId, String coupleId, String uploaderId, List<String> localFilePaths);
}
