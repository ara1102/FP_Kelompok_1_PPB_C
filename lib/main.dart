import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:fp_kelompok_1_ppb_c/env.dart';
import 'firebase_options.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:fp_kelompok_1_ppb_c/pages/home.dart';
import 'package:fp_kelompok_1_ppb_c/pages/login.dart';
import 'package:fp_kelompok_1_ppb_c/pages/register.dart';
import 'package:fp_kelompok_1_ppb_c/pages/group_chat_screen.dart';
import 'package:fp_kelompok_1_ppb_c/services/group_service.dart'; // Import Group model
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Inisialisasi Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Clear Firestore persistence sekali saja
  final prefs = await SharedPreferences.getInstance();
  final hasCleared = prefs.getBool('hasClearedFirestorePersistence') ?? false;

  if (!hasCleared) {
    try {
      await FirebaseFirestore.instance.clearPersistence();
      await prefs.setBool('hasClearedFirestorePersistence', true);
      debugPrint('🔥 Firestore persistence cleared.');
    } catch (e) {
      debugPrint('❌ Failed to clear Firestore persistence: $e');
    }
  }

  // Inisialisasi Gemini AI
  Gemini.init(apiKey: GEMINI_API_KEY, enableDebugging: true);

  FlutterNativeSplash.remove();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: 'login',
      routes: {
        'home': (context) => const HomePage(),
        'login': (context) => const LoginScreen(),
        'register': (context) => const RegisterScreen(),
        '/groupChat': (context) {
          final group = ModalRoute.of(context)!.settings.arguments as Group;
          return GroupChatScreen(group: group);
        },
      },
      navigatorKey: navigatorKey,
    );
  }
}
