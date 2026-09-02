// lib/screens/crm_screen.dart

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/client.dart';
import '../models/nail_session.dart';
import '../services/database_service.dart';
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

  List<Client> _clients = [];
  List<NailSession> _allSessions = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: Colors.black87,
      ));
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

  // ============ BUILD ============

  @override
  Widget build(BuildContext context) {
    final dueCount = _clients.where(_isDue).length;

    return Scaffold(
      appBar: HomeAppBar(
        title: const Text('CRM', style: TextStyle(fontSize: 24)),
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
            color: Theme.of(context).colorScheme.primary,
              child: TabBar(
              controller: _tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w600),
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(width: 7.0, color: Colors.white),
              ),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(text: 'Клиенты (${_clients.length})'),
                Tab(text: 'Напоминания${dueCount > 0 ? ' ($dueCount)' : ''}'),
                const Tab(text: 'Финансы'),
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
              fillColor: Colors.grey[100],
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
              ? const Center(
                  child: Text('Никого не нашли 😔',
                      style: TextStyle(fontSize: 18, color: Colors.grey)))
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
                              due ? Colors.orange : Colors.pink,
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
                                fontSize: 19, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${c.phone ?? 'без телефона'}\n'
                          'Был(а): ${last != null ? _fmtDate(last) : '—'} • '
                          '${_fmtMoney(total)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: due
                            ? const Icon(Icons.notifications_active,
                                color: Colors.orange, size: 26)
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
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green[300]),
            const SizedBox(height: 16),
            const Text('Всем клиентам недавно писали 🎉',
                style: TextStyle(fontSize: 20, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
                'Напоминания появятся через '
                '${DatabaseService.reminderDays} дней после визита',
                style: const TextStyle(fontSize: 15, color: Colors.grey)),
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
                        color: Colors.orange,
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
                  style: TextStyle(fontSize: 15, color: Colors.grey[700]),
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
                          backgroundColor: Colors.green,
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
                          foregroundColor: Colors.pink,
                          side: const BorderSide(color: Colors.pink),
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
              child: _statCard('За месяц', _fmtMoney(monthSum), Colors.pink),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard('Всего', _fmtMoney(totalSum), Colors.deepPurple),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard('Визитов', '${_allSessions.length}', Colors.teal),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard('Средний чек', _fmtMoney(avg), Colors.orange),
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
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE91E63), Color(0xFF7B1FA2)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
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
              backgroundColor: Colors.pink,
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
                    color: Colors.pink)),
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
          colors: [color, color.withOpacity(0.7)],
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