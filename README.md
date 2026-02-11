# claude-workflows

Workflow GitHub Actions riutilizzabili per l'integrazione di Claude nei tuoi repository.

## Workflow disponibili

### 1. Interactive @claude

Permette ai collaboratori di menzionare `@claude` nelle issue e PR per:
- **Chiedere delucidazioni** sul codice o su una parte del progetto
- **Segnalare bug** — Claude rielabora la segnalazione in un prompt strutturato
- **Proporre feature/implementazioni** — Claude analizza la proposta e crea un prompt pronto per Claude Code locale

> Claude su GitHub **non scrive codice**: rielabora i commenti dei collaboratori in prompt ben strutturati, pronti per essere presi in carico da Claude Code (CC) in locale.

### 2. PRD to CLAUDE.md

Si attiva automaticamente quando vengono pushati file nella cartella `.claude/prds/` del tuo repo. Claude:
- Analizza i file PRD (Product Requirements Document)
- Analizza il codebase esistente
- Genera/aggiorna il `CLAUDE.md` del progetto con le istruzioni specifiche

## Setup rapido

### Prerequisiti

1. **Claude GitHub App** installata sul tuo account ([installa qui](https://github.com/apps/claude))
2. **GitHub CLI (gh)** installato (`brew install gh`)
3. **ANTHROPIC_API_KEY** — configurata come secret nel repo:
   ```bash
   gh secret set ANTHROPIC_API_KEY --repo tuo-utente/tuo-repo
   ```

### Installazione con script

Dalla root del tuo repository:

```bash
curl -sL https://raw.githubusercontent.com/Polloinfilzato/claude-workflows/main/setup-claude.sh | bash
```

Lo script ti chiederà quali workflow attivare e genererà automaticamente i file necessari.

### Installazione manuale

Copia i template dalla cartella `templates/` nel tuo repo:

```bash
# Interactive @claude
mkdir -p .github/workflows
curl -sL https://raw.githubusercontent.com/Polloinfilzato/claude-workflows/main/templates/claude-interactive.yml \
  -o .github/workflows/claude-interactive.yml

# PRD to CLAUDE.md
curl -sL https://raw.githubusercontent.com/Polloinfilzato/claude-workflows/main/templates/claude-prd.yml \
  -o .github/workflows/claude-prd.yml
mkdir -p .claude/prds
```

Poi commit e push:

```bash
git add .github/workflows/ .claude/
git commit -m "chore: setup Claude workflows"
git push
```

## Come funziona

### Interactive @claude

```
Collaboratore scrive su Issue #42:
  "@claude ho notato che il login non funziona su mobile"
      │
      ▼
  Claude analizza il commento + il codebase
      │
      ▼
  Claude scrive un prompt strutturato nell'issue:
  🎯 [Bug]: Session persistence su mobile
  File coinvolti: src/auth/session.ts, src/middleware/cookies.ts
  Checklist: [...]  Priorità: high
      │
      ▼
  Label "ready-for-cc" aggiunta all'issue
      │
      ▼
  Tu sincronizzi con CC locale → implementi con i tuoi token
```

### PRD to CLAUDE.md

```
Tu crei .claude/prds/requirements.md → git push
      │
      ▼
  Workflow triggerato automaticamente
      │
      ▼
  Claude legge PRD + analizza codebase
      │
      ▼
  CLAUDE.md generato/aggiornato con:
  - Stack tecnologico
  - Struttura progetto
  - Convenzioni
  - Istruzioni per @claude su GitHub
```

## Struttura del repository

```
claude-workflows/
├── .github/workflows/
│   ├── interactive-claude.yml   ← Workflow riutilizzabile: @claude
│   └── prd-to-claude-md.yml    ← Workflow riutilizzabile: PRD → CLAUDE.md
├── templates/
│   ├── claude-interactive.yml   ← Template per i tuoi repo
│   └── claude-prd.yml           ← Template per i tuoi repo
├── setup-claude.sh              ← Script di setup automatico
└── README.md
```

## Personalizzazione

### Modificare il comportamento di @claude per un progetto specifico

Aggiungi istruzioni nel `CLAUDE.md` del singolo repo:

```markdown
## Istruzioni per @claude su GitHub
- In questo progetto usiamo TypeScript strict mode
- Nelle checklist includi sempre il passo di testing con Vitest
- I file di test vanno nella cartella __tests__/
```

### Modificare i parametri del workflow

Nel file `.github/workflows/claude-interactive.yml` del tuo repo:

```yaml
jobs:
  claude:
    uses: Polloinfilzato/claude-workflows/.github/workflows/interactive-claude.yml@main
    secrets:
      anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
    with:
      max_turns: "15"            # Più turni per richieste complesse
      trigger_phrase: "@ai"      # Trigger personalizzato
```

## Costi

- **Interactive @claude**: Pochi token per ogni interazione (solo rielaborazione testo, no code generation)
- **PRD to CLAUDE.md**: Token moderati per l'analisi iniziale del codebase (si attiva solo quando pushi PRD)
- Tutti i costi sono a carico dell'API key Anthropic configurata nel secret
