# Diário do Bebê — app nativo (Android)

App nativo pra registrar a rotina do bebê com um toque. O pulo do gato em relação ao app web: uma **notificação fixa** com botões que ficam na barra e na tela de bloqueio, e gravam direto mesmo com o app fechado e sem desbloquear o celular.

Mesmo backend do app web (Supabase). Os dados são os mesmos: quem já usa o web entra com a mesma conta e vê o mesmo histórico.

## O que faz

- **Notificação fixa de layout customizado** (estilo CamScanner): 4 botões com ícone redondo colorido e rótulo — Soneca, Mamada, Refeição, Despertar. Soneca/Mamada/Despertar gravam na hora, mesmo pela tela bloqueada; Refeição abre a ficha no app (precisa de quantidade e quem serviu). Sessão aberta vira cronômetro no título da notificação e o rótulo do botão muda (ex.: Soneca → Acordou).
- **5 registros** dentro do app: soneca, mamada, despertar e sono noturno (começa/termina) e refeição (quanto comeu + quem serviu).
- **Login** por email/senha, mesma conta do app web.
- **Histórico** agrupado pelo dia do ciclo do bebê (do acordar ao acordar; corte às 5h quando não há sono pra ancorar).

## Stack

- **Flutter** (a casca nova). Reaproveita 100% do backend.
- **Supabase** (Postgres + Auth + RLS por `user_id`), o mesmo do app web.
- **Serviço nativo em Kotlin** (`native/`) pra notificação fixa: RemoteViews customizado, tipo `specialUse`, gravação direta na REST do Supabase com refresh de token (mesma lógica do `events_repo.dart`, portada pra `SupabaseApi.kt`). A pasta `native/` é copiada pra dentro de `android/` pelo `tool/patch_android.py` na build.

## Como vira um arquivo instalável

Você não compila nada na sua máquina. O **GitHub Actions** compila o APK na nuvem a cada push (arquivo `.github/workflows/build-apk.yml`):

1. Gera a estrutura Android com `flutter create`.
2. Injeta o código nativo, as permissões, o serviço e as dependências (`tool/patch_android.py` copia a pasta `native/` pra dentro).
3. Roda `flutter build apk --release` (assinado com a chave de debug, suficiente pra instalar por link).
4. Sobe o APK em **Artifacts** (toda execução) e em **Releases** (quando você cria uma tag `v*`).

A pasta `android/` é gerada na nuvem e não fica no repositório (está no `.gitignore`), pra ficar sempre alinhada com a versão do Flutter do build.

## Instalar no celular

- Build de teste: aba **Actions** do repositório → última execução → baixar o artifact `diario-do-bebe-apk`.
- Versão "de verdade": crie uma tag (`git tag v1.0.1 && git push --tags`); o APK aparece em **Releases** com link fixo.
- No Android: abrir o arquivo `.apk`, permitir "instalar de fonte desconhecida", instalar. Abrir o app, entrar, e em **Botões fixos na tela de bloqueio** ligar a notificação.

## Tela de bloqueio (o ponto principal)

A notificação usa um canal de importância DEFAULT (`diario_bebe_botoes_v3`) e visibilidade pública, que é o que faz ela aparecer na tela de bloqueio. Como a importância de um canal só é definida na primeira criação, o id do canal muda a cada mudança de configuração: ao instalar a versão nova, o canal é recriado já com a configuração certa.

Os botões grandes aparecem na notificação **expandida**. Na tela de bloqueio, se ela vier recolhida, arrasta pra baixo pra expandir; a maioria dos aparelhos lembra o estado.

Se mesmo assim não aparecer na tela de bloqueio, é configuração do sistema (varia por fabricante). Confira:

- Permissão de notificação concedida ao app, e bateria sem otimização (o app pede os dois ao ligar o toggle).
- Ajustes do Android → Notificações → Notificações na tela de bloqueio → "Mostrar tudo".
- Nos ajustes do app → canal "Diário do Bebê (botões fixos)" → tela de bloqueio = mostrar conteúdo.

## Visual

Mesma identidade do app web (tema azul-marinho, três abas), com a home repaginada: resumo do dia em 2x2 com número grande e a última mamada em destaque, painel de registro em grid 2 colunas com botões grandes, ícones desenhados no lugar dos emojis (mesma família da notificação), animação de toque com haptic, e snackbar com Desfazer nos registros. Gráficos (linha, barra e rosca) com `fl_chart`, espelhando os do site.

## Configurações

No ícone de engrenagem (canto da home): editar perfil do bebê (nome, foto pela câmera ou galeria, data de nascimento, nome da mãe), trocar o formato de hora (24h ou AM/PM, afeta todo o app), ligar/desligar a notificação fixa, e sair da conta.

A foto é guardada no perfil (base64), compatível com o app web. O formato de hora fica salvo no aparelho.

## Editar e apagar registro

No Histórico: tocar num registro abre a edição de horário (início e, nas sessões, o fim) pra corrigir um lançamento feito atrasado. Arrastar pro lado apaga.

## Já feito vs. próximo

Feito: login, os 5 registros, notificação customizada com 4 botões de ícone (grava pela tela bloqueada, Refeição abre a ficha, cronômetro de sessão), home em grid com ícones e resumo grande, abas Hoje/Histórico/Estatísticas, gráficos de tendência e por horário, seletor de período, configurações (perfil + foto + formato de hora), editar e apagar registro, Desfazer, religa sozinha após reiniciar o celular, ícone próprio do app, build automática.

O limite antigo (botão de notificação só texto) caiu: o layout customizado (RemoteViews) desenha os botões redondos coloridos, igual apps de scanner fazem.

Próximo: widget na tela inicial com os botões (superfície nativa separada, feita num passo dedicado). Mais pra frente, se valer: lembrete de intervalo, exportar CSV, desfazer pela notificação.

## Privacidade

A chave `sb_publishable_` no código é pública por design; a proteção real do dado é a RLS por conta no Supabase. Senha do banco e chave secreta não ficam no repositório.
