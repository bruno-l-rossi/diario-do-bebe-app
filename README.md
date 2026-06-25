# Diário do Bebê — app nativo (Android)

App nativo pra registrar a rotina do bebê com um toque. O pulo do gato em relação ao app web: uma **notificação fixa** com botões que ficam na barra e na tela de bloqueio, e gravam direto mesmo com o app fechado e sem desbloquear o celular.

Mesmo backend do app web (Supabase). Os dados são os mesmos: quem já usa o web entra com a mesma conta e vê o mesmo histórico.

## O que faz

- **Notificação fixa** com 3 botões: Soneca, Mamada, Despertar. Tocar grava na hora, mesmo pela tela bloqueada (serviço em primeiro plano, tipo `specialUse`, sem o timeout de 6h do `dataSync`).
- **5 registros** dentro do app: soneca, mamada, despertar e sono noturno (começa/termina) e refeição (quanto comeu + quem serviu).
- **Login** por email/senha, mesma conta do app web.
- **Histórico** agrupado pelo dia do ciclo do bebê (do acordar ao acordar; corte às 5h quando não há sono pra ancorar).

Refeição e Sono não entram como botão da notificação: refeição precisa de mais toques (quantidade e quem serviu), então abre o app.

## Stack

- **Flutter** (a casca nova). Reaproveita 100% do backend.
- **Supabase** (Postgres + Auth + RLS por `user_id`), o mesmo do app web.
- **flutter_foreground_task** pra notificação fixa com botões.
- Gravação no Supabase pela REST, com refresh de token, pra funcionar também no isolate do serviço (igual o service worker fazia no PWA).

## Como vira um arquivo instalável

Você não compila nada na sua máquina. O **GitHub Actions** compila o APK na nuvem a cada push (arquivo `.github/workflows/build-apk.yml`):

1. Gera a estrutura Android com `flutter create`.
2. Injeta as permissões e o serviço da notificação (`tool/patch_android.py`).
3. Roda `flutter build apk --release` (assinado com a chave de debug, suficiente pra instalar por link).
4. Sobe o APK em **Artifacts** (toda execução) e em **Releases** (quando você cria uma tag `v*`).

A pasta `android/` é gerada na nuvem e não fica no repositório (está no `.gitignore`), pra ficar sempre alinhada com a versão do Flutter do build.

## Instalar no celular

- Build de teste: aba **Actions** do repositório → última execução → baixar o artifact `diario-do-bebe-apk`.
- Versão "de verdade": crie uma tag (`git tag v1.0.1 && git push --tags`); o APK aparece em **Releases** com link fixo.
- No Android: abrir o arquivo `.apk`, permitir "instalar de fonte desconhecida", instalar. Abrir o app, entrar, e em **Botões fixos na tela de bloqueio** ligar a notificação.

## Tela de bloqueio (o ponto principal)

A notificação usa um canal de importância DEFAULT (`diario_bebe_lockscreen_v2`) e visibilidade pública, que é o que faz ela aparecer na tela de bloqueio. Como a importância de um canal só é definida na primeira criação, mudei o id do canal: ao instalar a versão nova, o canal é recriado já com a configuração certa.

Se mesmo assim não aparecer na tela de bloqueio, é configuração do sistema (varia por fabricante). Confira:

- Permissão de notificação concedida ao app, e bateria sem otimização (o app pede os dois ao ligar o toggle).
- Ajustes do Android → Notificações → Notificações na tela de bloqueio → "Mostrar tudo".
- Nos ajustes do app → canal "Diário do Bebê (botões fixos)" → tela de bloqueio = mostrar conteúdo.

## Visual

Mesma identidade do app web: tema azul-marinho, três abas (Hoje, Histórico, Estatísticas), cards de registro coloridos por tipo, cards de sessão em andamento com cronômetro, e os gráficos (linha, barra e rosca) com `fl_chart`, espelhando os do site.

## Configurações

No ícone de engrenagem (canto da home): editar perfil do bebê (nome, foto pela câmera ou galeria, data de nascimento, nome da mãe), trocar o formato de hora (24h ou AM/PM, afeta todo o app), ligar/desligar a notificação fixa, e sair da conta.

A foto é guardada no perfil (base64), compatível com o app web. O formato de hora fica salvo no aparelho.

## Editar e apagar registro

No Histórico: tocar num registro abre a edição de horário (início e, nas sessões, o fim) pra corrigir um lançamento feito atrasado. Arrastar pro lado apaga.

## Já feito vs. próximo

Feito: login, os 5 registros, notificação fixa com os 3 botões (texto colorido) na tela de bloqueio, abas Hoje/Histórico/Estatísticas fiéis ao site, gráficos de tendência e por horário, seletor de período, configurações (perfil + foto + formato de hora), editar e apagar registro, ícone próprio do app, build automática.

Limite da notificação (do Android, não do app): os botões de notificação são texto, não dá pra fazer botão redondo grande colorido. O que dá, e está feito, é colorir o texto de cada botão com a cor do tipo.

Próximo: widget na tela inicial com os botões (superfície nativa separada, feita num passo dedicado). Mais pra frente, se valer: lembrete de intervalo, exportar CSV, desfazer pela notificação.

## Privacidade

A chave `sb_publishable_` no código é pública por design; a proteção real do dado é a RLS por conta no Supabase. Senha do banco e chave secreta não ficam no repositório.
