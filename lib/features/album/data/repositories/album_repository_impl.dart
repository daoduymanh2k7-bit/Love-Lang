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
  Future<String> createAlbum(AlbumEntity album) async {
    try {
      final model = AlbumModel.fromEntity(album);
      return await _remoteDataSource.createAlbum(model);
    } on FirebaseException catch (e) {
      throw ServerFailure(message: e.message ?? 'Lỗi Firebase khi tạo album');
    } catch (e) {
      throw const ServerFailure();
    }
  }

  @override
  Future<void> uploadPhotos(
    String albumId,
    String coupleId,
    String uploaderId,
    List<String> localFilePaths,
  ) async {
    try {
      await _remoteDataSource.uploadPhotos(
          albumId, coupleId, uploaderId, localFilePaths);
    } on FirebaseException catch (e) {
      throw ServerFailure(message: e.message ?? 'Lỗi Firebase khi tải ảnh lên');
    } catch (e) {
      throw const ServerFailure();
    }
  }

  // ── Mới thêm ──────────────────────────────────────────────────────────────

  @override
  Future<void> updateAlbum(
    String albumId, {
    String? title,
    String? description,
    String? coverUrl,
  }) async {
    try {
      await _remoteDataSource.updateAlbum(
        albumId,
        title: title,
        description: description,
        coverUrl: coverUrl,
      );
    } on FirebaseException catch (e) {
      throw ServerFailure(
          message: e.message ?? 'Lỗi Firebase khi cập nhật album');
    } catch (e) {
      throw const ServerFailure();
    }
  }

  @override
  Future<void> deleteAlbum(String albumId) async {
    try {
      await _remoteDataSource.deleteAlbum(albumId);
    } on FirebaseException catch (e) {
      throw ServerFailure(message: e.message ?? 'Lỗi Firebase khi xóa album');
    } catch (e) {
      throw const ServerFailure();
    }
  }

  @override
  Future<void> deletePhoto(String albumId, String photoId) async {
    try {
      await _remoteDataSource.deletePhoto(albumId, photoId);
    } on FirebaseException catch (e) {
      throw ServerFailure(message: e.message ?? 'Lỗi Firebase khi xóa ảnh');
    } catch (e) {
      throw const ServerFailure();
    }
  }

  @override
  Future<void> deletePhotos(String albumId, List<String> photoIds) async {
    try {
      await _remoteDataSource.deletePhotos(albumId, photoIds);
    } on FirebaseException catch (e) {
      throw ServerFailure(message: e.message ?? 'Lỗi Firebase khi xóa ảnh');
    } catch (e) {
      throw const ServerFailure();
    }
  }
}
