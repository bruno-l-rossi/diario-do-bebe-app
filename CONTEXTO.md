# CONTEXTO.md — pra retomar o desenvolvimento

Leia isto (e o README + DESIGN.md) antes de mexer no projeto. Atualizado na v1.8.0 (jul/2026).

## O que é

App Android nativo (Flutter + serviço Kotlin) pra registrar a rotina de um bebê num toque. Irmão do app web (PWA na pasta `OUTPUTS/diario-do-bebe`); mesmo backend Supabase, mesma conta, mesmos dados. O diferencial do nativo é a notificação fixa com botões que gravam pela tela de bloqueio.

## Estado atual (v1.8.0+9)

Funciona de ponta a ponta: login/cadastro com fluxo de boas-vindas (mãe → bebê → foto), tour de 4 telas no primeiro login, home com registro num toque (5 tipos + nota do dia), notificação fixa always-on (única do app, reposta sozinha se sumir), histórico em card por dia com editar/apagar no toque, aba Notas com calendário mensal (dias com nota clicáveis, editar/apagar, últimas 3 notas), estatísticas que abrem com 7 dias de dados (resumo em frases, tendência vs período anterior, linha do tempo 24h), ajuda com tutorial + email, tema claro/escuro seguindo o celular.

Navegação: 4 abas (Hoje, Histórico, Notas, Estatísticas). A aba Notas (`lib/screens/notas_tab.dart`) agrupa por data civil (não pelo "dia do bebê"): nota é lembrança do dia em que foi escrita.

## Arquitetura em 1 minuto

- `lib/main.dart`: AuthGate decide login → boas-vindas (perfil sem bebê) → tour (1ª vez no aparelho) → home. BabyApp observa o brilho do sistema e troca a paleta.
- `lib/data/store.dart` (AppStore): singleton ChangeNotifier, carrega events + profile do Supabase, calcula "dia do bebê" (acordar → acordar, corte 5h) e sono líquido.
- `lib/services/events_repo.dart`: REST direto no Supabase com refresh de token. O Kotlin (`native/kotlin/SupabaseApi.kt`) replica essa lógica pra notificação gravar com o app fechado.
- `lib/theme.dart`: design system. `Palette` (kDarkPalette/kLightPalette), `AppColors` são GETTERS da paleta ativa (`kP`). REGRA DURA: cor nunca entra em expressão `const` — quebra a build. `setPaletteFor(brightness)` troca; a key em `main.dart` remonta a árvore.
- `native/`: NotifService (notificação RemoteViews, canal `diario_bebe_botoes_v3`, watchdog reposta a cada 10min), MainActivity (MethodChannel `diario/notif`), BootReceiver. Copiado pra `android/` na build pelo `tool/patch_android.py`, que também injeta permissões, queries de mailto e o label "Diário do Bebê".
- Build: sem Android local. GitHub Actions (`.github/workflows/build-apk.yml`) roda `flutter create` + patch + build a cada push; APK em Actions → Artifacts, e em Releases quando há tag `v*`.

## Backend (Supabase, projeto `diario-bebe`, id xvydkvqfcgfysrkmzsae)

- Tabelas: `events` (id, user_id, type, ts, end_ts, quality, served_by, note) e `profiles` (user_id, baby_name, baby_birth, mother_name, baby_photo base64).
- `events.type` tem CHECK: soneca | mamada | refeicao | despertar | sono | nota (o tipo `nota` entrou na migração `add_nota_event_type`, jul/2026).
- RLS por user_id. A chave `sb_publishable_` no código é pública por design.
- ATENÇÃO: o app web lê os mesmos events; se mexer no schema, conferir se o web não quebra (eventos `nota` no web ainda não têm render próprio).

## Decisões que não são óbvias

- Estatísticas só abrem com 7 dias de dados distintos (decisão do Bruno: análise com pouco dado engana). Antes disso, card de progresso "dia X de 7".
- `nota` fica fora de TODA análise e gráfico. É diário, memória. `kTypeColor` não tem 'nota' de propósito (é o que filtra a linha do tempo).
- Histórico sem gesto escondido: apagar/editar é por toque + menu, decisão de usabilidade pra mãe cansada.
- Notificação: importância de canal só se define na criação, então mudança de config de canal = trocar o id (`_v3` → `_v4`...).
- Identidade: estética adaptada do DESIGN-meta.md (pílulas, cartões 20-24px, hairline, flat, 1 cor de ação escassa), mas quente e com modo escuro de primeira classe. Ver DESIGN.md.
- Tom dos textos: acolhedor, direto, sem corporativês. Contato: rideblan33@caramujorecords.com.br.

## Como buildar e publicar

Ver COMANDOS.md. Resumo: commit + push (Actions gera APK de teste) e tag `vX.Y.Z` (gera Release com link fixo). Versão em `pubspec.yaml` (formato X.Y.Z+build, incrementar os dois).

## Backlog (por ordem de valor/esforço)

1. Widget de home screen com os botões (superfície nativa própria).
2. Exportar resumo pro pediatra (CSV/PDF do histórico).
3. Crescimento: peso/altura com curva de percentil OMS.
4. Previsão da próxima soneca (janela média acordado, estilo SweetSpot do Huckleberry).
5. Segundo cuidador na mesma conta do bebê (mexe no RLS; maior diferencial do mercado, ver Pebbi).
6. Render do tipo `nota` no app web.

## Pastas irmãs

- `OUTPUTS/diario-do-bebe`: o app web/PWA (repo próprio, tem CONTEXTO.md dele).
- `DESIGN-meta.md`: análise do design system da Meta que serviu de referência visual. Não é o design do app; o do app é DESIGN.md.
