# Topics

LLM-maintained synthesis pages. One page per coherent research topic.

## What a topic page looks like

```markdown
---
type: research-topic
last_updated: YYYY-MM-DD
sources: 3
related: [[other-topic-a]], [[other-topic-b]]
projects: [[projects/{project}/...]]
---

# Topic Name

> One-sentence statement of what this topic covers.

## Summary

A few paragraphs synthesising what's known across all sources. Updated every time a new source is ingested.

## Key Claims

- Concrete factual claims, with citations to source files
  - Claim A — see [[../sources/articles/2026-06-02-example-source]]
  - Claim B — see [[../sources/analyses/2026-05-30-example-analysis]]

## Open Questions

- Things you still want to investigate

## Sources

- [[../sources/articles/2026-06-02-example-source]]
- [[../sources/analyses/2026-05-30-example-analysis]]
- [[../sources/notes/2026-06-01-example-notes]]
```

## Rules

- Topic pages are LLM-maintained. You don't write them directly (but can edit).
- Every claim should trace back to a source via a link.
- When sources disagree, the page documents the disagreement instead of picking one side.
- New sources added → topic page gets updated, not appended to. The synthesis stays current.
