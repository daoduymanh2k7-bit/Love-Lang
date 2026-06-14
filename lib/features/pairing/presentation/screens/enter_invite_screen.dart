// lib/features/pairing/presentation/screens/enter_invite_screen.dart
// UI layer: Màn hình nhập mã kết nối.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:love_lang/features/auth/presentation/providers/auth_provider.dart';
import 'package:love_lang/features/pairing/presentation/providers/pairing_provider.dart';
import 'package:love_lang/features/pairing/presentation/providers/pairing_state.dart';

class EnterInviteScreen extends ConsumerStatefulWidget {
  const EnterInviteScreen({super.key});

  @override
  ConsumerState<EnterInviteScreen> createState() => _EnterInviteScreenState();
}

class _EnterInviteScreenState extends ConsumerState<EnterInviteScreen> {
  final _codeController = TextEditingController();
  String? _generatedCode;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onConnectPressed() {
    FocusScope.of(context).unfocus();
    final code = _codeController.text;
    ref.read(pairingNotifierProvider.notifier).connectWithCode(code);
  }

  void _onGenerateCodePressed() {
    ref.read(pairingNotifierProvider.notifier).generateInviteCode();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PairingState>(pairingNotifierProvider, (previous, next) {
      switch (next) {
        case PairingError(:final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
          break;

        case PairingSuccess():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Kết nối thành công!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          break;

        case PairingInviteCreated(:final invite):
          setState(() {
            _generatedCode = invite.code;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✉️ Đã tạo mã kết nối thành công!'),
              backgroundColor: Colors.pinkAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          break;

        default:
          break;
      }
    });

    final pairingState = ref.watch(pairingNotifierProvider);
    final isLoading = pairingState is PairingLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết Nối Cặp Đôi'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Đăng xuất',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(
                Icons.favorite_rounded,
                size: 80,
                color: Colors.pinkAccent,
              ),
              const SizedBox(height: 24),
              const Text(
                'Bắt đầu kết nối yêu thương',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Để sử dụng Love Lang, bạn cần kết nối với nửa kia của mình thông qua mã mời.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Card 1: Nhập mã kết nối từ đối phương
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1. Nhập mã kết nối của nửa kia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.pinkAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          labelText: 'Mã kết nối',
                          hintText: 'VD: ABC123',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          counterText: '',
                          prefixIcon: const Icon(Icons.lock_person_outlined),
                        ),
                        maxLength: 6,
                        textCapitalization: TextCapitalization.characters,
                        enabled: !isLoading,
                        onSubmitted: (_) => _onConnectPressed(),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: isLoading ? null : _onConnectPressed,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading && pairingState is! PairingInviteCreated
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Kết Nối',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Card 2: Tạo mã kết nối của bản thân
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '2. Hoặc tự tạo mã của bạn',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.pinkAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tạo mã và gửi cho nửa kia để họ nhập trên thiết bị của họ.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_generatedCode != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.pink.shade100),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _generatedCode!,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                  color: Colors.pinkAccent,
                                ),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, color: Colors.pinkAccent),
                                tooltip: 'Sao chép mã',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _generatedCode!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('📋 Đã sao chép mã kết nối!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Mã có hiệu lực trong 24 giờ.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ] else
                        ElevatedButton(
                          onPressed: isLoading ? null : _onGenerateCodePressed,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.pinkAccent,
                            side: const BorderSide(color: Colors.pinkAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading && pairingState is PairingInviteCreated
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.pinkAccent,
                                  ),
                                )
                              : const Text(
                                  'Tạo Mã Mới',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
