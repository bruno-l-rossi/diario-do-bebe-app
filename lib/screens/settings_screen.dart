import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/settings.dart';
import '../data/store.dart';
import '../services/foreground.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'help_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _name;
  late TextEditingController _mother;
  DateTime? _birth;
  String? _photo; // data URI base64
  bool _notifOn = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = AppStore.I;
    _name = TextEditingController(text: s.babyName);
    _mother = TextEditingController(text: s.motherName);
    _birth = (s.babyBirth != null && s.babyBirth!.isNotEmpty)
        ? DateTime.tryParse(s.babyBirth!)
        : null;
    _photo = s.babyPhoto;
    ForegroundController.isRunning().then((v) {
      if (mounted) setState(() => _notifOn = v);
    });
  }

  Future<void> _pickPhoto() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.card,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera, color: AppColors.accent),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.accent),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (src == null) return;
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: src,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 70,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() => _photo = 'data:image/jpeg;base64,${base64Encode(bytes)}');
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      _snack('Coloca o nome do bebê.');
      return;
    }
    setState(() => _saving = true);
    try {
      await AppStore.I.saveProfile(
        name: _name.text.trim(),
        birth: _birth?.toIso8601String().split('T').first,
        mother: _mother.text.trim(),
        photo: _photo,
      );
      _snack('Salvo.');
    } catch (_) {
      _snack('Falhou ao salvar.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setTimeFmt(String fmt) async {
    await Settings.setTimeFmt(fmt);
    AppStore.I.notifyListeners(); // atualiza horários em todo o app
    setState(() {});
  }

  Future<void> _toggleNotif(bool v) async {
    if (v) {
      await ForegroundController.start();
    } else {
      await ForegroundController.stop();
    }
    final on = await ForegroundController.isRunning();
    if (mounted) setState(() => _notifOn = on);
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m), duration: const Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '—';
    final idade = _birth != null
        ? ageLabel(_birth!.toIso8601String().split('T').first)
        : '';
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Perfil do bebê'),
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _Avatar(photo: _photo, name: _name.text),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        color: AppColors.accent, shape: BoxShape.circle),
                    child: Icon(Icons.edit,
                        size: 14, color: AppColors.onAccent),
                  ),
                ],
              ),
            ),
          ),
          if (idade.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(idade,
                    style: TextStyle(color: AppColors.muted)),
              ),
            ),
          const SizedBox(height: 16),
          _field(_name, 'Nome do bebê', onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          _field(_mother, 'Nome da mãe (opcional)'),
          const SizedBox(height: 12),
          _dateRow(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '...' : 'Salvar perfil'),
            ),
          ),
          _section('Formato de hora'),
          _timeFmtSelector(),
          _section('Notificação'),
          Container(
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.accent,
              title: Text('Botões fixos na tela de bloqueio',
                  style: TextStyle(color: AppColors.ink)),
              value: _notifOn,
              onChanged: _toggleNotif,
            ),
          ),
          _section('Ajuda'),
          Container(
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line)),
            child: ListTile(
              leading:
                  Icon(Icons.help_outline, color: AppColors.accent),
              title: Text('Tutorial e contato',
                  style: TextStyle(color: AppColors.ink, fontSize: 14)),
              subtitle: Text('Rever o tour ou falar com a gente',
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
              onTap: () => showHelpSheet(context),
            ),
          ),
          _section('Conta'),
          Container(
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.mail_outline, color: AppColors.muted),
                  title: Text(email,
                      style: TextStyle(color: AppColors.ink, fontSize: 14)),
                ),
                Divider(height: 1, color: AppColors.line),
                ListTile(
                  leading: Icon(Icons.logout, color: AppColors.qBad),
                  title: Text('Sair', style: TextStyle(color: AppColors.qBad)),
                  onTap: () => Supabase.instance.client.auth.signOut(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
        child: Text(t.toUpperCase(),
            style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      );

  Widget _field(TextEditingController c, String label,
          {void Function(String)? onChanged}) =>
      TextField(
        controller: c,
        onChanged: onChanged,
        style: TextStyle(color: AppColors.ink),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.card,
        ),
      );

  Widget _dateRow() {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.line)),
      padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _birth == null
                  ? 'Data de nascimento'
                  : '${_birth!.day}/${_birth!.month}/${_birth!.year}',
              style: TextStyle(
                  color: _birth == null ? AppColors.muted : AppColors.ink),
            ),
          ),
          TextButton(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _birth ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _birth = d);
            },
            child: const Text('Escolher'),
          ),
        ],
      ),
    );
  }

  Widget _timeFmtSelector() {
    Widget seg(String id, String label) {
      final active = currentTimeFmt == id;
      return Expanded(
        child: GestureDetector(
          onTap: () => _setTimeFmt(id),
          child: Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: active ? AppColors.onAccent : AppColors.muted,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.line)),
      child: Row(children: [seg('24h', '24 horas'), seg('12h', 'AM / PM')]),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? photo;
  final String name;
  const _Avatar({this.photo, required this.name});

  @override
  Widget build(BuildContext context) {
    Widget inner;
    if (photo != null && photo!.isNotEmpty) {
      try {
        final b64 = photo!.contains(',') ? photo!.split(',').last : photo!;
        inner = ClipOval(
            child: Image.memory(base64Decode(b64),
                width: 84, height: 84, fit: BoxFit.cover));
      } catch (_) {
        inner = _ini();
      }
    } else {
      inner = _ini();
    }
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.card2,
          border: Border.all(color: AppColors.accent, width: 2)),
      alignment: Alignment.center,
      child: inner,
    );
  }

  Widget _ini() => Text(
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '🍼',
        style: TextStyle(
            color: AppColors.accentSoft, fontSize: 34, fontWeight: FontWeight.w700),
      );
}
