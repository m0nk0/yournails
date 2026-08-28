// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'clients_screen.dart';
import 'my_designs_screen.dart';
import 'manage_masters_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Твои Ноготочки'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
                actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageMastersScreen()),
            ),
            icon: const Icon(Icons.people_alt, size: 20),
            label: const Text(
              'Мастера',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Логотип
              SvgPicture.asset(
              'assets/logo.svg',
              width: 160,
              height: 160,
            ),
            const SizedBox(height: 16),
            const Text(
              'Твои Ноготочки',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Цифровая студия nail-арта',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),

            // Кнопка 1: Примерка (розовая)
            _buildBigButton(
              title: 'Примерка',
              icon: Icons.camera_alt,
              color: Colors.pink,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CameraScreen()),
              ),
            ),
            const SizedBox(height: 16),

            // Кнопка 2: Мои дизайны (фиолетовая)
            _buildBigButton(
              title: 'Мои дизайны',
              icon: Icons.bookmark,
              color: Colors.deepPurple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyDesignsScreen()),
              ),
            ),
            const SizedBox(height: 16),

            // Кнопка 3: Клиенты (бирюзовая)
            _buildBigButton(
              title: 'Клиенты',
              icon: Icons.people,
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ClientsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Большая яркая кнопка одинаковой формы и размера
  Widget _buildBigButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 90,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 40, color: Colors.white),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}