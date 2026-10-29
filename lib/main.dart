import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AiPrivacyScannerApp());
}

class AiPrivacyScannerApp extends StatelessWidget {
  const AiPrivacyScannerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'AI Privacy Scanner',
    theme: ThemeData(brightness: Brightness.dark, useMaterial3: true, colorSchemeSeed: Colors.cyan,
      scaffoldBackgroundColor: const Color(0xFF08111F)),
    home: const HomeScreen(),
  );
}
