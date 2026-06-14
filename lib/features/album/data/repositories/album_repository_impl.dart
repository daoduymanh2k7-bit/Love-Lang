import 'package:firebase_core/firebase_core.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/album_entity.dart';
import '../../domain/entities/photo_entity.dart';
import '../../domain/repositories/album_repository.dart';
import '../datasources/album_remote_datasource.dart';
import '../models/album_model.dart';

class AlbumRepositoryImpl implements AlbumRepository {
  final AlbumRemoteDataSource _remoteDataSource;

  AlbumRepositoryImpl(this._remoteDataSource);

  @override
  Stream<List<AlbumEntity>> watchAlbums(String coupleId) {
    try {
      return _remoteDataSource.watchAlbums(coupleId);
    } catch (e) {
      throw const ServerFailure();
    }
  }

  @override
  Stream<List<PhotoEntity>> watchPhotos(String albumId) {
    try {
      return _remoteDataSource.watchPhotos(albumId);
    } catch (e) {
      throw const ServerFailure();
    }
  }

  @override
  Future<void> createAlbum(AlbumEntity album) async {
    try {
      final model = AlbumModel.fromEntity(album);
      await _remoteDataSource.createAlbum(model);
    } on FirebaseException catch (e) {
      throw ServerFailure(message: e.message ?? 'Lỗi Firebase khi tạo album');
    } catch (e) {
      throw const ServerFailure();
    }
  }

  @override
  Future<void> uploadPhotos(String albumId, String coupleId, String uploaderId, List<String> localFilePaths) async {
    try {
      await _remoteDataSource.uploadPhotos(albumId, coupleId, uploaderId, localFilePaths);
    } on FirebaseException catch (e) {
      throw ServerFailure(message: e.message ?? 'Lỗi Firebase khi tải ảnh lên');
    } catch (e) {
      throw const ServerFailure();
    }
  }
}
