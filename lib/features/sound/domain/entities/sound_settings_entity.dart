/// Trạng thái cài đặt âm thanh của người dùng: bật/tắt và âm lượng riêng
/// cho nhạc nền và sound effect. Đây là entity thuần domain, không phụ
/// thuộc vào SharedPreferences hay bất kỳ package hạ tầng nào.
class SoundSettingsEntity {
  final bool musicEnabled;
  final bool sfxEnabled;
  final double musicVolume; // 0.0 - 1.0
  final double sfxVolume; // 0.0 - 1.0

  const SoundSettingsEntity({
    required this.musicEnabled,
    required this.sfxEnabled,
    required this.musicVolume,
    required this.sfxVolume,
  });

  /// Giá trị mặc định khi người dùng mở app lần đầu (chưa có gì lưu sẵn).
  static const defaults = SoundSettingsEntity(
    musicEnabled: true,
    sfxEnabled: true,
    musicVolume: 0.5,
    sfxVolume: 0.8,
  );

  SoundSettingsEntity copyWith({
    bool? musicEnabled,
    bool? sfxEnabled,
    double? musicVolume,
    double? sfxVolume,
  }) {
    return SoundSettingsEntity(
      musicEnabled: musicEnabled ?? this.musicEnabled,
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SoundSettingsEntity &&
          runtimeType == other.runtimeType &&
          musicEnabled == other.musicEnabled &&
          sfxEnabled == other.sfxEnabled &&
          musicVolume == other.musicVolume &&
          sfxVolume == other.sfxVolume;

  @override
  int get hashCode =>
      Object.hash(musicEnabled, sfxEnabled, musicVolume, sfxVolume);
}