import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'clients_screen.dart';
import 'my_designs_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YourNails'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Логотип
            const Icon(Icons.auto_awesome, size: 100, color: Colors.pink),
            const SizedBox(height: 16),
            const Text(
              'YourNails',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Примерка дизайна ногтей',
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