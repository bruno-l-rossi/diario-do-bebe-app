import 'package:flutter/material.dart';

import '../data/store.dart';
import '../models/baby_event.dart';
import '../theme.dart';

/// Ficha da nota do dia: um campo de texto e pronto. Serve pra criar
/// (sem `event`) e pra editar uma nota existente (com `event`).
/// É o lado "diário" do Diário do Bebê: memória pra reler depois.
Future<bool?> showNotaSheet(BuildContext context, {BabyEvent? event}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _NotaForm(event: event),
  );
}

class _NotaForm extends StatefulWidget {
  final BabyEvent? event;
  const _NotaForm({this.event});

  @override
  State<_NotaForm> createState() => _NotaFormState();
}

class _NotaFormState extends State<_NotaForm> {
  late final TextEditingController _text;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.event?.note ?? '');
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    setState(() => _saving = true);
    try {
      if (widget.event == null) {
        await AppStore.I.addNota(t);
      } else {
        await AppStore.I.updateNota(widget.event!.id, t);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Falhou ao salvar. Tenta de novo.'),
            duration: Duration(seconds: 2)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final editing = widget.event != null;
    final nome = AppStore.I.babyName;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: kNotaColor, size: 20),
              const SizedBox(width: 8),
              Text(editing ? 'Editar nota' : 'Nota do dia',
                  style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            nome.isEmpty
                ? 'Uma lembrança, uma conquista, como foi o dia. Fica guardado no histórico.'
                : 'Uma lembrança, uma conquista, como $nome estava hoje. Fica guardado no histórico.',
            style: TextStyle(
                color: AppColors.muted, fontSize: 12.5, height: 1.5),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _text,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: AppColors.ink, height: 1.45),
            decoration: InputDecoration(
              hintText: 'Ex.: hoje ficou de pé sozinho pela primeira vez!',
              hintStyle: TextStyle(color: AppColors.muted, fontSize: 13),
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.line),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed:
                  _saving || _text.text.trim().isEmpty ? null : _save,
              child: Text(_saving ? '...' : 'Guardar no diário'),
            ),
          ),
        ],
      ),
    );
  }
}
