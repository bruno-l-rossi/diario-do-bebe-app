import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../main.dart' show kAccent, kCard, kMuted, kText, kBg;
import '../services/events_repo.dart';
import '../services/foreground.dart';
import '../services/session_store.dart';
import 'history_screen.dart';
import 'refeicao_sheet.dart';

const Map<String, Color> kTypeColor = {
  'soneca': Color(0xFF7AA2F7),
  'mamada': Color(0xFF9ECE6A),
  'despertar': Color(0xFFE0AF68),
  'sono': Color(0xFF7DCFFF),
  'refeicao': Color(0xFFBB9AF7),
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _profile;
  Map<String, bool> _open = {
    'soneca': false,
    'mamada': false,
    'despertar': false,
    'sono': false
  };
  bool _notifOn = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('user_id', uid)
          .limit(1);
      if (rows.isNotEmpty) {
        _profile = rows.first;
        await SessionStore.saveBabyName(
            (_profile?['baby_name'] as String?) ?? 'Bebê');
      } else {
        await _askProfile();
      }
    }
    _open = await EventsRepo.openSessions();
    _notifOn = await ForegroundController.isRunning();
    if (mounted) setState(() {});
  }

  Future<void> _askProfile() async {
    final nameCtrl = TextEditingController();
    DateTime? birth;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: kCard,
          title: const Text('Quem é o bebê?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(birth == null
                        ? 'Data de nascimento'
                        : '${birth!.day}/${birth!.month}/${birth!.year}'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setS(() => birth = d);
                    },
                    child: const Text('Escolher'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                final uid = Supabase.instance.client.auth.currentUser?.id;
                if (uid != null && nameCtrl.text.trim().isNotEmpty) {
                  await Supabase.instance.client.from('profiles').upsert({
                    'user_id': uid,
                    'baby_name': nameCtrl.text.trim(),
                    if (birth != null)
                      'baby_birth': birth!.toIso8601String().split('T').first,
                  });
                  await SessionStore.saveBabyName(nameCtrl.text.trim());
                  _profile = {'baby_name': nameCtrl.text.trim()};
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 6) return 'Madrugada';
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  Future<void> _tap(EventType type) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (type == EventType.refeicao) {
        final ok = await showRefeicaoSheet(context);
        if (ok == true && mounted) {
          _snack('Refeição registrada');
        }
      } else {
        final msg = await EventsRepo.toggleSession(type);
        _open = await EventsRepo.openSessions();
        if (mounted) _snack(msg);
      }
    } catch (_) {
      if (mounted) _snack('Falhou. Tenta de novo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), duration: const Duration(seconds: 1)),
      );

  Future<void> _toggleNotif(bool v) async {
    if (v) {
      await ForegroundController.start();
    } else {
      await ForegroundController.stop();
    }
    final running = await ForegroundController.isRunning();
    if (mounted) setState(() => _notifOn = running);
  }

  @override
  Widget build(BuildContext context) {
    final baby = (_profile?['baby_name'] as String?) ?? 'Bebê';
    return Scaffold(
      appBar: AppBar(
        title: Text('$_greeting, $baby'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Histórico',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _notifCard(),
            const SizedBox(height: 16),
            _btn(EventType.soneca),
            _btn(EventType.mamada),
            _btn(EventType.despertar),
            _btn(EventType.sono),
            _btn(EventType.refeicao),
          ],
        ),
      ),
    );
  }

  Widget _notifCard() {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeColor: kAccent,
        title: const Text('Botões fixos na tela de bloqueio',
            style: TextStyle(color: kText, fontWeight: FontWeight.w600)),
        subtitle: const Text(
          'Soneca, Mamada e Despertar num toque, mesmo com o app fechado.',
          style: TextStyle(color: kMuted, fontSize: 12),
        ),
        value: _notifOn,
        onChanged: _toggleNotif,
      ),
    );
  }

  Widget _btn(EventType type) {
    final isOpen = _open[type.id] == true;
    final color = kTypeColor[type.id]!;
    final label = type.isSession
        ? (isOpen ? 'Encerrar ${type.label}' : type.label)
        : type.label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 72,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: isOpen ? color : kCard,
            foregroundColor: isOpen ? kBg : kText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: color, width: isOpen ? 0 : 1.5),
            ),
          ),
          onPressed: _busy ? null : () => _tap(type),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isOpen ? kBg : color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w600)),
              if (isOpen) ...[
                const SizedBox(width: 10),
                const Icon(Icons.fiber_manual_record, size: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
