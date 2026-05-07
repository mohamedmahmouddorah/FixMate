import 'package:flutter/material.dart';
import 'controllers/app_controller.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_wrapper.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.load();
  await AuthService.instance.init();
  await AppController.instance.init();
  runApp(const FixMateApp());
}

class FixMateApp extends StatelessWidget {
  const FixMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'FixMate',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: !AppController.instance.isOnboardingComplete
              ? const OnboardingScreen()
              : (AuthService.instance.isLoggedIn
                  ? const MainWrapper()
                  : const LoginScreen()),
        );
      },
    );
  }
}
