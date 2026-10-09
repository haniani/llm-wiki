---
name: ingest
description: Use when the user asks to ingest a source into the wiki — a file in raw/, a URL, or pasted text ("ingest this", "add this source", "process this article", "заингести", "добавь источник", "обработай статью").
---

# Ingesting a source into the wiki

Integrates ONE source into the wiki following the schema in AGENTS.md. Not a batch: several sources means several sequential runs.

## Steps (all mandatory, in order)

1. **Get the source into `raw/`.**
   - Already a file in `raw/` → content stays untouched; a markdown file not yet named `<name>.src.md` is renamed to it (`git mv`).
   - URL → `.claude/skills/ingest/fetch-source.sh <URL> <kebab-name>`: saves the full text as markdown in the original language to `raw/<kebab-name>.src.md` and downloads every image into `raw/assets/` with the links rewritten. Do NOT use WebFetch for this — it returns a model-condensed rendering, not the text. Skim the capture against the page: headings, lists and code present, no big holes. Site boilerplate or comments that came along stay in raw — just ignore them when writing. If the extraction is clearly incomplete (paywall, JS-only page, a fraction of the article) — stop and ask the user to save the page themselves (Obsidian Web Clipper, or copy-paste) into `raw/`.
   - Pasted text → save verbatim as `raw/<kebab-name>.src.md`.
2. **Read the source in full.** Not a diff, not a skim. If it has local images, look at them separately after the text. A source too long to hold at once (a book, a long report — roughly 30k+ words) is ingested in parts: one chapter or section per run, steps 3–9 each time, the summary page growing part by part, log entries `ingest | Title (part N)`.
3. **Discuss key takeaways with the user** and ask what to emphasize. Wait for the answer. Skip this step only if the user said up front "no discussion / batch".
4. **Write the summary** in `wiki/sources/<kebab-name>.md` following AGENTS.md conventions (frontmatter with `aliases`, the `source` page skeleton, Related, Sources). Written in the page language from AGENTS.md, even when the source is in another language; keep key terms in the original next to the translation where it helps.
5. **Update/create affected pages** in the categories from AGENTS.md, new ones following their type's skeleton.
   - Update existing pages first; that is where the wiki compounds. Find them through the index, `qmd vsearch` on the source's main topics (if search is on — see AGENTS.md) and `grep -ril` for its key terms over `wiki/` — the index alone misses pages that mention a topic without being about it. Each fact has one home: the detail goes on the topic page, the source summary states it in a line and links there. Create a new page only for something the source says enough about to fill it — a name mentioned in passing gets a sentence on an existing page, not a page of its own. Fewer rich pages beat many stubs.
   - A skeleton section with nothing to put in it is left out — never "not in the source" / "none yet".
   - Every fact comes from a source in `raw/`. Your own background knowledge does not go into pages; if it matters, raise it with the user as a candidate source to find. Connections between sources ("X is a form of Y") are the wiki's value — write them, as a connection, with links to both sides.
   - A contradiction — two sources asserting incompatible things — → a `> [!warning]` callout titled "Contradiction" in the page language, citing both sources, never a silent rewrite. Put it on the one page where the topic lives and link to it from the others; differences of emphasis or terminology are a plain sentence, not a callout. Also update the summary of the older source that is contradicted.
6. **Update the index** (`wiki/index.md`, or the category's `index-<category>.md` once split — see Growth in AGENTS.md) — a line for every new page in its category section, a fresh date on updated ones; delete the `.gitkeep` of a folder that just got its first page. One date for the whole operation: the day it started.
7. **Append an entry to `wiki/log.md`**: `## [YYYY-MM-DD] ingest | Title` + the list of created/updated pages.
8. **Check links** — run `.claude/skills/lint/check-links.sh`. Fix duplicate names and broken links immediately; on a duplicate, rename the wiki page, never a file in `raw/`. Then commit (`ingest | Title`).
9. **Show the user the result**: what was created, what was updated, which connections appeared.

## Red flags — stop

- About to edit a file in `raw/` → not allowed, raw is immutable. Two exceptions: the one-time `.src.md` rename in step 1, and replacing a capture that turned out incomplete with the full text of the same source — with the user's approval, followed by re-reading it and updating its summary.
- About to save a summary or a WebFetch rendering to `raw/` as the source → raw holds the original text; if you can't get it, say so and stop.
- Translating the source while saving it to `raw/` → raw keeps the original language; translation happens only in the wiki pages.
- Summary written, but "I'll update the index later" → steps 6–7 are part of ingest, not an optional tail.
- A new page that is two sentences, or skeleton sections filled with "not in the source" → fold it into an existing page instead.
- A detail, example or number on a page that you can't point to in `raw/` → remove it.
- A wiki link to a page that doesn't exist and that you aren't creating in this run → either create it or don't link.
- An example of double-bracket link syntax in plain page text → Obsidian treats it as a real link; put examples in inline code.
