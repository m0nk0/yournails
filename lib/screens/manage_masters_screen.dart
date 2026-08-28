// lib/screens/manage_masters_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/master_icons.dart';
import '../models/master.dart';
import '../services/database_service.dart';
import 'master_onboarding_screen.dart';

/// Экран управления списком мастеров (для студии)
class ManageMastersScreen extends StatefulWidget {
  const ManageMastersScreen({super.key});

  @override
  State<ManageMastersScreen> createState() => _ManageMastersScreenState();
}

class _ManageMastersScreenState extends State<ManageMastersScreen> {
  List<Master> _masters = [];

  @override
  void initState() {
    super.initState();
    _loadMasters();
  }

  void _loadMasters() {
    setState(() {
      _masters = DatabaseService.getMasters();
    });
  }

  /// Переход к добавлению нового мастера
  Future<void> _addMaster() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MasterOnboardingScreen()),
    );
    if (result == true) _loadMasters();
  }

  /// Переход к редактированию мастера
  Future<void> _editMaster(Master master) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MasterOnboardingScreen(master: master)),
    );
    if (result == true) _loadMasters();
  }

  /// Удаление мастера с подтверждением
  Future<void> _deleteMaster(Master master) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить мастера?'),
        content: Text('Мастер "${master.name}" будет удалён без возможности восстановления.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.deleteMaster(master.id);
      _loadMasters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Мастер "${master.name}" удалён'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои мастера'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: _masters.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Пока нет мастеров',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Добавьте первого мастера',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _masters.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final master = _masters[index];
                return _buildMasterCard(master);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMaster,
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget _buildMasterCard(Master master) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _editMaster(master),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Аватарка мастера
              _buildAvatar(master),
              const SizedBox(width: 16),
              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      master.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      master.isCustomIcon ? 'Свой логотип' : 'Иконка',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Кнопки
              IconButton(
                onPressed: () => _editMaster(master),
                icon: const Icon(Icons.edit, color: Colors.pink),
                tooltip: 'Редактировать',
              ),
              IconButton(
                onPressed: () => _deleteMaster(master),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Удалить',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Master master) {
    if (master.isCustomIcon && master.iconPath != null) {
      return CircleAvatar(
        radius: 32,
        backgroundImage: FileImage(File(master.iconPath!)),
      );
    }
    return CircleAvatar(
      radius: 32,
      backgroundColor: Colors.pink.withOpacity(0.15),
      child: Icon(
        MasterIcons.getIconByName(master.iconName ?? 'auto_awesome'),
        color: Colors.pink,
        size: 32,
      ),
    );
  }
}