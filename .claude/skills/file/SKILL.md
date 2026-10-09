---
name: file
description: Use when a valuable answer, comparison, or analysis emerged in conversation and the user wants it saved to the wiki ("file this", "save this to the wiki", "add it as a page", "зафайли это", "сохрани в вики").
---

# Filing an answer into the wiki

A valuable answer from the chat (a comparison, an analysis, a discovered connection) becomes a page — otherwise it disappears into the history. This is a mini-ingest: page + links + index + log.

## Steps

1. **Pick the location** from the category table in AGENTS.md; if no category fits — ask the user (maybe it's time for a new one, recorded in the schema).
2. **Write the page** following AGENTS.md conventions and its type's skeleton: frontmatter (`aliases:` with a readable title; `sources:` lists the source pages behind the pages the answer draws on), the answer itself, Related, Sources. A wiki page, not a chat transcript: no "you asked / I answered".
3. **Links both ways**: the pages the answer draws on go in the new page's Related; the ones central to it (usually 2–5, not every page touched) get a link back under their own Related.
4. **Index + log.md** — a line in `index.md` (or the category index, once split); log entry (`## [YYYY-MM-DD] query | <gist of the question>` + the name of the created page).
5. **`.claude/skills/lint/check-links.sh`** — make sure nothing is broken, then commit (`query | <gist of the question>`).

## Red flags

- The page retells the dialogue ("the user asked…") → rewrite it as a standalone wiki page.
- Filed, but index/log untouched → an invisible page; step 4 is part of filing.
- The answer adds facts not found on the wiki pages or in `raw/` → drop them, or first ingest a source that has them.
- The answer is based on wiki pages, but `sources:` is empty and there are no backlinks → the knowledge won't compound; add the links.
