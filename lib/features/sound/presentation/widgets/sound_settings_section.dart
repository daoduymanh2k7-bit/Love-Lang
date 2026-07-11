import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:love_lang/features/sound/presentation/providers/sound_settings_provider.dart';

/// Section cài đặt âm thanh — nhúng vào `profile_screen.dart` trong phần
/// Settings. Gồm: toggle nhạc nền, toggle sound effect, và 2 slider âm
/// lượng riêng (chỉ bật được khi toggle tương ứng đang bật).
class SoundSettingsSection extends ConsumerWidget {
  const SoundSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(soundSettingsNotifierProvider);
    final notifier = ref.read(soundSettingsNotifierProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Không có tiêu đề riêng ở đây — widget này được nhúng vào trong
        // 1 Card đã có `_buildSectionHeader('ÂM THANH')` bên ngoài
        // (xem profile_screen.dart), tránh lặp tiêu đề 2 lần.

        // ─── Nhạc nền ───
        SwitchListTile(
          title: const Text('Nhạc nền'),
          subtitle: const Text('Phát nhạc nhẹ nhàng xuyên suốt ứng dụng'),
          value: settings.musicEnabled,
          onChanged: notifier.setMusicEnabled,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.music_note,
                  size: 20,
                  color: settings.musicEnabled
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurface.withValues(alpha: 0.3)),
              Expanded(
                child: Slider(
                  value: settings.musicVolume,
                  onChanged: settings.musicEnabled
                      ? (v) => notifier.setMusicVolume(v)
                      : null,
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 24),

        // ─── Sound Effect ───
        SwitchListTile(
          title: const Text('Hiệu ứng âm thanh'),
          subtitle: const Text('Âm thanh phản hồi khi thao tác trong app'),
          value: settings.sfxEnabled,
          onChanged: notifier.setSfxEnabled,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.graphic_eq,
                  size: 20,
                  color: settings.sfxEnabled
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurface.withValues(alpha: 0.3)),
              Expanded(
                child: Slider(
                  value: settings.sfxVolume,
                  onChanged: settings.sfxEnabled
                      ? (v) => notifier.setSfxVolume(v)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}