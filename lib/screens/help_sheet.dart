import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';
import 'onboarding_screen.dart';

const kContatoEmail = 'rideblan33@caramujorecords.com.br';

/// Ajuda em duas opções, sem labirinto: rever o tutorial do primeiro uso
/// ou mandar um email pra gente. Usado no "?" do topo e nas configurações.
Future<void> showHelpSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Icon(Icons.help_outline, size: 18, color: AppColors.accent),
                SizedBox(width: 8),
                Text('Precisa de uma mão?',
                    style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.lightbulb_outline, color: AppColors.accent),
            title: const Text('Ver o tutorial'),
            subtitle: Text('O tour rápido do primeiro uso',
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const OnboardingScreen(standalone: true)),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.mail_outline, color: AppColors.accent),
            title: const Text('Falar com a gente'),
            subtitle: Text(kContatoEmail,
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
            onTap: () async {
              Navigator.pop(ctx);
              final uri = Uri(
                scheme: 'mailto',
                path: kContatoEmail,
                query: 'subject=Diário do Bebê',
              );
              try {
                await launchUrl(uri);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Escreve pra $kContatoEmail'),
                      duration: const Duration(seconds: 4)));
                }
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
