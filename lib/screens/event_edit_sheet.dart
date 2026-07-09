import 'package:flutter/material.dart';

import '../data/store.dart';
import '../models/baby_event.dart';
import '../theme.dart';
import '../utils/format.dart';

/// Edita o horário de um registro feito atrasado: início e, se for sessão
/// encerrada, o fim também.
Future<void> showEventEditSheet(BuildContext context, BabyEvent e) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _EditForm(event: e),
  );
}

class _EditForm extends StatefulWidget {
  final BabyEvent event;
  const _EditForm({required this.event});

  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  late DateTime _ts;
  DateTime? _end;
  bool _saving = false;

  bool get _hasEnd => widget.event.isSession && widget.event.end != null;

  @override
  void initState() {
    super.initState();
    _ts = widget.event.ts;
    _end = widget.event.end;
  }

  Future<DateTime?> _pick(DateTime initial) async {
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null || !mounted) return null;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AppStore.I.updateEventTime(widget.event.id, _ts, _hasEnd ? _end : null);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falhou ao salvar.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final label = _typeLabel(widget.event.type);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Editar horário — $label',
              style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _row(_hasEnd ? 'Início' : 'Horário', _ts, () async {
            final r = await _pick(_ts);
            if (r != null) setState(() => _ts = r);
          }),
          if (_hasEnd) ...[
            const SizedBox(height: 10),
            _row('Fim', _end!, () async {
              final r = await _pick(_end!);
              if (r != null) setState(() => _end = r);
            }),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '...' : 'Salvar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, DateTime value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Text(label,
                style: TextStyle(color: AppColors.muted, fontSize: 13)),
            const Spacer(),
            Text(
              '${value.day}/${value.month} · ${fmtH(value)}',
              style: TextStyle(
                  color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Icon(Icons.edit_calendar, size: 18, color: AppColors.accent),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'soneca':
        return 'Soneca';
      case 'sono':
        return 'Sono noturno';
      case 'mamada':
        return 'Mamada';
      case 'despertar':
        return 'Despertar';
      case 'refeicao':
        return 'Refeição';
      default:
        return t;
    }
  }
}
