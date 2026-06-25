# Como subir e gerar o app

Você não precisa entender o código. São 2 passos: subir o projeto pro GitHub, e o GitHub gera o arquivo do app sozinho.

## Passo 1 — subir pro GitHub

Cole isto no Claude Code (ele roda na pasta do projeto). Cria o repositório e sobe tudo:

```bash
cd "OUTPUTS/diario-do-bebe-app"
git init -b main
git add .
git commit -m "App nativo: notificacao fixa + login (v1)"
gh repo create diario-do-bebe-app --public --source=. --remote=origin --push
```

Assim que subir, o GitHub já começa a montar o arquivo do app sozinho.

**Se o repositório já existe** (você já subiu antes), é só mandar as mudanças:

```bash
cd "OUTPUTS/diario-do-bebe-app"
git add .
git commit -m "Visual fiel ao site, gráficos e tela de bloqueio"
git push
```

## Passo 2 — pegar o arquivo do app (APK)

Duas formas:

**Pra testar agora (qualquer push):**
abra o repositório no GitHub → aba **Actions** → clique na execução mais recente (a do topo) → role até **Artifacts** → baixe `diario-do-bebe-apk`.

**Versão "de verdade" com link fixo:**
cole no Claude Code pra marcar uma versão:

```bash
git tag v1.1.0
git push origin v1.1.0
```

O arquivo aparece na aba **Releases** do repositório, com link fixo pra baixar e reinstalar quando quiser. Toda vez que você (ou eu) mudar algo, é só repetir com `v1.0.1`, `v1.0.2`, etc.

## Passo 3 — instalar no celular

1. Baixe o `.apk` pelo celular (pelo link do Actions ou do Releases).
2. Abra o arquivo. O Android vai pedir pra permitir "instalar app de fonte desconhecida" — permite.
3. Instale, abra o app, entre com o **mesmo email e senha** do app web.
4. Na tela inicial, ligue **"Botões fixos na tela de bloqueio"**. O Android vai pedir permissão de notificação e pra ignorar a economia de bateria — aceite os dois (sem isso a notificação some).
5. Trave o celular e confira: a notificação com Soneca, Mamada e Despertar tem que aparecer na tela de bloqueio, e tocar grava sem desbloquear.

## Se o primeiro build falhar

É normal numa primeira compilação de app nativo. Vá na aba **Actions**, abra a execução vermelha, copie o texto do erro e me manda aqui. Eu conserto e você repete o Passo 2.
