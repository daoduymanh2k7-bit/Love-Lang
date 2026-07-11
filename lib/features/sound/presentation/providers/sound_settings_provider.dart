import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:love_lang/core/services/audio_service.dart';
import 'package:love_lang/features/sound/data/datasources/sound_settings_local_datasource.dart';
import 'package:love_lang/features/sound/data/repositories/sound_settings_repository_impl.dart';
import 'package:love_lang/features/sound/domain/entities/sound_settings_entity.dart';
import 'package:love_lang/features/sound/domain/repositories/sound_settings_repository.dart';
import 'package:love_lang/features/sound/domain/usecases/get_sound_settings_usecase.dart';
import 'package:love_lang/features/sound/domain/usecases/update_sound_settings_usecase.dart';

// ─── DI Providers ────────────────────────────────────────────────────────────

final soundSettingsLocalDatasourceProvider =
    Provider<SoundSettingsLocalDatasource>((ref) {
  return SoundSettingsLocalDatasourceImpl();
});

final soundSettingsRepositoryProvider = Provider<SoundSettingsRepository>((ref) {
  return SoundSettingsRepositoryImpl(ref.read(soundSettingsLocalDatasourceProvider));
});

final getSoundSettingsUseCaseProvider = Provider<GetSoundSettingsUseCase>((ref) {
  return GetSoundSettingsUseCase(ref.read(soundSettingsRepositoryProvider));
});

final updateSoundSettingsUseCaseProvider =
    Provider<UpdateSoundSettingsUseCase>((ref) {
  return UpdateSoundSettingsUseCase(ref.read(soundSettingsRepositoryProvider));
});

// ─── Notifier chính ──────────────────────────────────────────────────────────

/// Quản lý cài đặt âm thanh xuyên suốt app. KHÔNG dùng `.autoDispose` — khác
/// với các Notifier theo màn hình (chat, album...) — vì cài đặt này cần tồn
/// tại suốt vòng đời app để mọi feature khác đọc được `sfxEnabled`/`volume`
/// bất cứ lúc nào cần phát SFX.
final soundSettingsNotifierProvider =
    NotifierProvider<SoundSettingsNotifier, SoundSettingsEntity>(
        SoundSettingsNotifier.new);

class SoundSettingsNotifier extends Notifier<SoundSettingsEntity> {
  @override
  SoundSettingsEntity build() {
    // Trả về default ngay lập tức để UI có gì đó hiển thị, rồi load giá trị
    // thật đã lưu (bất đồng bộ) và cập nhật state khi có kết quả.
    _loadInitial();
    return SoundSettingsEntity.defaults;
  }

  Future<void> _loadInitial() async {
    try {
      final settings = await ref.read(getSoundSettingsUseCaseProvider)();
      state = settings;
      // Áp dụng ngay cho AudioService (ví dụ nhạc nền cần đúng volume/trạng
      // thái bật/tắt đã lưu, không phải luôn dùng default).
      await ref
          .read(audioServiceProvider)
          .setMusicVolume(settings.musicVolume);
    } catch (e) {
      debugPrint('SoundSettingsNotifier: không thể tải cài đặt âm thanh: $e');
      // Giữ nguyên default nếu lỗi — không chặn app khởi động.
    }
  }

  Future<void> _persist() async {
    try {
      await ref.read(updateSoundSettingsUseCaseProvider)(state);
    } catch (e) {
      debugPrint('SoundSettingsNotifier: không thể lưu cài đặt âm thanh: $e');
    }
  }

  Future<void> setMusicEnabled(bool value) async {
    state = state.copyWith(musicEnabled: value);
    await ref
        .read(audioServiceProvider)
        .setMusicEnabled(value, volume: state.musicVolume);
    await _persist();
  }

  Future<void> setSfxEnabled(bool value) async {
    state = state.copyWith(sfxEnabled: value);
    await _persist();
  }

  Future<void> setMusicVolume(double value) async {
    state = state.copyWith(musicVolume: value);
    await ref.read(audioServiceProvider).setMusicVolume(value);
    await _persist();
  }

  Future<void> setSfxVolume(double value) async {
    state = state.copyWith(sfxVolume: value);
    await _persist();
    // Không cần gọi AudioService ở đây — âm lượng SFX được truyền trực tiếp
    // mỗi lần gọi playSfx() (mỗi SFX là 1 player mới, không có player nào
    // "đang phát" để chỉnh volume live như nhạc nền).
  }
}