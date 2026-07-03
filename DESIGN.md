# DESIGN.md — Diário do Bebê (app nativo)

A identidade vem do app que já está no ar. Nada de redesenho: o nativo tem que parecer o mesmo app, só que cravado no celular. Quem já usa o PWA não pode estranhar.

## Tom

Calmo, noturno, de madrugada. O app é usado no escuro, com uma mão, com o bebê no colo. Tudo grande, tudo num toque. Sem firula, sem tela cheia de opção. O foco é o botão certo aparecer rápido.

## Cores

- Fundo: azul-marinho escuro, quase preto. `#0B1220` (base) e `#111A2E` (cartões).
- Texto: branco suave `#E8ECF4`, secundário `#9AA7BE`.
- Destaque (ações, botões): azul `#4F7DF0`.
- Acentos por tipo de registro (para diferenciar os botões num olhar):
  - Soneca: `#7AA2F7` (azul claro)
  - Mamada: `#9ECE6A` (verde)
  - Despertar: `#E0AF68` (âmbar)
  - Sono noturno: `#7DCFFF` (azul gelo)
  - Refeição: `#BB9AF7` (lilás)
- Lua e estrelas no ícone, no tema escuro (igual ao ícone atual `icon-512.png`).

## Tipografia

Fonte do sistema (Roboto no Android). Sem fonte importada, pra abrir rápido. Tamanhos generosos: título da home grande, botões com texto legível de longe.

## Layout

- Home: foto do bebê, saudação pela hora, idade. Resumo do dia em 2x2 (número grande) com a última mamada em destaque. Painel de registro em grid 2 colunas: Soneca, Mamada, Refeição, Despertar (mesma ordem da notificação) + Sono noturno em faixa cheia. Sessão aberta muda o rótulo do botão e mostra o tempo correndo.
- Ícones desenhados (lua, copo, talheres, estrelas) no lugar de emoji: emoji muda por aparelho e quebra a identidade. Mesma família visual no app e na notificação.
- Notificação fixa: layout customizado (RemoteViews) com 4 botões de ícone redondo colorido e rótulo embaixo, estilo CamScanner. Título mostra a sessão aberta com cronômetro. Refeição abre a ficha no app.
- Histórico: lista por dia (ciclo do bebê, do acordar ao acordar), agrupada, com hora e duração.
- Micro: animação de escala no toque, haptic ao registrar, snackbar com Desfazer.

## Princípio

Um toque resolve. Se um registro pede mais de um toque (refeição, que pede quanto comeu e quem serviu), ele abre o app; o resto grava na hora, mesmo pela tela bloqueada.
