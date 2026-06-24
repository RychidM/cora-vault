---
purpose: research-ingest-log
instructions: Chronological record of source ingests. Append-only. Each entry starts with `## [YYYY-MM-DD]` for grep-friendly parsing.
---

# 📚 Ingest Log

Chronological record of every source ingested into the research library and what topics it touched.

**Format:**

```
## [YYYY-MM-DD] {source filename}

**Source:** `research/sources/{category}/{filename}.md`
**Topics touched:** [[research/topics/topic-a]], [[research/topics/topic-b]]
**Projects linked:** [[projects/{project}/...]] (optional)

One-paragraph summary of what was learned and what changed in the topic pages.
```

To see recent activity from the terminal:

```bash
grep "^## \[" research/_logs/INGEST_LOG.md | tail -10
```

---

<!-- AGENTS: Append new ingest entries below this line. Most recent at the bottom. -->
