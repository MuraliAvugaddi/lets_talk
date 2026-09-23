import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _box = GetStorage();
  final _storageKey = 'isDarkMode';

  // 🚀 Reactive RxBool variable for seamless Obx tracking
  late final RxBool isDarkMode;

  @override
  void onInit() {
    super.onInit();
    // Read saved preference from local storage, defaulting to false (Light Mode)
    isDarkMode = RxBool(_box.read(_storageKey) ?? false);
  }

  ThemeMode get themeMode => isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _box.write(_storageKey, isDarkMode.value);
    
    // Instantly switch theme across the app dynamically
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    update();
  }
}