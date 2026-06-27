# Contributing to CORA Vault

Thanks for your interest in CORA Vault — the reusable starting point for an
agent-readable memory vault, and the data half of the
[CORA](https://github.com/RychidM/cora) pair (CORA Vault holds the content;
the CORA plugin is the controls).

This guide covers how the repo is laid out, the rules that keep it reusable,
and how to make a change. For what the vault *is*, see the [README](README.md);
for the full structure and maintenance workflow, see [`SETUP.md`](SETUP.md).

---

## Ground rules

- **No personal content.** This repo is structure and mechanics only — empty
  templates, working scripts, no real names, projects, or private notes. Keep
  placeholders generic (`*(Fill in)*`, `your-name`, dates filled by `setup.sh`).
- **Keep the two halves in sync.** CORA Vault and the CORA plugin write the
  same files and frontmatter. If you change a file's schema — frontmatter
  fields, the `ACTIVITY.md` model, index formats, wikilink conventions — note
  in your PR whether the [CORA plugin](https://github.com/RychidM/cora) needs a
  matching change so the script path and the agent path don't drift.
- **One concern per PR.**
- **Match the surrounding style.** Mirror the conventions of the files you edit.

---

## Repository layout

| Path | What it is |
|------|------------|
| `AGENTS.md` | The entry point every agent reads — identity, projects, write-back protocol, cross-module rules. |
| `setup.sh` | One-time personalization for a freshly cloned vault. |
| `scripts/init-project.sh` | Scaffold a project/module from `_TEMPLATE` and register it. |
| `scripts/sync-memory.sh` | Generate per-repo agent files (`CLAUDE.md`/`GEMINI.md`/Copilot/Codex). |
| `scripts/memory-wrappers.sh` | Shell wrappers that keep those files fresh automatically. |
| `projects/_TEMPLATE/` | The skeleton `init-project.sh` copies for each new project. |
| `projects/`, `ideas/`, `brand/`, `research/`, `sessions/` | The vault's content areas (shipped empty / index-only). |
| `SETUP.md` | Full structure diagram and maintenance reference. |

---

## Working on the scripts

All four scripts are `#!/usr/bin/env bash`. Before opening a PR:

```bash
shellcheck setup.sh scripts/*.sh   # must be clean
for f in setup.sh scripts/*.sh; do bash -n "$f"; done
```

Both run in CI (`.github/workflows/ci.yml`) on every push and PR, alongside a
check that the required `_TEMPLATE` files still exist.

To test a change end-to-end, clone or copy the repo to a scratch directory and
run it there so you never commit personalized output:

```bash
cp -R . /tmp/cora-vault-test && cd /tmp/cora-vault-test
./setup.sh
scripts/init-project.sh demo
```

---

## Changing the template structure

If you add, remove, or rename files under `projects/_TEMPLATE/` (or add a new
top-level area):

1. Update `scripts/init-project.sh` so it copies/handles the new layout.
2. Update the required-files list in `.github/workflows/ci.yml`.
3. Update `SETUP.md` and `README.md` so the documented structure matches.
4. Consider whether the [CORA plugin](https://github.com/RychidM/cora)'s
   `cora-project-init` / `cora-lint` skills need the same change.

---

## Submitting a PR

1. Branch off `main`.
2. Make your change; run `shellcheck` / `bash -n` if you touched scripts.
3. Open a PR and fill in the template.
4. Keep it focused and the summary clear about what changed and why.

By contributing you agree your work is licensed under the project's
[MIT License](LICENSE).
