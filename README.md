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

## Já feito vs. próximo

Nesta v1 do nativo: login, os 5 registros, notificação fixa com os 3 botões, histórico, build automática.

Fora desta v1 (puxar do app web depois, se valer): os gráficos de tendência (Chart.js no web), o seletor de período nas estatísticas, foto de perfil do bebê e o formato de hora 24h/AM-PM. O app web segue no ar com tudo isso enquanto o nativo amadurece.

## Privacidade

A chave `sb_publishable_` no código é pública por design; a proteção real do dado é a RLS por conta no Supabase. Senha do banco e chave secreta não ficam no repositório.
