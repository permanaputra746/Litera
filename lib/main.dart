import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'login_screen.dart';
import 'utils/app_state.dart';
import 'services/storage_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'; // import kIsWeb
import 'package:google_fonts/google_fonts.dart';

import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyD7oB8pN9ET32IIglOevxuSgsWX1aB7jnY',
        appId: '1:204571339046:web:65cb07b0ec22eb523db9e7', // Web App ID matching the project credentials
        messagingSenderId: '204571339046',
        projectId: 'perpustakaan-flutter-fcb4a',
        authDomain: 'perpustakaan-flutter-fcb4a.firebaseapp.com',
        storageBucket: 'perpustakaan-flutter-fcb4a.firebasestorage.app',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  
  if (kIsWeb) {
    await GoogleSignIn.instance.initialize(
      clientId: '204571339046-0ovjvtv2j892u7fi6cbfsv0dppetdvka.apps.googleusercontent.com',
    );
  } else {
    await GoogleSignIn.instance.initialize(
      serverClientId: '204571339046-0ovjvtv2j892u7fi6cbfsv0dppetdvka.apps.googleusercontent.com',
    );
  }
  
  final storage = StorageService();
  final savedName = await storage.getAdminName();
  final savedLang = await storage.getLanguage();
  
  await NotificationService.init();

  AppState.updateAdminName(savedName);
  AppState.changeLanguage(savedLang);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppState.themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Litera',
          
          // --- LIGHT THEME (iOS Light) ---
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFFAF8F5), // Parchment / Warm Off-white
            primaryColor: const Color(0xFF2E4F3F), // Scholarly Forest Green
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E4F3F), 
              secondary: Color(0xFFC49A45), // Elegant Gold
              surface: Colors.white,
              error: Color(0xFFFF3B30), // Apple Red
            ),
            textTheme: GoogleFonts.loraTextTheme(ThemeData.light().textTheme),
            fontFamily: GoogleFonts.lora().fontFamily,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xAAFAF8F5),
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(color: Color(0xFF2E4F3F), fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // --- DARK THEME (iOS Dark) ---
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121B16), // Deep Forest Green-Black
            primaryColor: const Color(0xFF4C8C6E), // Scholarly Mint Green
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4C8C6E),
              secondary: Color(0xFFD4AF37), // Rich Gold
              surface: Color(0xFF1B2620), // Darker Scholar Surface
              error: Color(0xFFFF453A), // Apple Dark Red
            ),
            textTheme: GoogleFonts.loraTextTheme(ThemeData.dark().textTheme),
            fontFamily: GoogleFonts.lora().fontFamily,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xAA121B16),
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          themeMode: currentMode,
          home: const LoginScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}