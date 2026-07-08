import 'package:flutter/material.dart';
import 'package:love_lang/core/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:love_lang/core/presentation/screens/main_screen.dart';
import 'package:love_lang/firebase_options.dart';
import 'package:love_lang/features/auth/presentation/screens/auth_screen.dart';
import 'package:love_lang/features/auth/presentation/providers/auth_provider.dart';
import 'package:love_lang/features/auth/presentation/providers/auth_state.dart';
import 'package:love_lang/features/pairing/presentation/screens/enter_invite_screen.dart';
import 'package:love_lang/core/theme/theme_provider.dart';

void main() async {
  // Đảm bảo các plugin Flutter đã được khởi tạo
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase với cấu hình tự động nhận diện nền tảng
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService.init();
    await NotificationService.requestPermission();
  } catch (e) {
    debugPrint('Lỗi khởi tạo Firebase: $e');
  }

  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final themeColor = ref.watch(themeColorProvider);
    final themeMode = ref.watch(themeModeProvider);

    Widget getHomeScreen() {
      if (authState is AuthInitial || authState is AuthLoading) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: Colors.pinkAccent,
            ),
          ),
        );
      }

      if (authState is Authenticated) {
        if (authState.pairingStatus == 'paired' && authState.coupleId != null) {
          return MainScreen(
            coupleId: authState.coupleId!,
            currentUserId: authState.user.uid,
          );
        } else {
          return const EnterInviteScreen();
        }
      }

      // Mặc định hoặc khi Unauthenticated/AuthError -> chuyển sang AuthScreen
      return const AuthScreen();
    }

    return MaterialApp(
      title: 'Love Lang',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeColor.color,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeColor.color,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: getHomeScreen(),
    );
  }
}
