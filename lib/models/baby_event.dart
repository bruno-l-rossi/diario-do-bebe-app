/// Um registro do diário, espelho da linha da tabela `events` no Supabase.
class BabyEvent {
  final String id;
  final String type; // soneca | sono | mamada | refeicao | despertar
  final DateTime ts; // início (local)
  final DateTime? end; // fim, nas sessões (local)
  final int? quality; // 0..3, só refeição
  final String? served; // mae | pai | outro, só refeição
  final String? note;

  BabyEvent({
    required this.id,
    required this.type,
    required this.ts,
    this.end,
    this.quality,
    this.served,
    this.note,
  });

  bool get isSession =>
      type == 'soneca' || type == 'sono' || type == 'mamada' || type == 'despertar';

  Duration? get duration => end == null ? null : end!.difference(ts);

  factory BabyEvent.fromRow(Map<String, dynamic> r) {
    DateTime? p(dynamic v) =>
        v == null ? null : DateTime.parse(v as String).toLocal();
    return BabyEvent(
      id: r['id'] as String,
      type: r['type'] as String,
      ts: p(r['ts'])!,
      end: p(r['end_ts']),
      quality: r['quality'] as int?,
      served: r['served_by'] as String?,
      note: r['note'] as String?,
    );
  }
}
