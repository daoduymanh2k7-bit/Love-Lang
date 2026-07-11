import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:love_lang/core/constants/firestore_paths.dart';
import 'package:love_lang/core/theme/theme_provider.dart';
import 'package:love_lang/features/auth/presentation/providers/auth_provider.dart';
import 'package:love_lang/features/pairing/presentation/providers/pairing_provider.dart';
import 'package:love_lang/features/sound/presentation/widgets/sound_settings_section.dart';

final currentUserDocProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, uid) {
  return FirebaseFirestore.instance
      .doc(FirestorePaths.userDoc(uid))
      .snapshots()
      .map((doc) => doc.data());
});

final partnerUserProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, partnerUid) {
  return FirebaseFirestore.instance
      .doc(FirestorePaths.userDoc(partnerUid))
      .snapshots()
      .map((doc) => doc.data());
});

class ProfileScreen extends ConsumerStatefulWidget {
  final String coupleId;
  final String currentUserId;

  const ProfileScreen({
    super.key,
    required this.coupleId,
    required this.currentUserId,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Local SharedPreferences states
  bool _nudgeEnabled = true;
  bool _vibrateEnabled = true;
  bool _soundEnabled = true;
  bool _isLoadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _nudgeEnabled = prefs.getBool('pref_nudge_notifications') ?? true;
        _vibrateEnabled = prefs.getBool('pref_vibrate_on_message') ?? true;
        _soundEnabled = prefs.getBool('pref_notification_sound') ?? true;
        _isLoadingPrefs = false;
      });
    } catch (_) {
      setState(() => _isLoadingPrefs = false);
    }
  }

  Future<void> _updatePreference(String key, bool value) async {
    setState(() {
      if (key == 'pref_nudge_notifications') _nudgeEnabled = value;
      if (key == 'pref_vibrate_on_message') _vibrateEnabled = value;
      if (key == 'pref_notification_sound') _soundEnabled = value;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  String _formatJoinDate(dynamic createdAtVal) {
    DateTime? date;
    if (createdAtVal is Timestamp) {
      date = createdAtVal.toDate();
    } else if (createdAtVal is DateTime) {
      date = createdAtVal;
    } else {
      date = FirebaseAuth.instance.currentUser?.metadata.creationTime ??
          DateTime.now();
    }
    return 'Tháng ${date.month}, năm ${date.year}';
  }

  Future<void> _editDisplayName(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi tên hiển thị'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Nhập tên của bạn...',
              border: OutlineInputBorder(),
            ),
            validator: (val) => (val == null || val.trim().isEmpty)
                ? 'Tên không được để trống'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final newName = controller.text.trim();
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                navigator.pop(); // Close dialog

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  await FirebaseFirestore.instance
                      .doc(FirestorePaths.userDoc(widget.currentUserId))
                      .update({
                    'displayName': newName,
                  });
                  await FirebaseAuth.instance.currentUser
                      ?.updateDisplayName(newName);
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Lỗi cập nhật tên: $e')),
                  );
                } finally {
                  if (navigator.canPop()) {
                    navigator.pop(); // Close loading
                  }
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.isEmpty)
                    ? 'Vui lòng nhập mật khẩu hiện tại'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.length < 6)
                    ? 'Mật khẩu tối thiểu 6 ký tự'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final currentPassword = currentPasswordController.text;
                final newPassword = newPasswordController.text;
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                navigator.pop(); // Close dialog

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  final email = user?.email;
                  if (email != null) {
                    final credential = EmailAuthProvider.credential(
                        email: email, password: currentPassword);
                    await user?.reauthenticateWithCredential(credential);
                    await user?.updatePassword(newPassword);

                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                          content: Text('Đổi mật khẩu thành công! 🔑')),
                    );
                  }
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Lỗi đổi mật khẩu: $e')),
                  );
                } finally {
                  if (navigator.canPop()) {
                    navigator.pop(); // Close loading
                  }
                }
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đăng xuất')),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(authNotifierProvider.notifier).signOut();
    }
  }

  Future<void> _unpairCouple() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy ghép cặp'),
        content: const Text(
          'Bạn có chắc muốn hủy ghép cặp? Hành động này không thể hoàn tác và sẽ đưa cả hai trở lại màn hình kết nối.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận hủy',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      try {
        await ref.read(pairingRepositoryProvider).unpair();
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      } finally {
        if (navigator.canPop()) {
          navigator.pop();
        }
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài khoản',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
          'CẢNH BÁO: Hành động này sẽ xóa toàn bộ dữ liệu của bạn và không thể phục hồi. Bạn có chắc chắn muốn tiếp tục?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa vĩnh viễn',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Unpair if paired
          final couple = ref.read(watchCoupleProvider(widget.coupleId)).value;
          if (couple != null) {
            await ref.read(pairingRepositoryProvider).unpair();
          }

          // Delete firestore user doc
          await FirebaseFirestore.instance
              .doc(FirestorePaths.userDoc(widget.currentUserId))
              .delete();

          // Delete Auth user
          await user.delete();
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text(
                  'Vui lòng đăng xuất và đăng nhập lại trước khi xóa tài khoản để bảo mật.'),
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.message}')),
          );
        }
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      } finally {
        if (navigator.canPop()) {
          navigator.pop();
        }
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE8889A),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = ref.watch(themeColorProvider);
    final themeMode = ref.watch(themeModeProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? null : const Color(0xFFFBE4D8);
    final cardColor = isDark ? null : const Color(0xFFFFF7EC);
    final accentColor = themeColor.color;

    final myDocAsync = ref.watch(currentUserDocProvider(widget.currentUserId));
    final coupleAsync = ref.watch(watchCoupleProvider(widget.coupleId));

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Cá nhân',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: myDocAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (myDoc) {
          final myName = myDoc?['displayName'] as String? ?? 'Chưa đặt tên';
          final email =
              FirebaseAuth.instance.currentUser?.email ?? 'Chưa có email';
          final joinDate = _formatJoinDate(myDoc?['createdAt']);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // ─── SECTION 1: THÔNG TIN CÁ NHÂN ───
              _buildSectionHeader('THÔNG TIN CÁ NHÂN'),
              Card(
                color: cardColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          const CircleAvatar(
                            radius: 45,
                            backgroundColor: Color(0xFFE8889A),
                            child: Icon(Icons.person,
                                size: 55, color: Colors.white),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8889A),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 16, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.edit_outlined,
                            color: Color(0xFFE8889A)),
                        title: const Text('Tên hiển thị'),
                        subtitle: Text(myName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        onTap: () => _editDisplayName(myName),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.email_outlined,
                            color: Color(0xFFE8889A)),
                        title: const Text('Email'),
                        subtitle: Text(email),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.calendar_today_outlined,
                            color: Color(0xFFE8889A)),
                        title: const Text('Tham gia từ'),
                        subtitle: Text(joinDate),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── SECTION 2: THÔNG TIN CẶP ĐÔI ───
              _buildSectionHeader('THÔNG TIN CẶP ĐÔI'),
              coupleAsync.when(
                loading: () => const Card(
                    child: SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()))),
                error: (err, stack) => Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Lỗi: $err'))),
                data: (couple) {
                  if (couple == null) return const SizedBox();
                  final partnerUid = couple.uid1 == widget.currentUserId
                      ? couple.uid2
                      : couple.uid1;
                  final partnerAsync =
                      ref.watch(partnerUserProvider(partnerUid));
                  final days =
                      DateTime.now().difference(couple.pairedAt).inDays;

                  return partnerAsync.when(
                    loading: () => const Card(
                        child: SizedBox(
                            height: 100,
                            child: Center(child: CircularProgressIndicator()))),
                    error: (err, stack) => Card(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Lỗi: $err'))),
                    data: (partnerDoc) {
                      final partnerName =
                          partnerDoc?['displayName'] as String? ?? 'Người ấy';

                      return Card(
                        color: cardColor,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Color(0xFFE8889A),
                                    child: Icon(Icons.favorite,
                                        color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          partnerName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Yêu nhau được $days ngày 💕',
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side:
                                      const BorderSide(color: Colors.redAccent),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 24),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _unpairCouple,
                                icon: const Icon(Icons.link_off,
                                    color: Colors.redAccent),
                                label: const Text(
                                  'Hủy ghép cặp',
                                  style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              // ─── SECTION 3: THÔNG BÁO ───
              _buildSectionHeader('THÔNG BÁO'),
              Card(
                color: cardColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: _isLoadingPrefs
                    ? const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()))
                    : Column(
                        children: [
                          SwitchListTile(
                            activeThumbColor: accentColor,
                            title: const Text('Thông báo chọc ghẹo'),
                            subtitle:
                                const Text('Nhận cảnh báo khi đối phương chọc'),
                            value: _nudgeEnabled,
                            onChanged: (val) => _updatePreference(
                                'pref_nudge_notifications', val),
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            activeThumbColor: accentColor,
                            title: const Text('Rung khi nhận tin nhắn'),
                            value: _vibrateEnabled,
                            onChanged: (val) => _updatePreference(
                                'pref_vibrate_on_message', val),
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            activeThumbColor: accentColor,
                            title: const Text('Âm thanh thông báo'),
                            value: _soundEnabled,
                            onChanged: (val) => _updatePreference(
                                'pref_notification_sound', val),
                          ),
                        ],
                      ),
              ),

              // ─── SECTION 3.5: ÂM THANH ───
              _buildSectionHeader('ÂM THANH'),
              Card(
                color: cardColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: const SoundSettingsSection(),
              ),

              // ─── SECTION 4: GIAO DIỆN ───
              _buildSectionHeader('GIAO DIỆN'),
              Card(
                color: cardColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Màu chủ đề',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: ThemePresetColor.values.map((preset) {
                          final isSelected = themeColor == preset;
                          return GestureDetector(
                            onTap: () => ref
                                .read(themeColorProvider.notifier)
                                .selectColor(preset),
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: preset.color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 4)
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                    spreadRadius: isSelected ? 2 : 0,
                                  ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      SwitchListTile(
                        activeThumbColor: accentColor,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Chế độ tối (Dark Mode)'),
                        value: themeMode == ThemeMode.dark,
                        onChanged: (val) {
                          ref.read(themeModeProvider.notifier).selectMode(
                                val ? ThemeMode.dark : ThemeMode.light,
                              );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ─── SECTION 5: BẢO MẬT & TÀI KHOẢN ───
              _buildSectionHeader('BẢO MẬT & TÀI KHOẢN'),
              Card(
                color: cardColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_outline,
                          color: Color(0xFFE8889A)),
                      title: const Text('Đổi mật khẩu'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _changePassword,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          const Icon(Icons.logout, color: Colors.redAccent),
                      title: const Text('Đăng xuất'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _signOut,
                    ),
                  ],
                ),
              ),

              // ─── SECTION 6: KHÁC ───
              _buildSectionHeader('KHÁC'),
              Card(
                color: cardColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    const ListTile(
                      leading:
                          Icon(Icons.info_outline, color: Color(0xFFE8889A)),
                      title: Text('Phiên bản'),
                      trailing:
                          Text('1.0.0', style: TextStyle(color: Colors.grey)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description_outlined,
                          color: Color(0xFFE8889A)),
                      title: const Text('Điều khoản sử dụng'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đang phát triển')),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined,
                          color: Color(0xFFE8889A)),
                      title: const Text('Chính sách bảo mật'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đang phát triển')),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Xóa tài khoản',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                      onTap: _deleteAccount,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}