import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/master_onboarding_screen.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  runApp(const YourNailsApp());
}

class YourNailsApp extends StatelessWidget {
  const YourNailsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hasMasters = DatabaseService.getMasters().isNotEmpty;
    final isSkipped = DatabaseService.isOnboardingSkipped;

    // Онбординг показываем только если: нет мастеров И не было пропуска
    final showOnboarding = !hasMasters && !isSkipped;

    return MaterialApp(
      title: 'Твои Ноготочки',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: showOnboarding ? const MasterOnboardingScreen() : const HomeScreen(),
    );
  }
}