# 🛠 Setup Guide

This is the maintenance guide for this vault. Agents don't need to read this.

---

## Vault Structure

```
cora-vault/
├── AGENTS.md                    ← Entry point for all agents
├── SETUP.md                     ← This file (for you only)
├── setup.sh                     ← Run once after cloning to personalize the vault
├── scripts/
│   ├── sync-memory.sh           ← Syncs vault memory to project agent files
│   ├── init-project.sh          ← Initialises a new project or module
│   └── memory-wrappers.sh       ← Shell wrappers — source in .bashrc/.zshrc
├── .project-paths               ← One repo path per line (auto-updated by init-project.sh)
├── projects/
│   ├── _INDEX.md
│   ├── _TEMPLATE/               ← Copy this to create a new top-level project
│   └── example-parent/          ← Example: top-level project with nested modules
│       ├── OVERVIEW.md          ← Umbrella: full system architecture
│       ├── STYLE.md             ← Cross-cutting style rules
│       ├── ISSUES.md            ← System-wide issues
│       ├── PROGRESS.md          ← Overall milestones
│       ├── ACTIVITY.md          ← Rollup of submodule breadcrumbs (every top-level project gets one; modules don't)
│       ├── docs/                ← Long-form docs (specs, design docs, diagrams)
│       └── example-module/      ← Module: its own OVERVIEW/STYLE/ISSUES/PROGRESS/docs (no ACTIVITY.md)
├── brand/
│   ├── PROFILE.md
│   ├── AESTHETIC.md
│   └── GOALS.md
└── ideas/
    ├── _INDEX.md
    ├── technical.md
    ├── product.md
    ├── content.md
    └── business.md
```

---

## Quick Start

### 0. Run setup once

```bash
./setup.sh
```

Personalizes `AGENTS.md` and `brand/PROFILE.md` with your name, and prints
shell-wiring instructions for your platform. See `README.md` for the full
walkthrough.

### 1. Wire the vault to your shell

Add to `~/.bashrc` or `~/.zshrc` (exact line printed by `setup.sh`):

```bash
export AGENT_MEMORY_VAULT="/path/to/this/vault"
source "$AGENT_MEMORY_VAULT/scripts/memory-wrappers.sh"
```

### 2. Sync an existing project

```bash
scripts/sync-memory.sh ~/dev/my-project
```

Writes `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md`, and `.codex/instructions.md` to the project directory.

### 3. Add a new top-level project

```bash
scripts/init-project.sh my-project ~/dev/my-project
```

### 4. Add a module under a parent project

```bash
scripts/init-project.sh my-parent/my-new-module ~/dev/my-new-module
```

### 5. Sync all registered projects at once

```bash
scripts/sync-memory.sh --all
```

---

## What sync-memory.sh generates per project

| Agent | File written | How agent reads it |
|-------|--------------|--------------------|
| Claude Code | `CLAUDE.md` | Auto-loaded at session start |
| Gemini CLI | `GEMINI.md` | Auto-loaded at session start |
| GitHub Copilot | `.github/copilot-instructions.md` | Auto-loaded in IDE |
| Codex | `.codex/instructions.md` | Auto-loaded at session start |

**For modules**, the generated file contains three layers:
1. Global `AGENTS.md` (identity, principles, write-back protocol)
2. Module OVERVIEW (what this specific module does)
3. Parent OVERVIEW (full system architecture)

This means an agent working on a module automatically gets both module context and the full parent system picture.

---

## Optional: Auto-Resync on a Stop Hook

If your coding agent supports a "Stop" hook (a command that runs after every
session ends), wire `sync-memory.sh --all` into it so memory files re-sync
automatically without manual intervention:

**`.claude/settings.json`** (or equivalent per agent):
```json
{
  "hooks": {
    "Stop": [
      {
        "command": "$AGENT_MEMORY_VAULT/scripts/sync-memory.sh --all"
      }
    ]
  }
}
```

---

## Updating AGENTS.md

When you add a project or module, update the **Active Projects** table in `AGENTS.md`.
When you make a system change, bump the `version` in the frontmatter.

`init-project.sh` handles the project-table update automatically when given a project path.

---

## Recommended Obsidian Plugins

| Plugin | Purpose |
|--------|---------|
| Dataview | Query notes like a database (auto project tables, idea counts) |
| Templater | Auto-fill new project files from `_TEMPLATE` |
| Tag Wrangler | Manage tags across ideas files |
