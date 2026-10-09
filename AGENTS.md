# LLM Wiki Schema

> ⚠️ **UNCONFIGURED TEMPLATE.** The first action in a new repository is the `setup` skill: it asks what this wiki is for and configures categories, language and schema. Do not run ingest/query/lint until setup is done. Setup removes this banner.

A personal knowledge base maintained by an LLM: sources go in, the LLM compiles them into a persistent, interlinked wiki of markdown pages that compounds with every new source.

**Domain**: `{{filled in by setup}}`
**Page language**: `{{filled in by setup}}` — the language the user is comfortable reading. All wiki pages are written in it, whatever the language of the sources.

## Roles

- **The human** curates sources, directs the analysis, asks questions.
- **The LLM** is a disciplined wiki maintainer: writes and updates pages, keeps cross-links, index and log in shape. The LLM does all the routine work; the human never writes wiki pages by hand.

## Three layers

- `raw/` — sources. **Immutable**: the LLM reads them but never modifies them. Kept in their original language — never translated. Markdown sources are named `<name>.src.md` so they never share a name with their summary `wiki/sources/<name>.md` (Obsidian resolves links by file name, and a duplicate makes the link ambiguous). Images go in `raw/assets/`.
- `wiki/` — the wiki itself, written entirely by the LLM.
- `AGENTS.md` (this file; `CLAUDE.md` is a symlink to it, for Claude Code) — the schema: conventions and workflows. Evolves together with the user. Always edit `AGENTS.md`, never replace the symlink.

## wiki/ structure

| Folder/file | Contents |
|---|---|
| `index.md` | Catalog of all pages, grouped by category, one line per page (format below). Updated on every ingest |
| `log.md` | Append-only chronology of operations |
| `sources/` | Source summaries: one source in `raw/` = one page |
| `{{domain categories — filled in by setup}}` | |

index.md line format (a list, so the pipe is not escaped):

```
- [[page-name|Title]] — one-line summary (updated YYYY-MM-DD)
```

**Search.** Optional local semantic search over `wiki/` with [qmd](https://github.com/tobi/qmd) — it finds pages by meaning, across word forms and across languages (a query in the page language finds a page that uses the English term), which `grep` can't. On when `.qmd/` exists; turned on by `.claude/skills/setup/enable-search.sh "<wiki description>"`. Use `qmd vsearch "<question>" -n 8 --files` (a second or two); `qmd query` adds reranking for hard questions but is slower. Wherever the workflows say "grep `wiki/`", search with qmd too when it's on.

**Growth.** Once `index.md` passes ~300 lines, split it: each category gets `wiki/index-<category>.md` in the same format, and `index.md` becomes a list of those category indexes with a line on what each holds. `check-links.sh` treats every `index*.md` as an index.

New categories are added as needed — discuss with the user first, then record them here.

## Skills

Workflows live in `.claude/skills/<name>/SKILL.md` (`.agents/skills` is a symlink to it, for Codex; Cursor and VS Code Copilot read `.claude/skills` directly) — when the user asks for one, follow that file step by step instead of working from memory (agents with skill support invoke it as a skill; others read the SKILL.md):

- **setup** — one-time configuration of the template for a domain
- **ingest** — integrate one source (file / URL / pasted text)
- **lint** — wiki health check
- **file** — file a valuable answer from the chat into the wiki

Mechanical checks (duplicate names, broken links, orphans, index completeness, self-links, unused assets) are done by `.claude/skills/lint/check-links.sh`, run at the end of every workflow. If search is on (`.qmd/` exists), refresh it right after: `.claude/skills/setup/enable-search.sh`. After the check passes, commit the workflow's changes with the log heading as the message (e.g. `ingest | Source title`).

## Page conventions

- **File names**: Latin characters, kebab-case, unique across the whole vault (the repository is the Obsidian vault). The human-readable title goes in `aliases`.
- **Frontmatter** (YAML) on every page:

```yaml
---
type: source | {{domain types — filled in by setup}}
aliases: []  # human-readable titles in the page language — Obsidian finds and links the page by them
tags: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources: []  # pages in wiki/sources/ the content rests on, in quotes: ["[[source-page]]"]; empty on a source page itself
---
```

- **Links**: Obsidian style — double-bracket links to a file name, optionally with `|display text`. Inside tables escape the pipe as `\|`. To show link syntax as an example, put it in inline code — otherwise it becomes a real link. Link generously — connections are worth more than the pages themselves.
- **Page skeletons** — the body structure of each `type:`, so pages of one kind stay comparable:

{{per-type page skeletons — filled in by setup}}

- Skeleton sections with nothing to say are omitted, not filled with "no data".
- A page past ~1500 words is split: the subtopics get pages of their own, the original keeps the overview and links to them.
- Every page ends with a **Related** section (wiki links) and a **Sources** section (links to pages in `sources/` and/or external URLs). Section headings are written in the page language.
- **Only what the sources say.** Every fact on a page traces to a file in `raw/`; the LLM's own background knowledge stays out (it can suggest a source instead). Connections the LLM draws between sources are welcome — phrased as a connection and linked to both sides.
- A new source contradicting an existing page is never silently absorbed: mark it on the page with a `> [!warning]` callout titled "Contradiction" in the page language, citing both sources. A contradiction means incompatible claims; different emphasis or terminology is written as plain text.
- Open questions and unfinished parts go in a `> [!todo]` callout — lint collects them.

## Workflows

- **Ingest** — `ingest` skill. One source at a time; discuss key takeaways with the user before writing.
- **Lint** — `lint` skill, periodically or on request.
- **Query** — no skill, follow these steps:
  1. Read `index.md` first (and the category indexes it points to, once split), find the relevant pages. Then search `wiki/` — `qmd vsearch` with the question if search is on, `grep -ril` for the key terms either way — the index lists pages, not every mention.
  2. Read them and synthesize an answer with citations and links to the pages. If the wiki doesn't cover the question, say so and suggest sources to ingest rather than answering from background knowledge.
  3. If the answer is valuable (a comparison, an analysis, a discovered connection) — offer to file it via the `file` skill. An answer that isn't filed leaves no trace in the wiki or the log.

## log.md format

Every entry starts with a greppable heading:

```
## [YYYY-MM-DD] ingest | Source title
## [YYYY-MM-DD] query | Gist of the question
## [YYYY-MM-DD] lint | What was checked
## [YYYY-MM-DD] meta | Schema/structure/skill change
```

Latest entries: `grep "^## \[" wiki/log.md | tail -5`.
