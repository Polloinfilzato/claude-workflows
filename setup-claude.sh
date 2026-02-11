#!/bin/bash

# ============================================================
# Setup Claude Workflows
# Genera i file workflow per integrare Claude nel tuo repo
#
# Uso: curl -sL https://raw.githubusercontent.com/Polloinfilzato/claude-workflows/main/setup-claude.sh | bash
# Oppure: ./setup-claude.sh (dalla cartella del tuo repo)
# ============================================================

set -e

REPO_URL="https://raw.githubusercontent.com/Polloinfilzato/claude-workflows/main/templates"
WORKFLOW_DIR=".github/workflows"

# Colori
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo ""
echo -e "${BLUE}${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}${BOLD}║      Setup Claude Workflows              ║${NC}"
echo -e "${BLUE}${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""

# Verifica che siamo in un repo git
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo -e "${RED}Errore: non sei in un repository Git.${NC}"
    echo "Esegui questo script dalla root del tuo progetto."
    exit 1
fi

# Verifica che gh sia installato
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Errore: gh (GitHub CLI) non è installato.${NC}"
    echo "Installalo con: brew install gh"
    exit 1
fi

# Mostra il repo corrente
CURRENT_REPO=$(basename "$(git rev-parse --show-toplevel)")
echo -e "Repository corrente: ${BOLD}${CURRENT_REPO}${NC}"
echo ""

# Menu di selezione workflow
echo -e "${YELLOW}Quali workflow vuoi attivare?${NC}"
echo ""
echo "  [1] Interactive @claude"
echo "      I collaboratori possono citare @claude nelle issue/PR"
echo "      per chiedere delucidazioni o proporre implementazioni."
echo "      Claude rielabora i commenti in prompt strutturati."
echo ""
echo "  [2] PRD to CLAUDE.md"
echo "      Quando pushi file in .claude/prds/, Claude analizza"
echo "      i requisiti e genera automaticamente il CLAUDE.md di progetto."
echo ""
echo "  [3] Entrambi (consigliato)"
echo ""

read -p "Scegli (1/2/3): " choice < /dev/tty

# Validazione input
case $choice in
    1|2|3) ;;
    *)
        echo -e "${RED}Scelta non valida. Usa 1, 2 o 3.${NC}"
        exit 1
        ;;
esac

# Crea directory workflow se non esiste
mkdir -p "$WORKFLOW_DIR"
echo ""

# Funzione per scaricare e installare un template
install_workflow() {
    local template_name="$1"
    local target_name="$2"
    local description="$3"

    echo -e "${BLUE}→ Installando: ${description}...${NC}"

    if [ -f "${WORKFLOW_DIR}/${target_name}" ]; then
        read -p "  ${target_name} esiste già. Sovrascrivere? (s/N): " overwrite < /dev/tty
        if [[ "$overwrite" != "s" && "$overwrite" != "S" ]]; then
            echo "  Saltato."
            return
        fi
    fi

    curl -sL "${REPO_URL}/${template_name}" -o "${WORKFLOW_DIR}/${target_name}"

    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓ ${target_name} creato${NC}"
    else
        echo -e "  ${RED}✗ Errore nel download. Creazione manuale...${NC}"
        create_workflow_manually "$template_name" "$target_name"
    fi
}

# Fallback: crea i file manualmente se il download fallisce
create_workflow_manually() {
    local template_name="$1"
    local target_name="$2"

    if [[ "$template_name" == "claude-interactive.yml" ]]; then
        cat > "${WORKFLOW_DIR}/${target_name}" << 'HEREDOC'
name: Claude Interactive

on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]

permissions:
  contents: write
  pull-requests: write
  issues: write

jobs:
  claude:
    if: contains(github.event.comment.body, '@claude')
    uses: Polloinfilzato/claude-workflows/.github/workflows/interactive-claude.yml@main
    secrets:
      anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
HEREDOC
        echo -e "  ${GREEN}✓ ${target_name} creato (fallback)${NC}"
    fi

    if [[ "$template_name" == "claude-prd.yml" ]]; then
        cat > "${WORKFLOW_DIR}/${target_name}" << 'HEREDOC'
name: Claude PRD Analysis

on:
  push:
    paths:
      - '.claude/prds/**'

permissions:
  contents: write
  pull-requests: write
  issues: write

jobs:
  generate-claude-md:
    uses: Polloinfilzato/claude-workflows/.github/workflows/prd-to-claude-md.yml@main
    secrets:
      anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
HEREDOC
        echo -e "  ${GREEN}✓ ${target_name} creato (fallback)${NC}"
    fi
}

# Installa i workflow selezionati
case $choice in
    1)
        install_workflow "claude-interactive.yml" "claude-interactive.yml" "Interactive @claude"
        ;;
    2)
        install_workflow "claude-prd.yml" "claude-prd.yml" "PRD to CLAUDE.md"
        mkdir -p .claude/prds
        echo -e "  ${GREEN}✓ Cartella .claude/prds/ creata${NC}"
        ;;
    3)
        install_workflow "claude-interactive.yml" "claude-interactive.yml" "Interactive @claude"
        install_workflow "claude-prd.yml" "claude-prd.yml" "PRD to CLAUDE.md"
        mkdir -p .claude/prds
        echo -e "  ${GREEN}✓ Cartella .claude/prds/ creata${NC}"
        ;;
esac

# Verifica secret ANTHROPIC_API_KEY
echo ""
echo -e "${YELLOW}Verifico secret ANTHROPIC_API_KEY...${NC}"

REPO_FULLNAME=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null)

if [ -n "$REPO_FULLNAME" ]; then
    HAS_SECRET=$(gh secret list --repo "$REPO_FULLNAME" 2>/dev/null | grep -c "ANTHROPIC_API_KEY" || true)
    if [ "$HAS_SECRET" -gt 0 ]; then
        echo -e "${GREEN}✓ ANTHROPIC_API_KEY è configurata${NC}"
    else
        echo -e "${YELLOW}⚠ ANTHROPIC_API_KEY non trovata nei secrets del repo.${NC}"
        echo ""
        echo "  Configurala con:"
        echo -e "  ${BOLD}gh secret set ANTHROPIC_API_KEY --repo ${REPO_FULLNAME}${NC}"
        echo ""
    fi
else
    echo -e "${YELLOW}⚠ Non riesco a verificare i secrets (repo non collegato a GitHub?)${NC}"
fi

# Riepilogo
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║              Setup completato!           ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""
echo "Prossimi passi:"
echo ""
echo "  1. Verifica i file creati in ${WORKFLOW_DIR}/"
echo "  2. Assicurati che ANTHROPIC_API_KEY sia configurata"
echo "  3. Fai commit e push:"
echo ""
echo -e "     ${BOLD}git add ${WORKFLOW_DIR}/ .claude/${NC}"
echo -e "     ${BOLD}git commit -m 'chore: setup Claude workflows'${NC}"
echo -e "     ${BOLD}git push${NC}"
echo ""
echo "  4. Testa scrivendo un commento su una issue:"
echo -e "     ${BOLD}@claude dimmi come funziona questo progetto${NC}"
echo ""
