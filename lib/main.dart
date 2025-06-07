import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:fp_kelompok_1_ppb_c/env.dart';
import 'firebase_options.dart';
import 'package:fp_kelompok_1_ppb_c/pages/home.dart';
import 'package:fp_kelompok_1_ppb_c/pages/login.dart';
import 'package:fp_kelompok_1_ppb_c/pages/register.dart';
import 'package:fp_kelompok_1_ppb_c/pages/group_chat_screen.dart';
import 'package:fp_kelompok_1_ppb_c/services/group_service.dart'; // Import Group model

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Gemini.init(apiKey: GEMINI_API_KEY, enableDebugging: true);
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
