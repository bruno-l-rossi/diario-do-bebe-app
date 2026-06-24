import 'package:flutter/material.dart';

import '../main.dart' show kAccent, kCard, kMuted, kText, kBg;
import '../services/events_repo.dart';

/// Folha pra registrar refeicao: quanto comeu + quem serviu + nota opcional.
/// Pensado pra introducao alimentar, onde a recusa e o dado que mais importa.
Future<bool?> showRefeicaoSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: kCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => const _RefeicaoForm(),
  );
}

class _RefeicaoForm extends StatefulWidget {
  const _RefeicaoForm();

  @override
  State<_RefeicaoForm> createState() => _RefeicaoFormState();
}

class _RefeicaoFormState extends State<_RefeicaoForm> {
  int _quality = 2;
  String _servedBy = 'mae';
  final _note = TextEditingController();
  bool _saving = false;

  static const _qualities = ['Recusou', 'Pouco', 'Médio', 'Bem'];
  static const _whoLabels = {'mae': 'Mãe', 'pai': 'Pai', 'outro': 'Outro'};

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await EventsRepo.insertRefeicao(
        quality: _quality,
        servedBy: _servedBy,
        note: _note.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falhou. Tenta de novo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Refeição',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: kText)),
          const SizedBox(height: 16),
          const Text('Quanto comeu', style: TextStyle(color: kMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(_qualities.length, (i) {
              final sel = _quality == i;
              return ChoiceChip(
                label: Text(_qualities[i]),
                selected: sel,
                selectedColor: kAccent,
                labelStyle: TextStyle(color: sel ? kBg : kText),
                backgroundColor: kBg,
                onSelected: (_) => setState(() => _quality = i),
              );
            }),
          ),
          const SizedBox(height: 16),
          const Text('Quem serviu', style: TextStyle(color: kMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _whoLabels.entries.map((e) {
              final sel = _servedBy == e.key;
              return ChoiceChip(
                label: Text(e.value),
                selected: sel,
                selectedColor: kAccent,
                labelStyle: TextStyle(color: sel ? kBg : kText),
                backgroundColor: kBg,
                onSelected: (_) => setState(() => _servedBy = e.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Nota (opcional)',
              filled: true,
              fillColor: kBg,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '...' : 'Registrar refeição'),
            ),
          ),
        ],
      ),
    );
  }
}
