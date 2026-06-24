#!/usr/bin/env bash
# memory-wrappers.sh — Shell wrappers that keep agent files fresh on every session start.
#
# Remote server setup — add to ~/.bashrc or ~/.zshrc on the server:
#
#   export AGENT_MEMORY_VAULT="$HOME/agent-memory-vault"
#   source "$AGENT_MEMORY_VAULT/scripts/memory-wrappers.sh"
#
# On your local machine (Obsidian), the vault lives in the same Git repo.
# Obsidian Git plugin pushes changes; the server pulls them automatically.
#
# What happens on every agent invocation:
#   1. _aw_pull_vault: pulls latest vault from Git (debounced — at most once per 5 min)
#   2. _aw_sync_cwd:   writes fresh CLAUDE.md / GEMINI.md / etc. for the current project
#   3. Agent binary runs with up-to-date context

# ── Config ────────────────────────────────────────────────────────────────────

AGENT_MEMORY_VAULT="${AGENT_MEMORY_VAULT:-$HOME/agent-memory-vault}"
_AW_SYNC="$AGENT_MEMORY_VAULT/scripts/sync-memory.sh"

# How often to pull from Git, in seconds (default: 5 minutes)
AGENT_MEMORY_PULL_INTERVAL="${AGENT_MEMORY_PULL_INTERVAL:-300}"

# Set to 1 to see pull/sync output on every invocation
AGENT_MEMORY_VERBOSE="${AGENT_MEMORY_VERBOSE:-0}"

# ── Git pull (debounced) ──────────────────────────────────────────────────────
# Pulls the vault from its Git remote at most once per AGENT_MEMORY_PULL_INTERVAL.
# The pull runs in the background — it never delays the agent invocation.
# A timestamp file (.last-pull) tracks when the last pull was triggered.

_aw_pull_vault() {
    [[ ! -d "$AGENT_MEMORY_VAULT/.git" ]] && return 0

    local stamp="$AGENT_MEMORY_VAULT/.last-pull"
    local now
    now="$(date +%s)"
    local last=0
    [[ -f "$stamp" ]] && last="$(cat "$stamp" 2>/dev/null || echo 0)"

    if (( now - last >= AGENT_MEMORY_PULL_INTERVAL )); then
        echo "$now" > "$stamp"
        if [[ "$AGENT_MEMORY_VERBOSE" == "1" ]]; then
            (cd "$AGENT_MEMORY_VAULT" && git pull 2>&1 | sed 's/^/  [vault] /' &)
        else
            (cd "$AGENT_MEMORY_VAULT" && git pull --quiet 2>/dev/null &)
        fi
    fi
}

# ── Internal sync helper ──────────────────────────────────────────────────────

_aw_sync_cwd() {
    if [[ ! -f "$_AW_SYNC" ]]; then
        return 0  # Vault not set up yet; don't block the agent
    fi

    if [[ "$AGENT_MEMORY_VERBOSE" == "1" ]]; then
        "$_AW_SYNC" "$(pwd)"
    else
        "$_AW_SYNC" "$(pwd)" 2>/dev/null || true
    fi
}

# ── Claude Code ───────────────────────────────────────────────────────────────
# Claude Code reads CLAUDE.md automatically. The wrapper keeps it fresh.

claude() {
    _aw_pull_vault
    _aw_sync_cwd
    command claude "$@"
}

# ── Gemini CLI ────────────────────────────────────────────────────────────────
# Gemini CLI reads GEMINI.md automatically.

gemini() {
    _aw_pull_vault
    _aw_sync_cwd
    command gemini "$@"
}

# ── OpenAI Codex CLI ──────────────────────────────────────────────────────────
# Codex reads instructions from .codex/instructions.md.

codex() {
    _aw_pull_vault
    _aw_sync_cwd
    command codex "$@"
}

# ── GitHub Copilot CLI ────────────────────────────────────────────────────────
# Copilot CLI reads .github/copilot-instructions.md.

gh() {
    if [[ "${1:-}" == "copilot" ]]; then
        _aw_pull_vault
        _aw_sync_cwd
    fi
    command gh "$@"
}

# Export so subshells and scripts can use them
export -f claude gemini codex gh 2>/dev/null || true

# ── Optional: Stop hook integration ──────────────────────────────────────────
# If your coding agent supports a "Stop" hook (a command that runs after
# every session ends), add this to its hook config to re-sync all registered
# projects automatically, so memory files stay current without any manual
# intervention:
#
#   "$AGENT_MEMORY_VAULT/scripts/sync-memory.sh" --all
#
# Example .claude/settings.json hook:
#
# {
#   "hooks": {
#     "Stop": [
#       {
#         "command": "$AGENT_MEMORY_VAULT/scripts/sync-memory.sh --all"
#       }
#     ]
#   }
# }

# ── Status ────────────────────────────────────────────────────────────────────

if [[ "${AGENT_MEMORY_VERBOSE}" == "1" ]]; then
    echo "Agent memory wrappers active."
    echo "  Vault: $AGENT_MEMORY_VAULT"
    echo "  Wrapped: claude, gemini, codex, gh"
fi
