#!/usr/bin/env bash
# cora-session-start.sh — Compute the mandatory session-start recap for a project.
#
# Usage:
#   cora-session-start.sh [project-name]
#
# If no project name is given, the script derives it from the current
# working directory's folder name. It resolves the CORA vault, finds the
# matching vault project, reads the correct ACTIVITY.md and
# sessions/_INDEX.md, and emits a plain-text recap on stdout.
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

# ── Date helpers ─────────────────────────────────────────────────────────────

# Convert a YYYY-MM-DD date to an integer comparable with test -lt/-gt.
date_to_int() {
    local d="$1"
    echo "${d//-/}"
}

# Today in YYYY-MM-DD format.
today_str() {
    date +%Y-%m-%d
}

# ── ACTIVITY.md parsing ────────────────────────────────────────────────────────

# Read an ACTIVITY.md file and emit entries dated strictly after the cutoff.
# Entries are lines under a ## YYYY-MM-DD heading.
emit_activity_since() {
    local activity_file="$1"
    local cutoff="$2"
    local cutoff_int
    local current_date=""
    local found_any=false

    cutoff_int="$(date_to_int "$cutoff")"

    if [[ ! -f "$activity_file" ]]; then
        return 0
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Date heading
        if [[ "$line" =~ ^##[[:space:]]+([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
            current_date="${BASH_REMATCH[1]}"
            continue
        fi

        # Entry line: starts with "- " and contains a date
        if [[ "$current_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ && "$line" =~ ^-[[:space:]]+([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
            local entry_date="${BASH_REMATCH[1]}"
            local entry_int
            entry_int="$(date_to_int "$entry_date")"

            if [[ "$entry_int" -gt "$cutoff_int" ]]; then
                echo "$line"
                found_any=true
            fi
        fi
    done < "$activity_file"

    if $found_any; then
        return 0
    else
        return 1
    fi
}

# Fallback: emit the last N activity entries (regardless of date).
emit_activity_last_n() {
    local activity_file="$1"
    local n="$2"

    if [[ ! -f "$activity_file" ]]; then
        return 0
    fi

    grep -E '^- [0-9]{4}-[0-9]{2}-[0-9]{2}' "$activity_file" | tail -n "$n"
}

# ── sessions/_INDEX.md parsing ───────────────────────────────────────────────

# Find the most recent session date (before today) whose scope matches the
# project path or any of its submodules/parent.
find_last_session_date() {
    local sessions_file="$1"
    local project_path="$2"  # e.g. cora-suite/cora or cora-suite
    local today
    today="$(today_str)"
    local best_date=""

    if [[ ! -f "$sessions_file" ]]; then
        return 0
    fi

    # Read the active sessions table. Scope is the third column and looks
    # like `projects/cora-suite/cora` or `ideas/technical` or `general`.
    # We match when the scope starts with the project path (so a parent
    # project also matches sessions scoped to its modules).
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Table rows only — first non-pipe token must be a date.
        local session_date
        session_date="$(echo "$line" | grep -oE '\|[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]*\|' | tr -d '|' | tr -d ' ')"
        [[ -z "$session_date" ]] && continue

        # Scope is the backtick-quoted value in the row.
        local scope
        scope="$(echo "$line" | grep -oE '\`[^`]+\`' | tr -d '\`')"
        [[ -z "$scope" ]] && continue

        # Skip rows with today's date or in the future
        if [[ "$(date_to_int "$session_date")" -ge "$(date_to_int "$today")" ]]; then
            continue
        fi

        # Match scope against project path. Scope values of interest start
        # with "projects/". We strip that prefix, then check whether the
        # remainder equals or starts with the project path.
        if [[ "$scope" == projects/* ]]; then
            local rel_scope="${scope#projects/}"
            if [[ "$rel_scope" == "$project_path" || "$rel_scope" == "$project_path/"* ]]; then
                if [[ -z "$best_date" || "$(date_to_int "$session_date")" -gt "$(date_to_int "$best_date")" ]]; then
                    best_date="$session_date"
                fi
            fi
        fi
    done < "$sessions_file"

    echo "$best_date"
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
Last session: unknown

Activity since last session:
- (none — vault project not found)
EOF
        return 0
    fi

    local parent_name=""
    local is_parent=false
    local is_module=false
    local is_standalone=false

    local parent_value
    parent_value="$(read_frontmatter "$vault_project_dir/OVERVIEW.md" "parent")"

    local submodules_value
    submodules_value="$(read_frontmatter "$vault_project_dir/OVERVIEW.md" "submodules")"

    if [[ -n "$parent_value" ]]; then
        is_module=true
        parent_name="$parent_value"
    elif [[ -n "$submodules_value" && "$submodules_value" != "[]" ]]; then
        is_parent=true
    else
        is_standalone=true
    fi

    # Determine which ACTIVITY.md to read
    local activity_file=""
    if $is_module; then
        activity_file="$vault/projects/$parent_name/ACTIVITY.md"
    elif $is_parent; then
        activity_file="$vault_project_dir/ACTIVITY.md"
    fi

    # Build the project path for session matching
    local project_path="$project_name"
    if $is_module; then
        project_path="$parent_name/$project_name"
    fi

    local last_session_date
    last_session_date="$(find_last_session_date "$vault/sessions/_INDEX.md" "$project_path")"

    local fallback_note=""
    local entries=""

    if [[ -n "$last_session_date" ]]; then
        entries="$(emit_activity_since "$activity_file" "$last_session_date" || true)"
        if [[ -z "$entries" ]]; then
            fallback_note="No activity entries dated after the last session ($last_session_date)."
        fi
    else
        fallback_note="No prior session found for this project — falling back to recent activity."
        # Last 5 entries or 7 days, whichever is more. We take last 5.
        entries="$(emit_activity_last_n "$activity_file" 5)"
    fi

    # Build relationship description
    local relationship="standalone"
    if $is_module; then
        relationship="module of $parent_name"
    elif $is_parent; then
        relationship="parent project"
    fi

    # Print the mandatory context block
    echo "MANDATORY SESSION START CONTEXT"
    echo "Project: $project_name ($relationship)"
    if [[ -n "$last_session_date" ]]; then
        echo "Last session: $last_session_date (from sessions/_INDEX.md)"
    else
        echo "Last session: none on record"
    fi

    if [[ -n "$fallback_note" ]]; then
        echo ""
        echo "$fallback_note"
    fi

    echo ""
    echo "Activity since last session:"
    if [[ -n "$entries" ]]; then
        echo "$entries"
    else
        echo "- (no recent activity)"
    fi
}

main "$@"
