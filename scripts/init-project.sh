#!/usr/bin/env bash
# init-project.sh — Initialise a new project (or module) in the vault.
#
# Usage:
#   init-project.sh <name> [repo-path]                    Top-level project
#   init-project.sh <parent>/<module> [repo-path]         Module under a parent
#
# Examples:
#   init-project.sh my-app ~/dev/my-app
#   init-project.sh agentwatch/agentwatch-ios ~/dev/agentwatch-ios

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_DIR="$VAULT_DIR/projects/_TEMPLATE"
PATHS_FILE="$VAULT_DIR/.project-paths"

ok()  { echo "  ✓ $*"; }
err() { echo "  ✗ $*" >&2; exit 1; }
info(){ echo "  → $*"; }

if [[ $# -lt 1 ]]; then
    echo "Usage:"
    echo "  init-project.sh <name> [repo-path]"
    echo "  init-project.sh <parent>/<module> [repo-path]"
    exit 1
fi

INPUT="$1"
REPO_PATH="${2:-}"

# Parse parent/module syntax
if [[ "$INPUT" == */* ]]; then
    PARENT_NAME="${INPUT%%/*}"
    PROJECT_NAME="${INPUT##*/}"
    PARENT_VAULT_DIR="$VAULT_DIR/projects/$PARENT_NAME"
    VAULT_PROJECT_DIR="$PARENT_VAULT_DIR/$PROJECT_NAME"
    IS_MODULE=true

    # Parent must exist
    if [[ ! -d "$PARENT_VAULT_DIR" ]]; then
        err "Parent project '$PARENT_NAME' not found at $PARENT_VAULT_DIR. Create it first."
    fi
else
    PROJECT_NAME="$INPUT"
    VAULT_PROJECT_DIR="$VAULT_DIR/projects/$PROJECT_NAME"
    IS_MODULE=false
fi

echo ""
echo "Initialising: $INPUT"
$IS_MODULE && echo "  Parent: $PARENT_NAME"
[[ -n "$REPO_PATH" ]] && echo "  Repo:   $REPO_PATH"
echo ""

# ── 1. Create vault project from template ─────────────────────────────────────

if [[ -d "$VAULT_PROJECT_DIR" ]]; then
    info "Vault folder already exists — skipping template copy"
else
    cp -r "$TEMPLATE_DIR" "$VAULT_PROJECT_DIR"

    # Replace placeholder text in all template files
    TODAY="$(date +%Y-%m-%d)"
    DISPLAY_NAME="$(echo "$PROJECT_NAME" | awk -F- '{out=""; for(i=1;i<=NF;i++){out = out (i>1?" ":"") toupper(substr($i,1,1)) substr($i,2)} print out}')"

    find "$VAULT_PROJECT_DIR" -name "*.md" | while read -r f; do
        sed -i.bak \
            -e "s/project: project-name/project: $PROJECT_NAME/g" \
            -e "s/Project Name/$DISPLAY_NAME/g" \
            -e "s/YYYY-MM-DD/$TODAY/g" \
            "$f"
        rm -f "$f.bak"
    done

    # Modules don't get their own ACTIVITY.md — their activity rolls up
    # into the parent's feed via breadcrumbs, not a per-module diary.
    if $IS_MODULE; then
        rm -f "$VAULT_PROJECT_DIR/ACTIVITY.md"
    fi

    # Declare the parent/submodule relationship in frontmatter. Per
    # AGENTS.md this — not folder nesting — is the source of truth used
    # to resolve which ACTIVITY.md to read at session start.
    if $IS_MODULE; then
        MODULE_OVERVIEW="$VAULT_PROJECT_DIR/OVERVIEW.md"
        sed -i.bak "s/^parent: *\$/parent: $PARENT_NAME/" "$MODULE_OVERVIEW"
        rm -f "$MODULE_OVERVIEW.bak"

        PARENT_OVERVIEW="$PARENT_VAULT_DIR/OVERVIEW.md"
        if grep -q '^submodules: \[\]$' "$PARENT_OVERVIEW"; then
            sed -i.bak "s/^submodules: \[\]\$/submodules: [$PROJECT_NAME]/" "$PARENT_OVERVIEW"
            rm -f "$PARENT_OVERVIEW.bak"
        elif grep -qE '^submodules: \[.*\]$' "$PARENT_OVERVIEW"; then
            if ! grep -qE "^submodules:.*[\[, ]$PROJECT_NAME[,\]]" "$PARENT_OVERVIEW"; then
                sed -i.bak "s/^submodules: \[\(.*\)\]\$/submodules: [\1, $PROJECT_NAME]/" "$PARENT_OVERVIEW"
                rm -f "$PARENT_OVERVIEW.bak"
            fi
        else
            info "Could not find 'submodules:' in $PARENT_OVERVIEW — add '$PROJECT_NAME' to it manually"
        fi
    fi

    # If module: inject parent link into OVERVIEW.md (after the first heading)
    if $IS_MODULE; then
        PARENT_LINK="
---

## System Context

This is a module of **$PARENT_NAME**.
→ See [[../../OVERVIEW]] for the full system architecture and cross-module decisions."

        OVERVIEW_FILE="$VAULT_PROJECT_DIR/OVERVIEW.md"
        OVERVIEW_TMP="$(mktemp)"
        INSERTED=false
        while IFS= read -r line || [[ -n "$line" ]]; do
            echo "$line" >> "$OVERVIEW_TMP"
            if ! $INSERTED && [[ "$line" == "# "* ]]; then
                printf '%s\n' "$PARENT_LINK" >> "$OVERVIEW_TMP"
                INSERTED=true
            fi
        done < "$OVERVIEW_FILE"
        mv "$OVERVIEW_TMP" "$OVERVIEW_FILE"
    fi

    ok "Created vault project: $VAULT_PROJECT_DIR"
fi

# ── 2. Register in projects/_INDEX.md ─────────────────────────────────────────

INDEX_FILE="$VAULT_DIR/projects/_INDEX.md"
TODAY="$(date +%Y-%m-%d)"

if $IS_MODULE; then
    INDEX_ENTRY="| &nbsp;&nbsp;↳ $PROJECT_NAME | ⚪ Planned | | $TODAY | [[$PARENT_NAME/$PROJECT_NAME/OVERVIEW]] |"
    SEARCH_STR="$PROJECT_NAME"
else
    INDEX_ENTRY="| **$PROJECT_NAME** | ⚪ Planned | | $TODAY | [[$PROJECT_NAME/OVERVIEW]] |"
    SEARCH_STR="$PROJECT_NAME"
fi

if grep -qF "$SEARCH_STR" "$INDEX_FILE" 2>/dev/null; then
    info "_INDEX.md already contains '$SEARCH_STR' — skipping"
else
    # Insert before the "add rows" placeholder line
    INDEX_TMP="$(mktemp)"
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" == "| *(add rows"* ]] && echo "$INDEX_ENTRY" >> "$INDEX_TMP"
        echo "$line" >> "$INDEX_TMP"
    done < "$INDEX_FILE"
    mv "$INDEX_TMP" "$INDEX_FILE"
    ok "Added to projects/_INDEX.md"
fi

# ── 3. Register in AGENTS.md ──────────────────────────────────────────────────

AGENTS_FILE="$VAULT_DIR/AGENTS.md"

if $IS_MODULE; then
    AGENTS_ENTRY="| &nbsp;&nbsp;↳ $PROJECT_NAME | ⚪ Planned | [[projects/$PARENT_NAME/$PROJECT_NAME/OVERVIEW]] |"
else
    AGENTS_ENTRY="| **$PROJECT_NAME** | ⚪ Planned | [[projects/$PROJECT_NAME/OVERVIEW]] |"
fi

if grep -qF "$PROJECT_NAME" "$AGENTS_FILE" 2>/dev/null; then
    info "AGENTS.md already mentions '$PROJECT_NAME' — skipping"
else
    AGENTS_TMP="$(mktemp)"
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" == "| *(copy"* ]] && echo "$AGENTS_ENTRY" >> "$AGENTS_TMP"
        echo "$line" >> "$AGENTS_TMP"
    done < "$AGENTS_FILE"
    mv "$AGENTS_TMP" "$AGENTS_FILE"
    ok "Added to AGENTS.md"
fi

# ── 4. Register repo path ─────────────────────────────────────────────────────

if [[ -n "$REPO_PATH" ]]; then
    if ! grep -qF "$REPO_PATH" "$PATHS_FILE" 2>/dev/null; then
        echo "$REPO_PATH" >> "$PATHS_FILE"
        ok "Registered in .project-paths: $REPO_PATH"
    else
        info ".project-paths already contains this path"
    fi

    # ── 5. Gitignore agent files in the repo ──────────────────────────────────
    # These files are auto-generated from vault content — they should never
    # be committed to the project repo.
    GITIGNORE_FILE="$REPO_PATH/.gitignore"
    AGENT_ENTRIES=(
        "# Agent memory files — auto-generated by sync-memory.sh, do not commit"
        ".claude/CLAUDE.md"
        ".gemini/GEMINI.md"
        ".github/copilot-instructions.md"
        ".codex/"
    )

    needs_header=true
    for entry in "${AGENT_ENTRIES[@]}"; do
        if grep -qF "$entry" "$GITIGNORE_FILE" 2>/dev/null; then
            needs_header=false  # block already present
            break
        fi
    done

    if $needs_header; then
        printf '\n' >> "$GITIGNORE_FILE"
        for entry in "${AGENT_ENTRIES[@]}"; do
            echo "$entry" >> "$GITIGNORE_FILE"
        done
        ok "Added agent files to $REPO_PATH/.gitignore"
    else
        info ".gitignore already covers agent files"
    fi

    # ── 6. Sync agent files to repo ───────────────────────────────────────────
    echo ""
    "$SCRIPT_DIR/sync-memory.sh" "$REPO_PATH"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Project '$PROJECT_NAME' is ready."
echo ""
echo "  Fill in:"
echo "    $VAULT_PROJECT_DIR/OVERVIEW.md   ← Start here"
echo "    $VAULT_PROJECT_DIR/STYLE.md"
echo ""
echo "  Drop long-form docs (specs, design docs, diagrams) in:"
echo "    $VAULT_PROJECT_DIR/docs/"
if [[ -n "$REPO_PATH" ]]; then
    echo ""
    echo "  Agent files written to (and gitignored):"
    echo "    $REPO_PATH/.claude/CLAUDE.md"
    echo "    $REPO_PATH/.gemini/GEMINI.md"
    echo "    $REPO_PATH/.github/copilot-instructions.md"
    echo "    $REPO_PATH/.codex/instructions.md"
fi
