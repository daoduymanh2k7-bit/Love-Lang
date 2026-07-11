import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/album_entity.dart';
import '../../domain/entities/photo_entity.dart';
import '../../domain/usecases/watch_albums_usecase.dart';
import '../../domain/usecases/watch_photos_usecase.dart';
import '../../domain/usecases/create_album_usecase.dart';
import '../../domain/usecases/upload_photos_usecase.dart';
import '../../domain/usecases/update_album_usecase.dart';
import '../../domain/usecases/delete_album_usecase.dart';
import '../../domain/usecases/delete_photo_usecase.dart';
import '../../domain/usecases/delete_photos_usecase.dart';
import '../../data/datasources/album_remote_datasource.dart';
import '../../data/repositories/album_repository_impl.dart';
import 'album_state.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/sound_effect.dart';
import '../../../sound/presentation/providers/sound_settings_provider.dart';

// ── Dependency providers ───────────────────────────────────────────────────

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final albumRemoteDataSourceProvider = Provider<AlbumRemoteDataSource>((ref) {
  return AlbumRemoteDataSource(ref.watch(firestoreProvider));
});

final albumRepositoryProvider = Provider<AlbumRepositoryImpl>((ref) {
  return AlbumRepositoryImpl(ref.watch(albumRemoteDataSourceProvider));
});

// ── UseCase providers ──────────────────────────────────────────────────────

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

final updateAlbumUseCaseProvider = Provider<UpdateAlbumUseCase>((ref) {
  return UpdateAlbumUseCase(ref.watch(albumRepositoryProvider));
});

final deleteAlbumUseCaseProvider = Provider<DeleteAlbumUseCase>((ref) {
  return DeleteAlbumUseCase(ref.watch(albumRepositoryProvider));
});

final deletePhotoUseCaseProvider = Provider<DeletePhotoUseCase>((ref) {
  return DeletePhotoUseCase(ref.watch(albumRepositoryProvider));
});

final deletePhotosUseCaseProvider = Provider<DeletePhotosUseCase>((ref) {
  return DeletePhotosUseCase(ref.watch(albumRepositoryProvider));
});

// ── Stream providers ───────────────────────────────────────────────────────

final albumsProvider =
    StreamProvider.family<List<AlbumEntity>, String>((ref, coupleId) {
  return ref.watch(watchAlbumsUseCaseProvider)(coupleId);
});

final photosProvider =
    StreamProvider.family<List<PhotoEntity>, String>((ref, albumId) {
  return ref.watch(watchPhotosUseCaseProvider)(albumId);
});

// ── AlbumNotifier ──────────────────────────────────────────────────────────

class AlbumNotifier extends StateNotifier<AlbumState> {
  final CreateAlbumUseCase _createUseCase;
  final UploadPhotosUseCase _uploadUseCase;
  final UpdateAlbumUseCase _updateUseCase;
  final DeleteAlbumUseCase _deleteAlbumUseCase;
  final DeletePhotoUseCase _deletePhotoUseCase;
  final DeletePhotosUseCase _deletePhotosUseCase;
  final Ref _ref;

  AlbumNotifier({
    required CreateAlbumUseCase createUseCase,
    required UploadPhotosUseCase uploadUseCase,
    required UpdateAlbumUseCase updateUseCase,
    required DeleteAlbumUseCase deleteAlbumUseCase,
    required DeletePhotoUseCase deletePhotoUseCase,
    required DeletePhotosUseCase deletePhotosUseCase,
    required Ref ref,
  })  : _createUseCase = createUseCase,
        _uploadUseCase = uploadUseCase,
        _updateUseCase = updateUseCase,
        _deleteAlbumUseCase = deleteAlbumUseCase,
        _deletePhotoUseCase = deletePhotoUseCase,
        _deletePhotosUseCase = deletePhotosUseCase,
        _ref = ref,
        super(const AlbumInitial());

  void _playSfx(SoundEffect effect) {
    final settings = _ref.read(soundSettingsNotifierProvider);
    _ref.read(audioServiceProvider).playSfx(
          effect,
          volume: settings.sfxVolume,
          enabled: settings.sfxEnabled,
        );
  }

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
      _playSfx(SoundEffect.album);
    } on Failure catch (e) {
      state = AlbumError(e.message);
    } catch (e) {
      state = const AlbumError('Đã có lỗi xảy ra khi upload ảnh.');
    }
  }

  Future<void> updateAlbum(
    String albumId, {
    String? title,
    String? description,
    String? coverUrl,
  }) async {
    state = const AlbumLoading();
    try {
      await _updateUseCase(albumId,
          title: title, description: description, coverUrl: coverUrl);
      state = const AlbumLoaded();
    } on Failure catch (e) {
      state = AlbumError(e.message);
    } catch (e) {
      state = const AlbumError('Đã có lỗi xảy ra khi cập nhật album.');
    }
  }

  /// Trả về true nếu xóa thành công, false nếu có lỗi.
  Future<bool> deleteAlbum(String albumId) async {
    state = const AlbumLoading();
    try {
      await _deleteAlbumUseCase(albumId);
      state = const AlbumLoaded();
      return true;
    } on Failure catch (e) {
      state = AlbumError(e.message);
      return false;
    } catch (e) {
      state = const AlbumError('Đã có lỗi xảy ra khi xóa album.');
      return false;
    }
  }

  Future<void> deletePhoto(String albumId, String photoId) async {
    state = const AlbumLoading();
    try {
      await _deletePhotoUseCase(albumId, photoId);
      state = const AlbumLoaded();
    } on Failure catch (e) {
      state = AlbumError(e.message);
    } catch (e) {
      state = const AlbumError('Đã có lỗi xảy ra khi xóa ảnh.');
    }
  }

  Future<void> deletePhotos(String albumId, List<String> photoIds) async {
    if (photoIds.isEmpty) return;
    state = const AlbumLoading();
    try {
      await _deletePhotosUseCase(albumId, photoIds);
      state = const AlbumLoaded();
    } on Failure catch (e) {
      state = AlbumError(e.message);
    } catch (e) {
      state = const AlbumError('Đã có lỗi xảy ra khi xóa ảnh.');
    }
  }
}

final albumNotifierProvider =
    StateNotifierProvider<AlbumNotifier, AlbumState>((ref) {
  return AlbumNotifier(
    createUseCase: ref.watch(createAlbumUseCaseProvider),
    uploadUseCase: ref.watch(uploadPhotosUseCaseProvider),
    updateUseCase: ref.watch(updateAlbumUseCaseProvider),
    deleteAlbumUseCase: ref.watch(deleteAlbumUseCaseProvider),
    deletePhotoUseCase: ref.watch(deletePhotoUseCaseProvider),
    deletePhotosUseCase: ref.watch(deletePhotosUseCaseProvider),
    ref: ref,
  );
});