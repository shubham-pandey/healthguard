import 'package:flutter/material.dart';
import 'package:healthguard/app/screens/login.dart';
import 'package:healthguard/services/runanywhere_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize RunAnywhere SDK
  final service = RunAnywhereService();
  try {
    await service.initialize();
    print('✓ RunAnywhere SDK initialized');
  } catch (e) {
    print('✗ Failed to initialize RunAnywhere: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00A8A8)),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
