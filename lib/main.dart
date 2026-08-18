import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lets_talk/firebase_options.dart';
import 'package:lets_talk/Controllers/authContoller.dart';
import 'package:lets_talk/Controllers/connectivityController.dart';
import 'package:lets_talk/Screens/auth/splash_screen.dart'; 
// import 'package:lets_talk/Screens/auth/welcome_screen.dart'; // No longer needed here

void main() async {
  // 1. Required for async initialization
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 3. Initialize Local Storage
  await GetStorage.init(); 
  
  // 4. Initialize Connectivity Controller
  Get.put(ConnectivityController()); 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Let\'s Talk', // Updated Title
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFFBB86FC),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFBB86FC),
          secondary: Color(0xFF03DAC6),
          surface: Color(0xFF1E1E1E),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Colors.grey),
        ),
      ),
      // Bind AuthController globally
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController());
      }),
      // ⬇️ SET HOME TO SPLASH SCREEN
      home: const SplashScreen(),
    );
  }
}