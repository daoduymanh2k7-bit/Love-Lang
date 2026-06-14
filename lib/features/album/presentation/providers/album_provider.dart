import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/album_entity.dart';
import '../../domain/entities/photo_entity.dart';
import '../../domain/usecases/watch_albums_usecase.dart';
import '../../domain/usecases/watch_photos_usecase.dart';
import '../../domain/usecases/create_album_usecase.dart';
import '../../domain/usecases/upload_photos_usecase.dart';
import '../../data/datasources/album_remote_datasource.dart';
import '../../data/repositories/album_repository_impl.dart';
import 'album_state.dart';
import '../../../../core/error/failures.dart';

// Providers for dependencies
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);


final albumRemoteDataSourceProvider = Provider<AlbumRemoteDataSource>((ref) {
  return AlbumRemoteDataSource(ref.watch(firestoreProvider));
});

final albumRepositoryProvider = Provider<AlbumRepositoryImpl>((ref) {
  return AlbumRepositoryImpl(ref.watch(albumRemoteDataSourceProvider));
});

final watchAlbumsUseCaseProvider = Provider<WatchAlbumsUseCase>((ref) {
  return WatchAlbumsUseCase(ref.watch(albumRepositoryProvider));
});

final watchPhotosUseCaseProvider = Provider<WatchPhotosUseCase>((ref) {
  return WatchPhotosUseCase(ref.watch(albumRepositoryProvider));
});

final createAlbumUseCaseProvider = Provider<CreateAlbumUseCase>((ref) {
  return CreateAlbumUseCase(ref.watch(albumRepositoryProvider));
});

final uploadPhotosUseCaseProvider = Provider<UploadPhotosUseCase>((ref) {
  return UploadPhotosUseCase(ref.watch(albumRepositoryProvider));
});

// Stream providers for Realtime listening
final albumsProvider = StreamProvider.family<List<AlbumEntity>, String>((ref, coupleId) {
  final watchUseCase = ref.watch(watchAlbumsUseCaseProvider);
  return watchUseCase(coupleId);
});

final photosProvider = StreamProvider.family<List<PhotoEntity>, String>((ref, albumId) {
  final watchUseCase = ref.watch(watchPhotosUseCaseProvider);
  return watchUseCase(albumId);
});

// StateNotifier for mutating states (create album, upload photos)
class AlbumNotifier extends StateNotifier<AlbumState> {
  final CreateAlbumUseCase _createUseCase;
  final UploadPhotosUseCase _uploadUseCase;

  AlbumNotifier({
    required CreateAlbumUseCase createUseCase,
    required UploadPhotosUseCase uploadUseCase,
  })  : _createUseCase = createUseCase,
        _uploadUseCase = uploadUseCase,
        super(const AlbumInitial());

  Future<String?> createAlbum(AlbumEntity album) async {
    state = const AlbumLoading();
    try {
      final albumId = await _createUseCase(album);
      state = const AlbumLoaded();
      return albumId;
    } on Failure catch (e) {
      state = AlbumError(e.message);
      return null;
    } catch (e) {
      state = const AlbumError('Đã có lỗi xảy ra khi tạo Album.');
      return null;
    }
  }

  Future<void> uploadPhotos({
    required String albumId,
    required String coupleId,
    required String uploaderId,
    required List<String> localFilePaths,
  }) async {
    if (localFilePaths.isEmpty) return;
    state = const AlbumLoading();
    try {
      await _uploadUseCase(albumId, coupleId, uploaderId, localFilePaths);
      state = const AlbumLoaded();
    } on Failure catch (e) {
      state = AlbumError(e.message);
    } catch (e) {
      state = const AlbumError('Đã có lỗi xảy ra khi upload ảnh.');
    }
  }
}

final albumNotifierProvider = StateNotifierProvider<AlbumNotifier, AlbumState>((ref) {
  return AlbumNotifier(
    createUseCase: ref.watch(createAlbumUseCaseProvider),
    uploadUseCase: ref.watch(uploadPhotosUseCaseProvider),
  );
});
