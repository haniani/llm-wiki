---
name: lint
description: Use when the user asks to health-check the wiki ("lint the wiki", "check the wiki", "what's wrong with the wiki", "сделай lint", "проверь вики") or after a large batch of changes.
---

# Wiki lint

A two-layer health check: mechanical (script) and semantic (reading). The output is a REPORT; fix things only after the user confirms (except duplicate names and broken links — those can be fixed right away).

## Steps

1. **Mechanics**: run `.claude/skills/lint/check-links.sh`. It finds duplicate note names (ambiguous links in Obsidian), broken wiki links, orphan pages (no incoming links), pages missing from the index, pages linking to themselves and unused files in `raw/assets/`.
2. **Semantic pass** (read the pages, not just the index). Scope: by default the pages changed since the last lint (`git log --grep='^lint |' -1` gives the commit; `git diff --name-only <commit> -- wiki/`) plus the pages they link to; the whole wiki when the user asks or there was no lint yet. A whole-wiki pass over more pages than fit in one read goes category by category, one subagent per category, then a pass over the cross-category findings.
   Check:
   - contradictions between pages;
   - claims made stale by newer sources (compare dates in frontmatter);
   - concepts mentioned on 3+ pages, with enough material in the sources to fill a page, but without a page of their own;
   - stub pages (a couple of sentences) → fold into a related page; pages past ~1500 words → propose a split; an index past ~300 lines → propose splitting it by category, and turning on search if it's off; skeleton sections filled with "no data" / "none yet" → remove or fill;
   - claims that can't be traced to `raw/` (details, examples, numbers from outside the sources);
   - frontmatter: required fields present, `type:` one of the values in AGENTS.md, `sources:` pointing to pages in `sources/`;
   - `raw/` files that aren't the full original (a summary, a truncated capture) → propose re-capturing via ingest;
   - missing cross-links (pages about the same thing that aren't linked) — with search on, `qmd vsearch` a page's topic and compare the hits with its links;
   - unresolved `> [!todo]` callouts;
   - gaps a web search would close — suggest sources.
3. **Report to the user** by category, in order of importance: contradictions → duplicate names and broken links → orphans → gaps. For each item — the specific file and the proposed action.
4. After confirmation — fix what was agreed, update the index if needed.
5. **log.md**: `## [YYYY-MM-DD] lint | <what was checked>` + what was found/fixed. Rerun the script if anything was fixed, then commit (`lint | <what was checked>`).

## Red flags

- Quietly "improved" pages during the check → lint reads and reports; edits come after confirmation (exception: duplicate names and broken links).
- An "all good" report without running the script → step 1 is not optional.
- Deleted an orphan page → an orphan is fixed by a link from a relevant page or the index; deletion only on the user's decision.
