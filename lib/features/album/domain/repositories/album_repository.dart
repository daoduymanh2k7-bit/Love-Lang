import '../entities/album_entity.dart';
import '../entities/photo_entity.dart';

abstract interface class AlbumRepository {
  Stream<List<AlbumEntity>> watchAlbums(String coupleId);
  Stream<List<PhotoEntity>> watchPhotos(String albumId);
  Future<String> createAlbum(AlbumEntity album);
  Future<void> uploadPhotos(String albumId, String coupleId, String uploaderId, List<String> localFilePaths);
  
  // Mới thêm
  Future<void> updateAlbum(String albumId, {String? title, String? description, String? coverUrl});
  Future<void> deleteAlbum(String albumId);
  Future<void> deletePhoto(String albumId, String photoId);
  Future<void> deletePhotos(String albumId, List<String> photoIds);
}