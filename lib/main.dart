import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      home: SplashIntro(
        next: showOnboarding
            ? const MasterOnboardingScreen()
            : const HomeScreen(),
      ),
    );
  }
}

/// Простой сплэш: тот же фон и логотип, что в нативном — без скачков
class SplashIntro extends StatefulWidget {
  final Widget next;
  const SplashIntro({super.key, required this.next});

  @override
  State<SplashIntro> createState() => _SplashIntroState();
}

class _SplashIntroState extends State<SplashIntro> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => widget.next),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDEEF3),
      body: Center(
        child: SvgPicture.asset(
          'assets/logo.svg',
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}