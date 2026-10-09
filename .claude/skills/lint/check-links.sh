#!/usr/bin/env bash
# Mechanical wiki checks: duplicate note names, broken wiki links, orphan pages, pages missing from the index,
# self-links, unused files in raw/assets/. Every check is a single pass, so it stays fast on thousands of pages.
# Link resolution mirrors Obsidian: by file name, case-insensitive, across the whole vault (the repo minus dot-folders).
# Exit code: 1 if there are duplicate names or broken links (fix them right away), 0 otherwise (the rest are warnings).
# Index files: wiki/index.md, plus per-category wiki/index-<category>.md once the main index is split.
cd "$(git rev-parse --show-toplevel)" || exit 2
[ -d wiki ] || { echo "no wiki/ directory"; exit 2; }

tab=$(printf '\t')
lower() { tr '[:upper:]' '[:lower:]'; }

# All vault files, dot-folders (.git, .obsidian, .claude) excluded — Obsidian ignores them too.
vault_files=$(find . -path './.*' -prune -o -type f -print | sed 's#^\./##' | sort)
# Names a link can resolve to: notes by name without .md, other files (images, PDFs) by full name.
note_names=$(printf '%s\n' "$vault_files" | grep '\.md$' | sed -E 's#.*/##; s/\.md$//' | lower)
file_names=$(printf '%s\n' "$vault_files" | grep -v '\.md$' | sed -E 's#.*/##' | lower)

# One line per link: "<source file><TAB><target, lowercased>".
# Handles [[page]], [[page|alias]], [[page#heading]], [[page^block]], [[folder/page]], ![[embed.png]]
# and [[page\|alias]] (the escaped pipe Obsidian requires inside tables).
# Links inside fenced code blocks and inline code are skipped — Obsidian doesn't treat them as links.
links=$(find wiki -name '*.md' -exec awk '
  FNR == 1 { fence = "" }
  {
    line = $0
    if (fence != "") { if (line ~ "^[ \t]*" fence) fence = ""; next }
    if (match(line, /^[ \t]*(```|~~~)/)) { fence = substr(line, RSTART, RLENGTH); sub(/^[ \t]*/, "", fence); next }
    while (match(line, /`[^`]*`/)) line = substr(line, 1, RSTART - 1) substr(line, RSTART + RLENGTH)
    while (match(line, /\[\[[^]|#^]+/)) {
      t = substr(line, RSTART + 2, RLENGTH - 2); line = substr(line, RSTART + RLENGTH)
      sub(/\\$/, "", t); sub(/[ \t]+$/, "", t)
      n = split(t, parts, "/"); t = tolower(parts[n]); sub(/\.md$/, "", t)
      print FILENAME "\t" t
    }
  }' {} +)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
printf '%s\n' "$links" | grep -v '^$' >"$tmp/links"
printf '%s\n%s\n' "$note_names" "$file_names" | grep -v '^$' >"$tmp/names"
find wiki -name '*.md' | sort >"$tmp/pages"

# Pages the checks below skip or treat as indexes (by lowercased base name).
is_index='^index(-.*)?$'

fail=0
echo "== Duplicate note names (a link to them is ambiguous in Obsidian) =="
dups=$(printf '%s\n' "$note_names" | sort | uniq -d)
if [ -n "$dups" ]; then
  printf '%s\n' "$dups" >"$tmp/dups"
  printf '%s\n' "$vault_files" | grep '\.md$' | awk 'NR == FNR { d[$0] = 1; next }
    { b = $0; sub(/.*\//, "", b); sub(/\.md$/, "", b); b = tolower(b); if (b in d) print b "\t" $0 }' "$tmp/dups" - |
    sort | awk -F'\t' '$1 != prev { print "DUPLICATE: " $1; prev = $1 } { print "  - " $2 }'
  fail=1
else
  echo "ok"
fi

echo "== Broken wiki links =="
awk -F'\t' 'NR == FNR { ok[$0] = 1; next } !($2 in ok)' "$tmp/names" "$tmp/links" | sort -t"$tab" -k2,2 -k1,1 -u |
  awk -F'\t' '$2 != prev { print "BROKEN: [[" $2 "]]"; prev = $2 } { print "  <- " $1 }' >"$tmp/broken"
if [ -s "$tmp/broken" ]; then cat "$tmp/broken"; fail=1; else echo "ok"; fi

# base <path> → lowercased file name without .md (awk helper, inlined below)
base='function base(p) { sub(/.*\//, "", p); sub(/\.md$/, "", p); return tolower(p) }'

echo "== Orphan pages (no incoming links; index files and log.md don't count) =="
awk -F'\t' -v ix="$is_index" "$base"'
  NR == FNR { s = base($1); if (s !~ ix && s != "log" && s != $2) linked[$2] = 1; next }
  { n = base($0); if (n !~ ix && n != "log" && !(n in linked)) print "ORPHAN: " $0 }' "$tmp/links" "$tmp/pages" >"$tmp/out"
if [ -s "$tmp/out" ]; then cat "$tmp/out"; else echo "ok"; fi

echo "== Pages missing from the index =="
if [ ! -f wiki/index.md ]; then
  echo "wiki/index.md does not exist"
else
  awk -F'\t' -v ix="$is_index" "$base"'
    NR == FNR { if (base($1) ~ ix) indexed[$2] = 1; next }
    { n = base($0); if (n != "index" && n != "log" && !(n in indexed)) print "NOT IN INDEX: " $0 }' "$tmp/links" "$tmp/pages" >"$tmp/out"
  if [ -s "$tmp/out" ]; then cat "$tmp/out"; else echo "ok"; fi
fi

echo "== Self-links (a page linking to itself, usually in Related) =="
awk -F'\t' "$base"' base($1) == $2 { print "SELF-LINK: " $1 }' "$tmp/links" | sort -u >"$tmp/out"
if [ -s "$tmp/out" ]; then cat "$tmp/out"; else echo "ok"; fi

echo "== Unused files in raw/assets/ (referenced by no page and no source) =="
find raw/assets -type f ! -name '.gitkeep' 2>/dev/null | sed 's#.*/##' | sort >"$tmp/assets"
if [ -s "$tmp/assets" ]; then
  find raw wiki -name '*.md' -exec grep -hoiF -f "$tmp/assets" {} + 2>/dev/null | lower | sort -u >"$tmp/used"
  lower <"$tmp/assets" | sort | comm -23 - "$tmp/used" | sed 's#^#UNUSED: raw/assets/#' >"$tmp/out"
  if [ -s "$tmp/out" ]; then cat "$tmp/out"; else echo "ok"; fi
else
  echo "ok"
fi

exit "$fail"
