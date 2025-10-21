import 'package:flutter/material.dart';
import 'package:sankofasave/controllers/theme_controller.dart';
import 'package:sankofasave/screens/splash_screen.dart';
import 'package:sankofasave/services/theme_service.dart';
import 'package:sankofasave/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = ThemeController(ThemeService());
  await themeController.loadTheme();
  runApp(ThemeControllerProvider(
    notifier: themeController,
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeControllerProvider.of(context);
    return MaterialApp(
      title: 'SankoFa Save',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeController.themeMode,
      home: const SplashScreen(),
    );
  }
}
