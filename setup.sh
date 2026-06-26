#!/usr/bin/env bash
# setup.sh — One-time personalization for a freshly cloned cora-vault.
#
# Fills in {{OWNER_NAME}} / {{TODAY}} placeholders across the vault's
# markdown files, makes the scripts executable, and prints shell-wiring
# instructions for your platform. See README.md for the full walkthrough.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── Helpers ──────────────────────────────────────────────────────────────────

ok()   { echo "  ✓ $*"; }
info() { echo "  → $*"; }
err()  { echo "  ✗ $*" >&2; }

# Escape a string for safe use as a sed replacement (escapes \, /, &)
sed_escape() {
    printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

# ── 1. Sanity check ────────────────────────────────────────────────────────

if [[ ! -f "$SCRIPT_DIR/AGENTS.md" || ! -f "$SCRIPT_DIR/scripts/init-project.sh" ]]; then
    err "This doesn't look like the vault template root (missing AGENTS.md or scripts/init-project.sh)."
    echo "  Run this from the directory you cloned the template into."
    exit 1
fi

# ── 2. Idempotency guard ───────────────────────────────────────────────────

if ! grep -q '{{OWNER_NAME}}' "$SCRIPT_DIR/AGENTS.md" 2>/dev/null; then
    echo "It looks like setup has already run (AGENTS.md has no {{OWNER_NAME}} placeholder left)."
    read -r -p "Run it again anyway? [y/N] " CONFIRM
    case "$CONFIRM" in
        y|Y|yes|YES) ;;
        *) echo "Aborted."; exit 0 ;;
    esac
fi

echo ""
echo "Setting up your agent-memory vault..."
echo ""

# ── 3. Prompts ─────────────────────────────────────────────────────────────

read -r -p "Your name (used in AGENTS.md and brand/PROFILE.md): " OWNER_NAME
if [[ -z "$OWNER_NAME" ]]; then
    err "A name is required."
    exit 1
fi

VAULT_PATH="$SCRIPT_DIR"

TODAY="$(date +%Y-%m-%d)"

# ── 4. Token substitution ──────────────────────────────────────────────────

NAME_ESCAPED="$(sed_escape "$OWNER_NAME")"
TODAY_ESCAPED="$(sed_escape "$TODAY")"

TOUCHED=0
while IFS= read -r -d '' f; do
    if grep -q '{{OWNER_NAME}}\|{{TODAY}}' "$f" 2>/dev/null; then
        sed -i.bak -e "s/{{OWNER_NAME}}/$NAME_ESCAPED/g" -e "s/{{TODAY}}/$TODAY_ESCAPED/g" "$f"
        rm -f "$f.bak"
        TOUCHED=$((TOUCHED + 1))
    fi
done < <(find "$SCRIPT_DIR" -name "*.md" -not -path "*/.git/*" -print0)

ok "Personalized $TOUCHED file(s) with your name and today's date"

# ── 5. Make scripts executable ─────────────────────────────────────────────

chmod +x "$SCRIPT_DIR"/scripts/*.sh
chmod +x "$SCRIPT_DIR"/setup.sh
ok "Made scripts/*.sh executable"

# ── 6. Platform-aware next steps ───────────────────────────────────────────

OS_NAME="$(uname -s)"
case "$OS_NAME" in
    Darwin)
        PLATFORM="macOS"
        PROFILE="~/.zshrc"
        ;;
    Linux)
        if grep -qi microsoft /proc/version 2>/dev/null; then
            PLATFORM="WSL"
        else
            PLATFORM="Linux"
        fi
        PROFILE="~/.bashrc (or ~/.zshrc if you use zsh)"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        PLATFORM="Windows (Git Bash)"
        PROFILE="~/.bashrc"
        ;;
    *)
        PLATFORM="$OS_NAME"
        PROFILE="your shell's profile file"
        ;;
esac

echo ""
echo "Done. Detected platform: $PLATFORM"
echo ""
echo "Next step — wire the vault into your shell."
echo "Add these two lines to $PROFILE:"
echo ""
echo "  export AGENT_MEMORY_VAULT=\"$VAULT_PATH\""
echo "  source \"\$AGENT_MEMORY_VAULT/scripts/memory-wrappers.sh\""
echo ""

if [[ "$PLATFORM" == "Windows (Git Bash)" ]]; then
    echo "Note: native PowerShell/cmd can't source memory-wrappers.sh directly."
    echo "Use Git Bash or WSL for the claude/gemini/codex/gh shell wrappers."
    echo ""
fi

echo "Then reload your shell (e.g. 'source $PROFILE' or open a new terminal)."
echo "Full walkthrough: README.md · Ongoing maintenance: SETUP.md"
