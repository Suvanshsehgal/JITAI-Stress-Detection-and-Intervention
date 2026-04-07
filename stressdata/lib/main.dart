import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash.dart';
import 'screens/profile_screen.dart';
import 'core/theme/colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Enable edge-to-edge UI (IMPORTANT)
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stride Probe',
      debugShowCheckedModeBanner: false,

      // 🎨 THEME (using your colors)
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,

        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),

        // AppBar theme (future use)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),

      // Routes
      routes: {
        '/profile': (context) => const ProfileScreen(),
      },

      home: const SplashScreen(),
    );
  }
}