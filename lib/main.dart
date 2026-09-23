import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:lets_talk/firebase_options.dart';
import 'package:lets_talk/Controllers/ThemeController.dart';
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/Controllers/connectivityController.dart';
import 'package:lets_talk/Screens/auth/splash_screen.dart';
import 'package:lets_talk/Screens/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await GetStorage.init();

  Get.put(
    ThemeController(),
    permanent: true,
  );

  Get.put(
    ConnectivityController(),
    permanent: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController =
        Get.find<ThemeController>();

    return GetMaterialApp(
      title: "Let's Speak Student",
      debugShowCheckedModeBanner: false,

      theme: _lightTheme(),
      darkTheme: _darkTheme(),

      themeMode: themeController.themeMode,

      initialBinding: BindingsBuilder(() {
        if (!Get.isRegistered<AuthController>()) {
          Get.put(AuthController());
        }
      }),

      home: const SplashScreen(),
    );
  }

  // ============================================================
  // LIGHT THEME
  // ============================================================

  ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      scaffoldBackgroundColor: AppColors.background,

      primaryColor: AppColors.navy,

      colorScheme: const ColorScheme.light(
        primary: AppColors.navy,
        secondary: AppColors.teal,
        surface: AppColors.surface,
        error: AppColors.error,
      ),

      cardColor: AppColors.surface,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSoft,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
        ),

        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
        ),

        prefixIconColor: AppColors.navy,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.teal,
            width: 2,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.error,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.teal,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
      ),
    );
  }

  // ============================================================
  // DARK THEME
  // ============================================================

  ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: AppColors.darkBackground,

      primaryColor: AppColors.teal,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.teal,
        secondary: AppColors.yellow,
        surface: AppColors.darkSurface,
        error: AppColors.error,
      ),

      cardColor: AppColors.darkSurface,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface2,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        hintStyle: const TextStyle(
          color: AppColors.darkTextSecondary,
        ),

        labelStyle: const TextStyle(
          color: AppColors.darkTextSecondary,
        ),

        prefixIconColor: AppColors.teal,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.darkBorder,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.teal,
            width: 2,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.error,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.darkBackground,
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.teal,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
      ),
    );
  }
}