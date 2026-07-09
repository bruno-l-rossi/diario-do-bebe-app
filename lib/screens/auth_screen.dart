import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme.dart';

/// Login e cadastro por email/senha, mesma conta do app web.
/// Tom acolhedor: é a porta de entrada de uma mãe cansada, não um formulário.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _signup = false;
  bool _loading = false;
  bool _showPass = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      if (_signup) {
        await auth.signUp(email: _email.text.trim(), password: _pass.text);
      } else {
        await auth.signInWithPassword(
          email: _email.text.trim(),
          password: _pass.text,
        );
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Não rolou. Confere email e senha.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👶', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              Text(
                'Diário do Bebê',
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                _signup
                    ? 'Vamos criar o cantinho do seu bebê.\nLeva menos de um minuto.'
                    : 'Que bom te ver de novo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.muted, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: AppColors.card,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pass,
                obscureText: !_showPass,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  filled: true,
                  fillColor: AppColors.card,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPass ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.muted,
                    ),
                    tooltip: _showPass ? 'Esconder senha' : 'Mostrar senha',
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: TextStyle(color: AppColors.qOk)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _loading ? null : _submit,
                  child: Text(_loading
                      ? '...'
                      : (_signup ? 'Começar nosso diário' : 'Entrar')),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _signup = !_signup),
                child: Text(
                  _signup
                      ? 'Já tenho conta. Entrar'
                      : 'Primeira vez aqui? Criar nossa conta',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
