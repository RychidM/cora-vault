# CORA Vault

The memory vault that [CORA](https://github.com/RychidM/cora) operates on.
CORA Vault holds the content; the CORA plugin is the controls — the two work
hand in hand (see [Working with CORA](#working-with-cora)).

It's a reusable starting point for an [Obsidian](https://obsidian.md)-based
memory vault that AI coding agents (Claude Code, Gemini CLI, GitHub Copilot,
Codex) read at the start of every session — your identity, your projects'
state, open issues, decisions, and conventions — instead of starting cold
every time.

This repo is the **structure and mechanics only**: empty templates, working
sync scripts, no personal content. Clone it, run `setup.sh`, and fill in your
own projects, ideas, and preferences.

---

## Quickstart

```bash
git clone <this-repo-url> cora-vault
cd cora-vault
./setup.sh
```

`setup.sh` will:
1. Ask for your name (used in `AGENTS.md` and `brand/PROFILE.md`)
2. Fill in today's date everywhere a `last_updated`/`updated` field needs it
3. Make `scripts/*.sh` executable
4. Print shell-wiring instructions for your platform (also below)

It only fills in personalization placeholders (your name, today's date) in
markdown files — no network calls, no other side effects.

---

## Wire it to your shell

Add these two lines to your shell profile, then reload it:

```bash
export AGENT_MEMORY_VAULT="/absolute/path/to/cora-vault"
source "$AGENT_MEMORY_VAULT/scripts/memory-wrappers.sh"
```

| Platform | Profile file |
|----------|--------------|
| macOS (default shell: zsh) | `~/.zshrc` |
| Linux | `~/.bashrc` (or `~/.zshrc` if you use zsh) |
| WSL | Same as Linux, inside your WSL shell |
| Windows (no WSL) | Use Git Bash — add the lines to its `~/.bashrc`. Native PowerShell/cmd can't source this script; the `claude`/`gemini`/`codex`/`gh` shell wrappers only work in a bash-compatible shell. |

Once wired, every `claude`, `gemini`, `codex`, or `gh copilot` invocation
automatically pulls the latest vault content (if it's a git repo with a
remote) and regenerates that project's `CLAUDE.md`/`GEMINI.md`/
`.github/copilot-instructions.md`/`.codex/instructions.md` before running.

---

## What to fill in next

1. **`AGENTS.md`** — the "Who You're Working With" section (2-4 sentences:
   role, what you build, how you like to collaborate). This is what every
   agent reads first.
2. **`brand/PROFILE.md`, `AESTHETIC.md`, `GOALS.md`** — your background, tech
   stack, design preferences, and direction. Optional but worth it if you
   want agents making UI/UX or strategic suggestions on your behalf.
3. **Your first project:**
   ```bash
   scripts/init-project.sh my-project ~/dev/my-project
   ```
   Scaffolds `projects/my-project/` from `_TEMPLATE`, registers it in
   `projects/_INDEX.md` and `AGENTS.md`, and (if you pass a repo path) syncs
   agent files into that repo.

---

## How it's organized

- `AGENTS.md` — the entry point every agent reads. Identity, active projects,
  write-back protocol, cross-module rules.
- `projects/{name}/` — one folder per project: `OVERVIEW.md`, `ISSUES.md`,
  `PROGRESS.md`, `STYLE.md`, `docs/` (long-form documents). Top-level
  projects also get `ACTIVITY.md` (a rollup feed for submodule activity,
  empty until the project has a module); modules don't have their own.
- `ideas/` — a lightweight idea backlog by domain.
- `brand/` — your profile, design preferences, and goals (used for anything
  client-facing or design-related).
- `research/` — a source/synthesis split: raw clippings in `sources/`,
  LLM-maintained topic pages in `topics/`.
- `sessions/` — captured chat sessions worth carrying forward.
- `scripts/` — `init-project.sh` (scaffold a project), `sync-memory.sh`
  (generate per-project agent files), `memory-wrappers.sh` (shell wrappers
  that keep those files fresh automatically).

Full reference, including the vault structure diagram and maintenance
workflow: see [`SETUP.md`](SETUP.md).

---

## Working with CORA

CORA Vault holds the content; **[CORA](https://github.com/RychidM/cora)** is
the operational layer that works it. They're designed to be used together:

- **The vault's scripts** cover the essentials from a plain shell, no agent
  needed — `setup.sh` (scaffold the vault), `init-project.sh` (new project),
  `sync-memory.sh` (regenerate per-repo agent files), `memory-wrappers.sh`
  (keep them fresh).
- **The CORA plugin** adds the full operational surface from chat, across
  Claude, Copilot, Gemini, and Codex: capture ideas and decisions
  (`/cora-log`), spin up and sync projects (`/cora-init`, `/cora-sync`),
  search and read (`/cora-find`, `/cora-read`, `/cora-status`), synthesize
  research (`/cora-ingest`), capture and resume sessions (`/cora-carry`,
  `/cora-recall`, `/cora-resume`), edit and reshape (`/cora-edit`,
  `/cora-move`), and keep the vault healthy (`/cora-lint`).

Both write the same files and frontmatter, so you can use the scripts, the
skills, or mix the two freely. Install CORA from the
[plugin repo](https://github.com/RychidM/cora#installation).

---

## Inspiration

Inspired by Andrej Karpathy's
["LLM Wiki" note](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
— an LLM that incrementally maintains a persistent, interlinked knowledge
base instead of re-deriving it on every query. CORA Vault is built on that
idea.

---

## License

MIT — see [`LICENSE`](LICENSE).
