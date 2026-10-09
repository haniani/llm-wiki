---
name: setup
description: Use when the wiki template is not yet configured — AGENTS.md contains the "UNCONFIGURED TEMPLATE" banner — or the user asks to set up / re-tune the wiki ("set up the wiki", "setup", "настрой вики").
---

# Configuring the template for a domain

A one-time skill: turns the generic template into a wiki for a specific domain. Setup is a DIALOGUE, not guesswork: the user approves categories and skills.

## Steps

1. **Ask the user** (in one go, with a structured question tool such as AskUserQuestion where the agent has one):
   - What is the wiki for? (domain: researching a topic, book notes, interview prep, work knowledge, a hobby…)
   - Page language? (the language the user is comfortable reading; sources in `raw/` stay in their original language regardless)
   - Turn on local semantic search (qmd) now or later? It finds pages by meaning and across languages; needs Node.js 22+ and a one-time ~2.4 GB model download. Worth it from the start for a big domain, otherwise once the wiki reaches a few hundred pages.
2. **Propose categories** for the domain: 4–8 folders besides `sources/` in `wiki/` + matching `type:` values for frontmatter. Show them as a "folder → contents" table and wait for approval/edits. `sources/`, `index.md`, `log.md` are always there, and one category is always for filed answers from the chat (comparisons, analyses — the `file` skill's target), named for the domain.
   Together with the categories, propose a **skeleton for every `type:`** (including `source`): 3–6 section headings in the page language with a one-line purpose each, not counting the mandatory Related and Sources — e.g. for a book-notes `source`: key ideas, quotes, disagreements, what to apply. These are what keeps the wiki consistent across dozens of ingests. Types that several sources will write about (concepts, patterns…) get a section for how the sources differ. No "open questions" section — those go in `> [!todo]` callouts, which lint collects.
3. **Create the structure**: `wiki/sources/` and the category folders, each with a `.gitkeep` (delete `wiki/.gitkeep`; ingest removes a folder's `.gitkeep` once it has pages), `wiki/index.md` (skeleton with the approved categories), `wiki/log.md` with the entry `## [YYYY-MM-DD] meta | Template configured for <domain>`.
4. **Rewrite AGENTS.md**: remove the "UNCONFIGURED TEMPLATE" banner, fill in domain, language, the structure table, the list of `type:` values in frontmatter, the approved page skeletons. Every `{{…}}` placeholder must disappear. AGENTS.md itself stays in English; only the wiki pages (and the skeleton headings quoted in AGENTS.md) use the chosen language.
5. **Propose 0–2 domain skills** — none is a fine outcome when ingest/query/file already cover the domain's workflows; otherwise specialized workflows on top of ingest (e.g. for interview prep, a debrief of an interview; for book notes, filing a chapter). Describe to the user what the skill will do; create only the approved ones. Same format as the existing skills: a description with triggers only (no retelling of the workflow), recipe-style steps, red flags, and a `check-links.sh` run at the end. Register new skills in the Skills section of AGENTS.md.
6. **Update README.md** (in the page language): the wiki's name and purpose instead of the template description (keep the prerequisites and the section on how to use the wiki after setup).
   If the user wants search now: `npm install -g @tobilu/qmd` if `qmd` is missing, then `.claude/skills/setup/enable-search.sh "<one-line domain description>"`.
7. **Verify**: `.claude/skills/lint/check-links.sh` passes; `grep -c '{{' AGENTS.md` returns 0.
8. **Commit** (`meta | Template configured for <domain>`) and show the user the result: structure, skills, what to do next (the first ingest), how to open the repository as an Obsidian vault, and — if search was left off — that it can be turned on later with attachment folder = `raw/assets`.

Re-tuning a wiki that already has pages: same dialogue, plus a migration — pages moved to renamed folders, `type:` values and skeletons updated on existing pages, links rechecked. Show the migration list before touching anything.

## Red flags

- Invented categories and created them silently → step 2 requires the user's approval.
- The banner or `{{placeholders}}` are still in AGENTS.md → setup isn't finished; step 7 catches this.
- Created a domain skill the user didn't approve → create only what was agreed.
- A new domain skill's description retells its workflow → the agent will follow the description and skip the body; triggers only.
