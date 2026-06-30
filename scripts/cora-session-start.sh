#!/usr/bin/env bash
# cora-session-start.sh — Compute the mandatory session-start recap for a project.
#
# Usage:
#   cora-session-start.sh [project-name]
#
# If no project name is given, the script derives it from the current
# working directory's folder name. It resolves the CORA vault, finds the
# matching vault project, reads the correct ACTIVITY.md, and emits a
# plain-text recap on stdout.
#
# This script is agent-agnostic — each agent's SessionStart hook wrapper
# is responsible for turning this plain text into the JSON shape that
# agent expects.

set -euo pipefail

# ── Vault resolution ─────────────────────────────────────────────────────────

normalize_vault_path() {
    local raw="$1"
    # Some callers set AGENT_MEMORY_VAULT with shell-escaped spaces/tildes.
    # Unescape the most common offenders so the path can be used literally.
    raw="${raw//\\ / }"
    raw="${raw//\\~/~}"
    raw="${raw//\\:/:}"
    printf '%s' "$raw"
}

resolve_vault() {
    local vault="${AGENT_MEMORY_VAULT:-}"
    vault="$(normalize_vault_path "$vault")"

    if [[ -z "$vault" || ! -f "$vault/AGENTS.md" ]]; then
        if [[ -d "${HOME}/obsidian-memory-vault" && -f "${HOME}/obsidian-memory-vault/AGENTS.md" ]]; then
            vault="${HOME}/obsidian-memory-vault"
        elif [[ -d "${HOME}/Library/Mobile Documents/iCloud~md~obsidian/Documents/rm-memory-vault" && -f "${HOME}/Library/Mobile Documents/iCloud~md~obsidian/Documents/rm-memory-vault/AGENTS.md" ]]; then
            vault="${HOME}/Library/Mobile Documents/iCloud~md~obsidian/Documents/rm-memory-vault"
        fi
    fi

    if [[ -z "$vault" ]]; then
        echo "ERROR: Could not resolve CORA vault. Set \$AGENT_MEMORY_VAULT or create ~/obsidian-memory-vault." >&2
        return 1
    fi

    if [[ ! -f "$vault/AGENTS.md" ]]; then
        echo "ERROR: Vault at '$vault' does not contain AGENTS.md." >&2
        return 1
    fi

    echo "$vault"
}

# ── Project resolution ───────────────────────────────────────────────────────

find_vault_project() {
    local vault="$1"
    local name="$2"

    # Top-level project
    if [[ -d "$vault/projects/$name" ]]; then
        echo "$vault/projects/$name"
        return 0
    fi

    # Nested module
    find "$vault/projects" -type d -name "$name" -maxdepth 4 2>/dev/null | head -1
}

# Read a YAML frontmatter value from the first --- block of a Markdown file.
read_frontmatter() {
    local file="$1"
    local key="$2"

    if [[ ! -f "$file" ]]; then
        return 0
    fi

    awk -v key="$key" '
        /^---$/ { in_fm = !in_fm; next }
        in_fm {
            gsub(/^ +| +$/, "", $0)
            split($0, parts, ":")
            if (parts[1] == key) {
                $1 = ""
                sub(/^ +/, "", $0)
                print $0
                exit
            }
        }
    ' "$file"
}

# ── ACTIVITY.md parsing ───────────────────────────────────────────────────────

# Emit the most recent N activity entries from an ACTIVITY.md file.
# File is newest-at-top, so head gives the most recent entries.
emit_activity_last_n() {
    local activity_file="$1"
    local n="$2"

    if [[ ! -f "$activity_file" ]]; then
        return 0
    fi

    grep -E '^- [0-9]{4}-[0-9]{2}-[0-9]{2}' "$activity_file" | head -n "$n"
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
    local project_name="${1:-}"

    if [[ -z "$project_name" ]]; then
        project_name="$(basename "$(pwd)")"
    fi

    local vault
    vault="$(resolve_vault)"

    local vault_project_dir
    vault_project_dir="$(find_vault_project "$vault" "$project_name")"

    if [[ -z "$vault_project_dir" ]]; then
        cat << EOF
MANDATORY SESSION START CONTEXT
Project: $project_name
Status: No matching vault project found at $vault/projects/...

Recent activity:
- (none — vault project not found)
EOF
        return 0
    fi

    local parent_name=""
    local is_parent=false
    local is_module=false

    local parent_value
    parent_value="$(read_frontmatter "$vault_project_dir/OVERVIEW.md" "parent")"

    local submodules_value
    submodules_value="$(read_frontmatter "$vault_project_dir/OVERVIEW.md" "submodules")"

    if [[ -n "$parent_value" ]]; then
        is_module=true
        parent_name="$parent_value"
    elif [[ -n "$submodules_value" && "$submodules_value" != "[]" ]]; then
        is_parent=true
    fi

    # Determine which ACTIVITY.md to read
    local activity_file=""
    if $is_module; then
        activity_file="$vault/projects/$parent_name/ACTIVITY.md"
    elif $is_parent; then
        activity_file="$vault_project_dir/ACTIVITY.md"
    fi

    local entries=""
    if [[ -n "$activity_file" && -f "$activity_file" ]]; then
        entries="$(emit_activity_last_n "$activity_file" 5)"
    fi

    # Build relationship description
    local relationship="standalone"
    if $is_module; then
        relationship="module of $parent_name"
    elif $is_parent; then
        relationship="parent project"
    fi

    echo "MANDATORY SESSION START CONTEXT"
    echo "Project: $project_name ($relationship)"
    echo ""
    echo "Recent activity:"
    if [[ -n "$entries" ]]; then
        echo "$entries"
    else
        echo "- (no recent activity)"
    fi
}

main "$@"
