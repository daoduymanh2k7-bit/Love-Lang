// lib/features/auth/presentation/screens/profile_setup_screen.dart
//
// Hiện đúng 1 lần, ngay sau khi đăng ký thành công và TRƯỚC khi vào màn
// nhập/tạo mã mời ghép đôi (EnterInviteScreen). Mục đích: để đối phương
// nhìn thấy tên/avatar thật thay vì mặc định trống khi ghép đôi.
//
// Có thể bấm "Bỏ qua" bất kỳ lúc nào — không bắt buộc. Dù lưu hay bỏ qua,
// field `profileSetupPrompted` trên Firestore đều được set true để màn
// này không hiện lại ở các lần đăng nhập sau.

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:love_lang/core/constants/firestore_paths.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String currentUserId;

  const ProfileSetupScreen({super.key, required this.currentUserId});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _pickedAvatarFile; // Ảnh vừa chọn, chưa upload
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null) return;
    setState(() => _pickedAvatarFile = File(picked.path));
  }

  /// Đánh dấu đã hỏi xong (dù lưu hay bỏ qua) để không hỏi lại nữa.
  Future<void> _markPrompted() {
    return FirebaseFirestore.instance
        .doc(FirestorePaths.userDoc(widget.currentUserId))
        .update({FirestorePaths.userProfileSetupPrompted: true});
  }

  Future<void> _skip() async {
    setState(() => _isSaving = true);
    try {
      await _markPrompted();
    } catch (_) {
      // Bỏ qua lỗi ở đây: nếu ghi thất bại, màn hình chỉ đơn giản là hiện
      // lại ở lần đăng nhập sau — không phải lỗi nghiêm trọng cần chặn
      // người dùng lại.
    }
    // Không cần điều hướng thủ công: MainApp lắng nghe authNotifierProvider,
    // Firestore update ở trên sẽ tự trigger rebuild sang EnterInviteScreen.
  }

  Future<void> _saveAndContinue() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();

    try {
      String? avatarUrl;
      if (_pickedAvatarFile != null) {
        final cloudinary =
            CloudinaryPublic('dq3bk50q9', 'love_lang_bucket', cache: false);
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            _pickedAvatarFile!.path,
            resourceType: CloudinaryResourceType.Image,
            folder: 'avatars',
          ),
        );
        avatarUrl = response.secureUrl;
      }

      final updateData = <String, dynamic>{
        FirestorePaths.userDisplayName: name,
        FirestorePaths.userProfileSetupPrompted: true,
      };
      if (avatarUrl != null) {
        updateData[FirestorePaths.userAvatarUrl] = avatarUrl;
      }

      await FirebaseFirestore.instance
          .doc(FirestorePaths.userDoc(widget.currentUserId))
          .update(updateData);

      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
      if (avatarUrl != null) {
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(avatarUrl);
      }
      // Không cần điều hướng thủ công — xem giải thích ở _skip().
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Lỗi lưu thông tin: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Spacer(),
                Text(
                  'Chào bạn! 👋',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đặt tên và ảnh đại diện để đối phương\ndễ nhận ra bạn hơn nhé',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: _isSaving ? null : _pickAvatar,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: colorScheme.primaryContainer,
                        backgroundImage: _pickedAvatarFile != null
                            ? FileImage(_pickedAvatarFile!)
                            : null,
                        child: _pickedAvatarFile == null
                            ? Icon(Icons.person,
                                size: 65, color: colorScheme.onPrimaryContainer)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: colorScheme.surface, width: 2),
                        ),
                        child: Icon(Icons.camera_alt,
                            size: 18, color: colorScheme.onPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  enabled: !_isSaving,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Tên hiển thị của bạn',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'Vui lòng nhập tên'
                      : null,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveAndContinue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Lưu và tiếp tục'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isSaving ? null : _skip,
                  child: const Text('Để sau'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}