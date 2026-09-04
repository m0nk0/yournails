import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/master_icons.dart';
import '../models/master.dart';
import '../services/database_service.dart';
import '../utils/top_message.dart';
import 'home_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Экран первого запуска / редактирования мастера
class MasterOnboardingScreen extends StatefulWidget {
  final Master? master; // null — создание, иначе — редактирование
  const MasterOnboardingScreen({super.key, this.master});

  @override
  State<MasterOnboardingScreen> createState() => _MasterOnboardingScreenState();
}

class _MasterOnboardingScreenState extends State<MasterOnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedIconName = 'auto_awesome';
  String? _customLogoPath;
  bool _isSaving = false;

  bool get isEditing => widget.master != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.master!.name;
      _customLogoPath = widget.master!.isCustomIcon ? widget.master!.iconPath : null;
      _selectedIconName = widget.master!.isCustomIcon
          ? null
          : (widget.master!.iconName ?? 'auto_awesome');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Пропустить настройку (режим клиента)
  Future<void> _skip() async {
    await DatabaseService.setOnboardingSkipped(true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  /// Сохранить мастера (создание или обновление)
  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      TopMessage.show(context, 'Введите ваше имя');
      return;
    }

    setState(() => _isSaving = true);

    if (isEditing) {
      final updated = Master(
        id: widget.master!.id,
        name: name,
        iconPath: _customLogoPath,
        iconName: _selectedIconName,
        isCustomIcon: _customLogoPath != null,
        createdAt: widget.master!.createdAt,
      );
      await DatabaseService.updateMaster(updated);
    } else {
      await DatabaseService.addMaster(
        name: name,
        iconPath: _customLogoPath,
        iconName: _selectedIconName,
        isCustomIcon: _customLogoPath != null,
      );
    }

    if (!mounted) return;
    if (isEditing) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  /// Открыть экран выбора логотипа
  Future<void> _openLogoPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => _LogoPickerScreen(
          currentIconName: _customLogoPath == null ? _selectedIconName : null,
          currentLogoPath: _customLogoPath,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedIconName = result['iconName'] as String?;
        _customLogoPath = result['logoPath'] as String?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Клавиатура открыта — контент МАКСИМАЛЬНО сжимается,
    // чтобы поле + логотип-кнопка встали НАД кнопкой «Начать»
    final bool kbOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(kbOpen ? 16 : 24),
          child: Column(
            children: [
              // Кнопка "Я клиент — пропустить" (только при создании)
              if (!isEditing && !kbOpen)
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton.icon(
                    onPressed: _skip,
                    icon: const Icon(Icons.arrow_forward, size: 26),
                    label: const Text('Я клиент — пропустить'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ),

              // СКРОЛЛ + компактный режим при клавиатуре
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isEditing) ...[
                              Text(
                                'Редактирование мастера',
                                style: TextStyle(
                                  fontSize: kbOpen ? 20 : 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: kbOpen ? 12 : 32),
                            ] else ...[
                              // Логотип-лотос: 180 обычно, 80 при клавиатуре
                              SvgPicture.asset(
                                'assets/logo.svg',
                                width: kbOpen ? 80 : 180,
                                height: kbOpen ? 80 : 180,
                              ),
                              SizedBox(height: kbOpen ? 12 : 32),

                              Text(
                                'Твои Ноготочки',
                                style: TextStyle(
                                  fontSize: kbOpen ? 24 : 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              // Подзаголовок скрывается при клавиатуре
                              if (!kbOpen) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Цифровая студия nail-арта',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              SizedBox(height: kbOpen ? 16 : 40),
                            ],

                            // Поле имени
                            TextField(
                              controller: _nameController,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: 'Как вас зовут?',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                filled: true,
                                fillColor: Colors.pink.withOpacity(0.06),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(color: Colors.pink, width: 2),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: kbOpen ? 12 : 18),
                              ),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: kbOpen ? 10 : 16),

                            // Превью выбранного лого + кнопка выбора
                            GestureDetector(
                              onTap: _openLogoPicker,
                              child: Container(
                                padding: EdgeInsets.all(kbOpen ? 8 : 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.pink.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildSmallPreview(),
                                    const SizedBox(width: 12),
                                    Text(
                                      _customLogoPath != null || _selectedIconName != null
                                          ? 'Изменить логотип'
                                          : 'Выбрать логотип',
                                      style: const TextStyle(
                                        color: Colors.pink,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.edit, size: 16, color: Colors.pink),
                                  ],
                                ),
                              ),
                            ),

                            // Запас до кнопки «Начать»
                            SizedBox(height: kbOpen ? 12 : 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Кнопка внизу
              SizedBox(
                width: double.infinity,
                height: kbOpen ? 48 : 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEditing ? 'Сохранить' : 'Начать',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallPreview() {
    if (_customLogoPath != null) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: FileImage(File(_customLogoPath!)),
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.pink.withOpacity(0.15),
      child: Icon(
        MasterIcons.getIconByName(_selectedIconName ?? 'auto_awesome'),
        size: 18,
        color: Colors.pink,
      ),
    );
  }
}

/// ═══════════════════════════════════════════════
/// Отдельный экран выбора логотипа (иконки + свой)
/// ═══════════════════════════════════════════════
class _LogoPickerScreen extends StatefulWidget {
  final String? currentIconName;
  final String? currentLogoPath;

  const _LogoPickerScreen({this.currentIconName, this.currentLogoPath});

  @override
  State<_LogoPickerScreen> createState() => _LogoPickerScreenState();
}

class _LogoPickerScreenState extends State<_LogoPickerScreen> {
  late String? _selectedIconName = widget.currentIconName;
  late String? _customLogoPath = widget.currentLogoPath;

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final savedPath =
        await DatabaseService.savePhoto(File(picked.path), 'master_logo');
    setState(() {
      _customLogoPath = savedPath;
      _selectedIconName = null;
    });
  }

  void _removeCustomLogo() {
    setState(() {
      _customLogoPath = null;
      _selectedIconName ??= 'auto_awesome';
    });
  }

  void _confirm() {
    Navigator.pop(context, {
      'iconName': _selectedIconName,
      'logoPath': _customLogoPath,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Выбор логотипа'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _confirm,
            child: const Text(
              'Готово',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _buildBigPreview()),
            const SizedBox(height: 24),

            if (_customLogoPath != null) ...[
              Center(
                child: TextButton.icon(
                  onPressed: _removeCustomLogo,
                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                  label: const Text(
                    'Убрать свой логотип',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Text(
              'Или выберите из коллекции',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: MasterIcons.availableIcons.length,
              itemBuilder: (context, index) {
                final item = MasterIcons.availableIcons[index];
                final isSelected =
                    _selectedIconName == item['name'] && _customLogoPath == null;
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() {
                    _selectedIconName = item['name'] as String;
                    _customLogoPath = null;
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.pink : Colors.pink.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.pink : Colors.pink.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          color: isSelected ? Colors.white : Colors.pink,
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _pickLogo,
                icon: const Icon(Icons.upload),
                label: const Text('Загрузить свой логотип'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.pink,
                  side: const BorderSide(color: Colors.pink),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBigPreview() {
    if (_customLogoPath != null) {
      return CircleAvatar(
        radius: 56,
        backgroundImage: FileImage(File(_customLogoPath!)),
      );
    }
    return CircleAvatar(
      radius: 56,
      backgroundColor: Colors.pink.withOpacity(0.15),
      child: Icon(
        MasterIcons.getIconByName(_selectedIconName ?? 'auto_awesome'),
        size: 56,
        color: Colors.pink,
      ),
    );
  }
}