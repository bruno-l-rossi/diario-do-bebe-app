# DESIGN.md — Diário do Bebê (app nativo)

Sistema visual adaptado do DESIGN-meta.md (análise do design da Meta) pro nosso mundo: mães e responsáveis de bebês, uma mão só, muitas vezes de madrugada. Pegamos a estrutura de lá (botões pílula, cartões bem arredondados, borda hairline de 1px, elevação flat, UMA cor de ação usada com parcimônia, hierarquia de texto enxuta) e trocamos o clima: em vez de branco estéril de loja, superfícies quentes e acolhedoras.

A fonte da verdade dos tokens é `lib/theme.dart` (classe `Palette` + `AppRadius`).

## Tom

Calmo e aconchegante. O app é usado no escuro com o bebê no colo E de dia com uma mão só. Tudo grande, tudo num toque, nada escondido em gesto. O foco é o botão certo aparecer rápido.

## Os dois modos

O app segue o modo do celular (claro/escuro), trocado em tempo real:

- **Dia (claro)**: branco quente `#FAF6F1` (não estéril), cartões brancos, tinta café `#33302B`, hairline areia `#EAE2D8`. Pastéis com contraste pra cada tipo de registro.
- **Madrugada (escuro)**: o azul-marinho de sempre, `#0D1B2A` (base) e `#16263A` (cartões), texto `#EEF4FB`.

Cor de ação (o "cobalto" do sistema Meta, adaptado): azul mais quente, `#4E7DE0` no claro e `#6C93F2` no escuro. Regra herdada de lá: essa cor é só pra ação principal (botão de salvar, aba ativa, seletor ativo). Se ela começar a aparecer em todo lugar, perdeu o sentido.

Acentos por tipo de registro (diferenciar num olhar; versão clara / escura):

- Soneca: `#4A7CD6` / `#6FA8FF`
- Sono noturno: `#6B77D9` / `#8A9BFF`
- Mamada: `#C97F2E` / `#E6A866`
- Refeição: `#55963F` / `#86CF73`
- Despertar: `#9A64BE` / `#C79BE0`
- Nota do dia: `#C75FA5` / `#E29AD0`

Cada tipo tem também um "dot" (fundo do ícone): pastel clarinho no modo claro, tom profundo no escuro.

## Geometria (assinatura do sistema)

Escala de raios (`AppRadius`): input 14 · cartão 20 · cartão-destaque/sheet 24 · pílula 100.

- **Botões sempre pílula** (`StadiumBorder`). Nunca quadrados: vale pra FilledButton, TextButton, chips e o indicador da barra de navegação.
- **Cartões 20-24px** de raio, borda hairline de 1px na cor `line`, sem sombra. Elevação é flat; profundidade vem de cor, não de sombra.
- **Seletores segmentados** (período das estatísticas, formato de hora) são trilhos-pílula com o segmento ativo preenchido na cor de ação e texto `onAccent`.
- **Inputs** com 14px de raio, preenchidos com a cor do cartão, foco na cor de ação com 2px.

## Tipografia

Fonte do sistema (Roboto no Android), sem fonte importada, pra abrir rápido. Hierarquia de 3 níveis por tela: título grande e pesado (w700/w800), corpo normal, apoio menor na cor `muted`. Números grandes nas estatísticas em w800 na cor de ação.

## Layout

- Home: foto do bebê, saudação com o nome da mãe, idade. Resumo do dia 2x2 com número grande e última mamada em destaque. Painel de registro em grid 2 colunas + Sono noturno e Nota do dia em faixa cheia. Sessão aberta muda o rótulo e mostra o tempo correndo.
- Ícones desenhados (lua, copo, talheres, estrelas, coração) no lugar de emoji nos botões: emoji muda por aparelho e quebra a identidade. Mesma família visual no app e na notificação.
- Notificação fixa: layout customizado (RemoteViews) com 4 botões de ícone redondo colorido, única notificação do app, always-on.
- Histórico: um card por dia com resumo no cabeçalho e linhas com divisória; toque abre as ações (editar/apagar).
- Micro: animação de escala no toque, haptic ao registrar, snackbar flutuante com Desfazer.

## Regras herdadas do DESIGN-meta (e as que adaptamos)

Herdadas: pílula em todo botão; cor de ação escassa; cartões arredondados com hairline; flat sem sombra decorativa; hierarquia de texto enxuta; uma família tipográfica só.

Adaptadas de propósito (nosso público não é loja de hardware):

- Canvas quente em vez de branco puro; o app precisa abraçar, não vender.
- Modo escuro é cidadão de primeira classe (o sistema da Meta nem define tokens dark): madrugada é metade da vida deste app.
- Em vez de monocromático + 1 accent, mantemos os 6 acentos pastéis por tipo de registro; mãe cansada diferencia botão por cor, não por rótulo.
- Nada de banner promocional, badge de urgência ou dual-CTA de marketing. Um app de diário não vende nada.

## Ícone

O emoji do bebê 👶 (arte Twemoji, vetor) sobre o azul-marinho `#0D1B2A`. Nome embaixo do ícone: "Diário do Bebê" (injetado no manifest pelo `tool/patch_android.py`).

## Princípio

Um toque resolve. Se um registro pede mais de um toque (refeição, nota), abre uma ficha curta; o resto grava na hora, mesmo pela tela bloqueada.
