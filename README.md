# Agent Memory Vault Template

A reusable starting point for an [Obsidian](https://obsidian.md)-based memory
vault that AI coding agents (Claude Code, Gemini CLI, GitHub Copilot, Codex)
read at the start of every session — your identity, your projects' state,
open issues, decisions, and conventions — instead of starting cold every time.

This repo is the **structure and mechanics only**: empty templates, working
sync scripts, no personal content. Clone it, run `setup.sh`, and fill in your
own projects, ideas, and preferences.

---

## Quickstart

```bash
git clone <this-repo-url> agent-memory-vault
cd agent-memory-vault
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
export AGENT_MEMORY_VAULT="/absolute/path/to/agent-memory-vault"
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
  `PROGRESS.md`, `STYLE.md`, `docs/` (long-form documents), and `ACTIVITY.md`
  for parent projects with submodules.
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

## License

MIT — see [`LICENSE`](LICENSE).
