import 'package:flutter/material.dart';

import '../data/store.dart';
import '../models/baby_event.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'nota_sheet.dart';

/// Aba Notas: o lado "diário de verdade" do app, num calendário do mês.
/// Dias com nota ficam marcados e clicáveis: tocar abre as notas do dia
/// pra ler, editar ou apagar. Usa a data do calendário (não o "dia do
/// bebê"): nota é lembrança do dia civil em que foi escrita.
class NotasTab extends StatefulWidget {
  const NotasTab({super.key});

  @override
  State<NotasTab> createState() => _NotasTabState();
}

class _NotasTabState extends State<NotasTab> {
  late DateTime _month; // dia 1 do mês exibido

  static const _meses = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
  ];
  static const _semana = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
  }

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, List<BabyEvent>> _notasPorDia(AppStore s) {
    final map = <String, List<BabyEvent>>{};
    for (final e in s.events) {
      if (e.type != 'nota') continue;
      map.putIfAbsent(_dayKey(e.ts), () => []).add(e);
    }
    for (final l in map.values) {
      l.sort((a, b) => a.ts.compareTo(b.ts));
    }
    return map;
  }

  bool get _noMesAtual {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  void _mudaMes(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta, 1));
  }

  Future<void> _novaNota() async {
    final ok = await showNotaSheet(context);
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Guardado no diário 💛'),
          duration: Duration(seconds: 1)));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStore.I;
    final notas = _notasPorDia(s);

    return RefreshIndicator(
      onRefresh: s.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _botaoNova(),
          const SizedBox(height: 12),
          _calendario(notas),
          const SizedBox(height: 14),
          if (notas.isEmpty) _vazio() else _ultimas(notas),
        ],
      ),
    );
  }

  Widget _botaoNova() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: kNotaColor,
          foregroundColor: AppColors.onAccent,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: _novaNota,
        icon: const Icon(Icons.favorite, size: 18),
        label: const Text('Escrever uma nota',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ---- calendário ----

  Widget _calendario(Map<String, List<BabyEvent>> notas) {
    final primeiro = _month;
    final diasNoMes = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = primeiro.weekday % 7; // domingo primeiro
    final hoje = DateTime.now();

    final cells = <Widget>[];
    for (var i = 0; i < offset; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= diasNoMes; d++) {
      final data = DateTime(_month.year, _month.month, d);
      final k = _dayKey(data);
      final doDia = notas[k];
      final isHoje = data.year == hoje.year &&
          data.month == hoje.month &&
          data.day == hoje.day;
      cells.add(_diaCell(d, data, doDia, isHoje));
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: AppColors.muted),
                tooltip: 'Mês anterior',
                onPressed: () => _mudaMes(-1),
              ),
              Expanded(
                child: Text(
                  '${_meses[_month.month - 1]} de ${_month.year}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right,
                    color: _noMesAtual ? AppColors.line : AppColors.muted),
                tooltip: 'Próximo mês',
                onPressed: _noMesAtual ? null : () => _mudaMes(1),
              ),
            ],
          ),
          Row(
            children: [
              for (final d in _semana)
                Expanded(
                  child: Text(d,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: cells,
          ),
        ],
      ),
    );
  }

  Widget _diaCell(
      int d, DateTime data, List<BabyEvent>? doDia, bool isHoje) {
    final tem = doDia != null && doDia.isNotEmpty;
    return GestureDetector(
      onTap: tem ? () => _abreDia(data, doDia) : null,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tem ? kNotaColor.withValues(alpha: kIsDark ? 0.28 : 0.16) : null,
          shape: BoxShape.circle,
          border: isHoje
              ? Border.all(color: AppColors.accent, width: 1.5)
              : (tem
                  ? Border.all(
                      color: kNotaColor.withValues(alpha: 0.8), width: 1)
                  : null),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$d',
                style: TextStyle(
                  color: tem ? AppColors.ink : AppColors.muted,
                  fontSize: 13,
                  fontWeight: tem ? FontWeight.w800 : FontWeight.w500,
                )),
            if (tem)
              Icon(Icons.favorite, size: 8, color: kNotaColor)
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---- notas de um dia ----

  Future<void> _abreDia(DateTime data, List<BabyEvent> doDia) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite, size: 18, color: kNotaColor),
                  const SizedBox(width: 8),
                  Text(longDayLabel(data),
                      style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: doDia.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 14, color: AppColors.line),
                  itemBuilder: (_, i) => _notaRow(ctx, doDia[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) setState(() {}); // reflete edição/exclusão no calendário
  }

  Widget _notaRow(BuildContext sheetCtx, BabyEvent e) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        Navigator.pop(sheetCtx);
        await showNotaSheet(context, event: e);
        if (mounted) setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fmtH(e.ts),
                style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(e.note ?? '',
                  style: TextStyle(
                      color: AppColors.ink, fontSize: 13.5, height: 1.5)),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 18, color: AppColors.qBad),
              tooltip: 'Apagar nota',
              onPressed: () => _apagar(sheetCtx, e),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _apagar(BuildContext sheetCtx, BabyEvent e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Apagar nota?'),
        content: Text(
          (e.note ?? '').length > 80
              ? '${e.note!.substring(0, 80)}…'
              : (e.note ?? ''),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.qBad),
              onPressed: () => Navigator.pop(dctx, true),
              child: const Text('Apagar')),
        ],
      ),
    );
    if (ok == true) {
      await AppStore.I.deleteEvent(e.id);
      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
      if (mounted) setState(() {});
    }
  }

  // ---- rodapé ----

  Widget _vazio() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('💛', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text(
            'Nenhuma nota ainda.\nEscreva a primeira: uma conquista, uma '
            'lembrança, como o dia foi. Daqui a um ano você vai amar reler.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.muted, fontSize: 13.5, height: 1.6),
          ),
        ],
      ),
    );
  }

  /// As 3 notas mais recentes, pra não depender só do calendário.
  Widget _ultimas(Map<String, List<BabyEvent>> notas) {
    final todas = notas.values.expand((l) => l).toList()
      ..sort((a, b) => b.ts.compareTo(a.ts));
    final top = todas.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 8),
          child: Text('ÚLTIMAS NOTAS',
              style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              for (var i = 0; i < top.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, indent: 16, color: AppColors.line),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    await showNotaSheet(context, event: top[i]);
                    if (mounted) setState(() {});
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${longDayLabel(top[i].ts)} · ${fmtH(top[i].ts)}',
                          style: TextStyle(
                              color: kNotaColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(top[i].note ?? '',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 13,
                                height: 1.45)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
