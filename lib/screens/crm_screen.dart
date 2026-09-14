// lib/screens/crm_screen.dart

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/client.dart';
import '../models/nail_session.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/top_message.dart';
import '../widgets/home_app_bar.dart';
import 'client_detail_screen.dart';

/// CRM: вкладки Клиенты / Напоминания / Финансы
class CrmScreen extends StatefulWidget {
  const CrmScreen({super.key});

  @override
  State<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends State<CrmScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _lastTabIndex = 0;

  List<Client> _clients = [];
  List<NailSession> _allSessions = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(_onTabChanged);
    _load();
  }

  @override
  void dispose() {
    _tab.removeListener(_onTabChanged);
    _tab.dispose();
    super.dispose();
  }

  /// Перерисовка при смене вкладки (чтобы FAB показывался только на «Клиенты»)
  void _onTabChanged() {
    if (_tab.index != _lastTabIndex) {
      _lastTabIndex = _tab.index;
      if (mounted) setState(() {});
    }
  }

  void _load() {
    setState(() {
      _clients = DatabaseService.getClients();
      _allSessions = DatabaseService.getAllSessions();
    });
  }

  // ============ ПОМОЩНИКИ ============

  List<NailSession> _sessionsOf(Client c) =>
      _allSessions.where((s) => s.clientId == c.id).toList();

  DateTime? _lastVisit(Client c) {
    final s = _sessionsOf(c);
    return s.isEmpty ? null : s.first.createdAt; // отсортированы по убыванию
  }

  double _totalOf(Client c) =>
      _sessionsOf(c).fold(0, (sum, s) => sum + (s.price ?? 0));

  bool _isDue(Client c) {
    final last = _lastVisit(c);
    if (last == null) return false;
    return DateTime.now().difference(last).inDays >=
        DatabaseService.reminderDays;
  }

  String _fmtMoney(double v) =>
      '${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 0)} ₽';

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';

  // ============ СОЗДАНИЕ КЛИЕНТА ============

  /// Диалог «Новый клиент»: имя обязательно, телефон опционален.
  /// После сохранения сразу открываем карточку клиента.
  Future<void> _addClient() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final nameOk = nameController.text.trim().isNotEmpty;

          // Проверка дубликата телефона (подсказка, не блокировка)
          final digits =
              phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
          String? duplicate;
          if (digits.length >= 5) {
            for (final c in _clients) {
              final cd =
                  (c.phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
              if (cd.isNotEmpty && cd == digits) {
                duplicate = 'Похоже, такой клиент уже есть: ${c.name}';
                break;
              }
            }
          }

          return AlertDialog(
            title: const Text('Новый клиент', style: TextStyle(fontSize: 20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Имя *'),
                  style: const TextStyle(fontSize: 18),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Телефон',
                    hintText: '+7 999 123-45-67',
                  ),
                  style: const TextStyle(fontSize: 18),
                  onChanged: (_) => setDialogState(() {}),
                ),
                if (duplicate != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber,
                          color: Colors.orange, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          duplicate!,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена', style: TextStyle(fontSize: 16)),
              ),
              ElevatedButton(
                onPressed:
                    nameOk ? () => Navigator.pop(context, true) : null,
                child: const Text('Сохранить', style: TextStyle(fontSize: 16)),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true) return;

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    final newClient = await DatabaseService.addClient(
      name: name,
      phone: phone.isEmpty ? null : phone,
    );
    _load();

    if (!mounted) return;
    // Сразу открываем карточку: мастер может добавить фото «до» и заметки
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClientDetailScreen(client: newClient)),
    );
    _load();
  }

  // ============ СВЯЗЬ ============

  Future<void> _call(Client c) async {
    final phone = c.phone?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';
    if (phone.isEmpty) {
      _snack('У клиента нет телефона');
      return;
    }
    await launchUrl(Uri.parse('tel:$phone'));
  }

  Future<void> _whatsapp(Client c) async {
    final digits = c.phone?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    if (digits.isEmpty) {
      _snack('У клиента нет телефона');
      return;
    }
    final text = Uri.encodeComponent(
        '${c.name}, здравствуйте! Пора обновить ноготочки 💅 '
        'Есть окошки на этой неделе?');
    await launchUrl(Uri.parse('https://wa.me/7$digits?text=$text'));
  }

  void _shareInvite(Client c) {
    Share.share(
        '${c.name}, здравствуйте! Пора обновить ноготочки 💅 '
        'Есть окошки на этой неделе?');
  }

  void _snack(String text) {
    if (mounted) {
      TopMessage.show(context, text,
          color: text.contains('нет телефона') ? Colors.orange : null);
    }
  }

  // ============ НАСТРОЙКИ CRM ============

  Future<void> _openSettings() async {
    final daysController =
        TextEditingController(text: '${DatabaseService.reminderDays}');
    final priceController =
        TextEditingController(text: '${DatabaseService.defaultPrice.toInt()}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Настройки CRM', style: TextStyle(fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: daysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Напоминать через (дней)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Цена по умолчанию (₽)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сохранить', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (ok == true) {
      final days = int.tryParse(daysController.text.trim());
      final price = double.tryParse(priceController.text.trim());
      if (days != null && days > 0) await DatabaseService.setReminderDays(days);
      if (price != null && price >= 0) await DatabaseService.setDefaultPrice(price);
      _load();
    }
  }

  // ============ БЕЙДЖИ ВКЛАДОК ============

    /// Вкладка: текст + бейдж-пилл со счётчиком. Без иконки и с компактным
  /// шрифтом — гарантированно влезает в треть ширины экрана;
  /// FittedBox(scaleDown) страхует совсем узкие экраны.
  Widget _tabLabel({
    required String label,
    int count = 0,
    bool isAlert = false,
  }) {
    // Напоминания с должниками = бирюзовый alert-бейдж, иначе нейтральный
    final Color badgeColor =
        isAlert && count > 0 ? AppColors.cyan : Colors.white24;
    final String countText = count > 99 ? '99+' : '$count';

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            constraints: const BoxConstraints(minWidth: 22, minHeight: 18),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              countText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ BUILD ============

  @override
  Widget build(BuildContext context) {
    final dueCount = _clients.where(_isDue).length;

    return Scaffold(
      appBar: HomeAppBar(
        title: const Text('CRM', style: TextStyle(fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 26),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.wine,
            child: TabBar(
              controller: _tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(width: 3.0, color: AppColors.cyan),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: EdgeInsets.zero,
                            tabs: [
                Tab(
                  child: _tabLabel(
                    label: 'Клиенты',
                    count: _clients.length,
                  ),
                ),
                Tab(
                  child: _tabLabel(
                    label: 'Напоминания',
                    count: dueCount,
                    isAlert: true,
                  ),
                ),
                Tab(
                  child: _tabLabel(
                    label: 'Финансы',
                    count: _allSessions.length,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildClientsTab(),
                _buildRemindersTab(),
                _buildFinanceTab(),
              ],
            ),
          ),
        ],
      ),
      // FAB только на вкладке «Клиенты»
      floatingActionButton: _tab.index == 0
          ? FloatingActionButton(
              onPressed: _addClient,
              backgroundColor: AppColors.cyan,
              tooltip: 'Новый клиент',
              child: const Icon(Icons.person_add_alt_1,
                  color: Colors.white, size: 28),
            )
          : null,
    );
  }

  // ============ ВКЛАДКА: КЛИЕНТЫ ============

  Widget _buildClientsTab() {
    final filtered = _search.isEmpty
        ? _clients
        : _clients
            .where((c) =>
                c.name.toLowerCase().contains(_search.toLowerCase()) ||
                (c.phone ?? '').contains(_search))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Поиск: имя или телефон',
              hintStyle: const TextStyle(fontSize: 16),
              prefixIcon: const Icon(Icons.search, size: 26),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline,
                          size: 80, color: AppColors.inkSoft),
                      const SizedBox(height: 12),
                      Text(
                        _clients.isEmpty
                            ? 'Пока нет клиентов'
                            : 'Никого не нашли 😔',
                        style: TextStyle(
                            fontSize: 18, color: AppColors.inkSoft),
                      ),
                      if (_clients.isEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Нажмите + внизу, чтобы добавить первого',
                          style: TextStyle(fontSize: 15, color: AppColors.inkSoft),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final c = filtered[i];
                    final last = _lastVisit(c);
                    final total = _totalOf(c);
                    final due = _isDue(c);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor:
                              due ? AppColors.wine : AppColors.navy,
                          child: Text(
                            c.name.isNotEmpty
                                ? c.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 22),
                          ),
                        ),
                        title: Text(c.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${c.phone ?? 'без телефона'}\n'
                          'Был(а): ${last != null ? _fmtDate(last) : '—'} • '
                          '${_fmtMoney(total)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: due
                            ? const Icon(Icons.notifications_active,
                                color: AppColors.wine, size: 26)
                            : null,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ClientDetailScreen(client: c)),
                          );
                          _load();
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ============ ВКЛАДКА: НАПОМИНАНИЯ ============

  Widget _buildRemindersTab() {
    final due = _clients.where(_isDue).toList()
      ..sort((a, b) =>
          (_lastVisit(a) ?? DateTime(0)).compareTo(_lastVisit(b) ?? DateTime(0)));

    if (due.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 80, color: AppColors.cyan),
            const SizedBox(height: 16),
            Text('Всем клиентам недавно писали 🎉',
                style: TextStyle(fontSize: 20, color: AppColors.inkSoft)),
            const SizedBox(height: 8),
            Text(
                'Напоминания появятся через '
                '${DatabaseService.reminderDays} дней после визита',
                style: TextStyle(fontSize: 15, color: AppColors.inkSoft)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: due.length,
      itemBuilder: (context, i) {
        final c = due[i];
        final days =
            DateTime.now().difference(_lastVisit(c)!).inDays;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(c.name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.wine,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('$days дн.',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Последний визит: ${_fmtDate(_lastVisit(c)!)}',
                  style: TextStyle(fontSize: 15, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _whatsapp(c),
                        icon: const Icon(Icons.chat, size: 22),
                        label: const Text('Написать',
                            style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _call(c),
                        icon: const Icon(Icons.call, size: 22),
                        label: const Text('Позвонить',
                            style: TextStyle(fontSize: 16)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.wine,
                          side: const BorderSide(color: AppColors.wine),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, size: 26),
                      onPressed: () => _shareInvite(c),
                      tooltip: 'Другой способ',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============ ВКЛАДКА: ФИНАНСЫ ============

  Widget _buildFinanceTab() {
    final now = DateTime.now();
    final monthSessions = _allSessions.where((s) =>
        s.createdAt.month == now.month && s.createdAt.year == now.year);
    final monthSum = monthSessions.fold(0.0, (s, x) => s + (x.price ?? 0));
    final totalSum =
        _allSessions.fold(0.0, (s, x) => s + (x.price ?? 0));
    final withPrice = _allSessions.where((s) => s.price != null).length;
        final double avg = withPrice > 0 ? totalSum / withPrice : 0.0;

    // Последние 6 месяцев
    final months = <Map<String, dynamic>>[];
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final sum = _allSessions
          .where((s) =>
              s.createdAt.month == d.month && s.createdAt.year == d.year)
          .fold(0.0, (s, x) => s + (x.price ?? 0));
      const names = ['ян', 'фв', 'мр', 'ап', 'мй', 'ин',
                     'ил', 'ав', 'сн', 'ок', 'нб', 'дк'];
      months.add({'label': names[d.month - 1], 'sum': sum});
    }
    final maxSum = months.fold(1.0, (m, x) =>
        (x['sum'] as double) > m ? (x['sum'] as double) : m);

    // Топ-5 клиентов
    final top = List<Client>.from(_clients)
      ..sort((a, b) => _totalOf(b).compareTo(_totalOf(a)));
    final top5 = top.take(5).toList();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard('За месяц', _fmtMoney(monthSum), AppColors.wine),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard('Всего', _fmtMoney(totalSum), AppColors.navy),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard('Визитов', '${_allSessions.length}', AppColors.cyanDeep),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard('Средний чек', _fmtMoney(avg), AppColors.wineSoft),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Доход за 6 месяцев',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: months.map((m) {
              final sum = m['sum'] as double;
              final h = maxSum > 0 ? (sum / maxSum) * 120.0 : 0;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      sum > 0 ? '${sum.toInt()}' : '',
                      style: const TextStyle(fontSize: 11),
                    ),
                    Container(
                      height: (h as double).clamp(4, 120),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        gradient: AppGradients.cta,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(m['label'] as String,
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Топ-5 клиентов',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...top5.asMap().entries.map((e) {
          final i = e.key;
          final c = e.value;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.wine,
              child: Text('${i + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            title: Text(c.name,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600)),
            trailing: Text(_fmtMoney(_totalOf(c)),
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.wine)),
          );
        }),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}