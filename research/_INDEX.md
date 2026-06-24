---
type: index
section: research
last_updated: {{TODAY}}
---

# Research Library — Index

A catalog of all topic pages in the research library, with one-line summaries.

If you've installed an ingest skill/command, it updates this file when new topics are created, and can flag topics mentioned in projects that don't yet have a page here.

---

## Topics

| Topic | Summary | Sources | Last Updated |
|-------|---------|---------|--------------|
| *(empty — populated as you ingest sources)* | | | |

---

## How this works

1. Drop a source into `research/sources/{articles|docs|analyses|notes}/`
2. Tell any agent: *"ingest this"*
3. The agent reads the source, extracts key claims, updates the relevant `research/topics/{topic}.md` page (creating it if needed), and appends an entry to `_logs/INGEST_LOG.md`
4. Topic pages cross-link with each other and with `projects/...` when relevant

## Naming conventions

- **Source files:** `YYYY-MM-DD-short-slug.md` — keeps them chronologically sortable
- **Topic pages:** `kebab-case-topic-name.md` — broad enough to accumulate sources, narrow enough to be coherent

## When to create a new topic vs. add to an existing one

- New source covers a topic already in the library → add to the existing page
- New source covers a related-but-distinct topic → new page, cross-link to the related one
- Unsure → use your judgment, or ask whoever's reviewing the work
