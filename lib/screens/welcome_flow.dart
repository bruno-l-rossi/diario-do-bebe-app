import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/store.dart';
import '../theme.dart';

/// Boas-vindas depois de criar a conta: uma pergunta por tela, tom de
/// conversa. Monta o perfil (mãe, bebê, nascimento, foto) sem parecer
/// formulário. Aparece enquanto o perfil não tem nome de bebê.
class WelcomeFlow extends StatefulWidget {
  const WelcomeFlow({super.key});

  @override
  State<WelcomeFlow> createState() => _WelcomeFlowState();
}

class _WelcomeFlowState extends State<WelcomeFlow> {
  final _page = PageController();
  int _step = 0;

  final _mother = TextEditingController();
  final _baby = TextEditingController();
  DateTime? _birth;
  String? _photo; // data URI base64
  bool _saving = false;

  static const _totalSteps = 4;

  @override
  void dispose() {
    _page.dispose();
    _mother.dispose();
    _baby.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      _page.nextPage(
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  }

  void _back() {
    if (_step > 0) {
      _page.previousPage(
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
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
    final x = await ImagePicker().pickImage(
      source: src,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 70,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() => _photo = 'data:image/jpeg;base64,${base64Encode(bytes)}');
  }

  Future<void> _finish() async {
    if (_baby.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await AppStore.I.saveProfile(
        name: _baby.text.trim(),
        birth: _birth?.toIso8601String().split('T').first,
        mother: _mother.text.trim(),
        photo: _photo,
      );
      // O AuthGate percebe o perfil preenchido e troca de tela sozinho.
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _dots(),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _step = i),
                children: [
                  _stepWelcome(),
                  _stepMother(),
                  _stepBaby(),
                  _stepPhoto(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalSteps, (i) {
        final on = i == _step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: on ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: on ? AppColors.accent : AppColors.line,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }

  // ---- passos ----

  Widget _stepWelcome() {
    return _StepShell(
      emoji: '👶',
      title: 'Que alegria ter vocês aqui',
      sub: 'Este diário é o cantinho de vocês: as sonecas, as mamadas, '
          'as noites (boas e difíceis) do seu bebê, tudo num toque.\n\n'
          'Antes de começar, me conta um pouquinho de vocês dois?',
      body: const SizedBox.shrink(),
      primary: 'Vamos lá',
      onPrimary: _next,
    );
  }

  Widget _stepMother() {
    return _StepShell(
      emoji: '💛',
      title: 'Como você quer ser chamada?',
      sub: 'Pra gente te dar bom dia do jeito certo.',
      body: TextField(
        controller: _mother,
        textCapitalization: TextCapitalization.words,
        autofocus: false,
        decoration: InputDecoration(
          labelText: 'Seu nome',
          filled: true,
          fillColor: AppColors.card,
        ),
        onChanged: (_) => setState(() {}),
      ),
      primary: 'Continuar',
      onPrimary: _next,
      secondary: 'Prefiro não dizer',
      onSecondary: () {
        _mother.clear();
        _next();
      },
      onBack: _back,
    );
  }

  Widget _stepBaby() {
    final ok = _baby.text.trim().isNotEmpty;
    return _StepShell(
      emoji: '🌟',
      title: _mother.text.trim().isEmpty
          ? 'E a estrela do diário?'
          : 'E a estrela do diário, ${_mother.text.trim()}?',
      sub: 'O nome aparece em todo o app, e a data de nascimento '
          'mostra a idade certinha em semanas e meses.',
      body: Column(
        children: [
          TextField(
            controller: _baby,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Nome do bebê',
              filled: true,
              fillColor: AppColors.card,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _birth == null
                        ? 'Data de nascimento (opcional)'
                        : 'Nasceu em ${_birth!.day}/${_birth!.month}/${_birth!.year}',
                    style: TextStyle(
                        color:
                            _birth == null ? AppColors.muted : AppColors.ink),
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
          ),
        ],
      ),
      primary: 'Continuar',
      onPrimary: ok ? _next : null,
      onBack: _back,
    );
  }

  Widget _stepPhoto() {
    final name = _baby.text.trim();
    return _StepShell(
      emoji: '📷',
      title: name.isEmpty ? 'Uma foto pro diário?' : 'Uma foto de $name?',
      sub: 'Ela aparece na home, do lado do bom dia. '
          'Dá pra colocar ou trocar depois nas configurações.',
      body: Center(
        child: GestureDetector(
          onTap: _pickPhoto,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.card2,
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            alignment: Alignment.center,
            child: _photo == null
                ? Icon(Icons.add_a_photo,
                    color: AppColors.accentSoft, size: 36)
                : ClipOval(
                    child: Image.memory(
                      base64Decode(_photo!.split(',').last),
                      width: 116,
                      height: 116,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
        ),
      ),
      primary: _saving ? '...' : 'Pronto, começar o diário',
      onPrimary: _saving ? null : _finish,
      secondary: _photo == null ? 'Deixar pra depois' : null,
      onSecondary: _saving ? null : _finish,
      onBack: _back,
    );
  }
}

/// Molde dos passos: emoji grande, título, texto, corpo e botões.
class _StepShell extends StatelessWidget {
  final String emoji, title, sub, primary;
  final Widget body;
  final VoidCallback? onPrimary;
  final String? secondary;
  final VoidCallback? onSecondary;
  final VoidCallback? onBack;

  const _StepShell({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.body,
    required this.primary,
    required this.onPrimary,
    this.secondary,
    this.onSecondary,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 14),
          Text(title,
              style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 24,
                  height: 1.25,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(sub,
              style: TextStyle(
                  color: AppColors.muted, fontSize: 14.5, height: 1.55)),
          const SizedBox(height: 26),
          body,
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: onPrimary,
              child: Text(primary,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          if (secondary != null)
            Center(
              child: TextButton(
                onPressed: onSecondary,
                child: Text(secondary!,
                    style: TextStyle(color: AppColors.muted)),
              ),
            ),
          if (onBack != null)
            Center(
              child: TextButton(
                onPressed: onBack,
                child: Text('Voltar',
                    style: TextStyle(color: AppColors.muted)),
              ),
            ),
        ],
      ),
    );
  }
}
