import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:love_lang/core/services/audio_service.dart';
import 'package:love_lang/features/sound/domain/entities/sound_settings_entity.dart';
import 'package:love_lang/features/sound/domain/usecases/get_sound_settings_usecase.dart';
import 'package:love_lang/features/sound/domain/usecases/update_sound_settings_usecase.dart';
import 'package:love_lang/features/sound/presentation/providers/sound_settings_provider.dart';

class MockGetSoundSettingsUseCase extends Mock
    implements GetSoundSettingsUseCase {}

class MockUpdateSoundSettingsUseCase extends Mock
    implements UpdateSoundSettingsUseCase {}

class MockAudioService extends Mock implements AudioService {}

void main() {
  late MockGetSoundSettingsUseCase mockGetUseCase;
  late MockUpdateSoundSettingsUseCase mockUpdateUseCase;
  late MockAudioService mockAudioService;

  setUpAll(() {
    registerFallbackValue(SoundSettingsEntity.defaults);
  });

  setUp(() {
    mockGetUseCase = MockGetSoundSettingsUseCase();
    mockUpdateUseCase = MockUpdateSoundSettingsUseCase();
    mockAudioService = MockAudioService();

    when(() => mockAudioService.setMusicVolume(any()))
        .thenAnswer((_) async {});
    when(() => mockAudioService.setMusicEnabled(any(), volume: any(named: 'volume')))
        .thenAnswer((_) async {});
    when(() => mockUpdateUseCase(any())).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        getSoundSettingsUseCaseProvider.overrideWithValue(mockGetUseCase),
        updateSoundSettingsUseCaseProvider
            .overrideWithValue(mockUpdateUseCase),
        audioServiceProvider.overrideWithValue(mockAudioService),
      ],
    );
  }

  test('build() trả về defaults ngay lập tức trước khi load xong', () {
    when(() => mockGetUseCase())
        .thenAnswer((_) async => SoundSettingsEntity.defaults);

    final container = makeContainer();
    addTearDown(container.dispose);

    final state = container.read(soundSettingsNotifierProvider);
    expect(state, SoundSettingsEntity.defaults);
  });

  test('load thành công cập nhật state đúng giá trị đã lưu', () async {
    const saved = SoundSettingsEntity(
      musicEnabled: false,
      sfxEnabled: true,
      musicVolume: 0.2,
      sfxVolume: 0.9,
    );
    when(() => mockGetUseCase()).thenAnswer((_) async => saved);

    final container = makeContainer();
    addTearDown(container.dispose);

    // Trigger build + chờ future bất đồng bộ trong _loadInitial hoàn tất.
    container.read(soundSettingsNotifierProvider);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(soundSettingsNotifierProvider), saved);
  });

  test('setMusicEnabled cập nhật state, gọi AudioService và lưu lại',
      () async {
    when(() => mockGetUseCase())
        .thenAnswer((_) async => SoundSettingsEntity.defaults);

    final container = makeContainer();
    addTearDown(container.dispose);
    container.read(soundSettingsNotifierProvider);
    await Future<void>.delayed(Duration.zero);

    await container
        .read(soundSettingsNotifierProvider.notifier)
        .setMusicEnabled(false);

    expect(
      container.read(soundSettingsNotifierProvider).musicEnabled,
      isFalse,
    );
    verify(() => mockAudioService.setMusicEnabled(false,
        volume: SoundSettingsEntity.defaults.musicVolume)).called(1);
    verify(() => mockUpdateUseCase(any())).called(greaterThanOrEqualTo(1));
  });

  test('setSfxVolume cập nhật state và lưu lại, không gọi AudioService',
      () async {
    when(() => mockGetUseCase())
        .thenAnswer((_) async => SoundSettingsEntity.defaults);

    final container = makeContainer();
    addTearDown(container.dispose);
    container.read(soundSettingsNotifierProvider);
    await Future<void>.delayed(Duration.zero);

    await container
        .read(soundSettingsNotifierProvider.notifier)
        .setSfxVolume(0.3);

    expect(
      container.read(soundSettingsNotifierProvider).sfxVolume,
      0.3,
    );
    verifyNever(() => mockAudioService.setMusicVolume(0.3));
  });

  test('lỗi khi load giữ nguyên default, không throw', () async {
    when(() => mockGetUseCase()).thenThrow(Exception('lỗi đọc prefs'));

    final container = makeContainer();
    addTearDown(container.dispose);

    container.read(soundSettingsNotifierProvider);
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(soundSettingsNotifierProvider),
      SoundSettingsEntity.defaults,
    );
  });
}