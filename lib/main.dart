import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация БД
  await DatabaseService.init();

  runApp(const YourNailsApp());
}

class YourNailsApp extends StatelessWidget {
  const YourNailsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YourNails',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}