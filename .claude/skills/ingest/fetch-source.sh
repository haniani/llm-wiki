#!/usr/bin/env bash
# Captures a web page into raw/: full text as markdown + every image it references, downloaded into raw/assets/.
# Usage: fetch-source.sh <url> <kebab-name>  →  raw/<kebab-name>.src.md, raw/assets/<kebab-name>-NN.<ext>
# Extractors, first that works:
#   1. the file itself, when the URL is already markdown/plain text (a .md link, raw.githubusercontent.com, a GitHub gist → /raw);
#   2. Jina Reader (https://r.jina.ai, a public service; needs only curl, the URL is sent to it) — keeps headings, lists, images;
#   3. trafilatura (`uvx trafilatura`, or `trafilatura` from pip) — local, but may drop headings and images on some sites.
# Images that fail to download keep their remote URL and are listed at the end. Needs bash + curl only.
set -u
url=${1:?usage: fetch-source.sh <url> <kebab-name>}
name=${2:?usage: fetch-source.sh <url> <kebab-name>}
cd "$(git rev-parse --show-toplevel)" || exit 2
out="raw/$name.src.md"
[ -e "$out" ] && { echo "$out already exists — raw/ is immutable, pick another name"; exit 2; }
mkdir -p raw/assets
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

raw_url=""
case "$url" in
  https://gist.github.com/*) raw_url="${url%/}/raw" ;;
  *.md|*.markdown|*.txt|https://raw.githubusercontent.com/*) raw_url=$url ;;
esac
traf_flags="--markdown --formatting --images --recall --no-comments --with-metadata"

extractor=""
if [ -n "$raw_url" ] && curl -fsSL "$raw_url" >"$tmp" 2>/dev/null && [ -s "$tmp" ]; then
  extractor="original file"
elif curl -fsSL "https://r.jina.ai/$url" >"$tmp" 2>/dev/null && [ -s "$tmp" ]; then
  extractor="Jina Reader"
elif command -v uvx >/dev/null && uvx --quiet trafilatura $traf_flags -u "$url" >"$tmp" 2>/dev/null && [ -s "$tmp" ]; then
  extractor="trafilatura (uvx)"
elif command -v trafilatura >/dev/null && trafilatura $traf_flags -u "$url" >"$tmp" 2>/dev/null && [ -s "$tmp" ]; then
  extractor="trafilatura"
else
  echo "Could not extract $url with any extractor — ask the user to save the page into raw/ themselves."
  exit 1
fi

content=$(cat "$tmp")
origin=$(printf '%s' "$url" | sed -E 's#^(https?://[^/]+).*#\1#')
base=$(printf '%s' "$url" | sed -E 's#[?#].*##; s#/[^/]*$#/#')

n=0 ok=0 failed=""
while IFS= read -r src; do
  [ -n "$src" ] || continue
  case "$src" in
    data:*|assets/*) continue ;;
    http://*|https://*) abs=$src ;;
    //*) abs="https:$src" ;;
    /*) abs="$origin$src" ;;
    *) abs="$base$src" ;;
  esac
  n=$((n + 1))
  # Extension from the response Content-Type — image URLs often have none, or a misleading one.
  if type=$(curl -fsSL --max-time 60 -o "raw/assets/$name-part" -w '%{content_type}' "$abs"); then
    case "$type" in
      *png*) ext=png ;; *jpeg*|*jpg*) ext=jpg ;; *gif*) ext=gif ;; *webp*) ext=webp ;;
      *svg*) ext=svg ;; *avif*) ext=avif ;;
      *) ext=$(printf '%s' "$abs" | sed -E 's#[?#].*##; s#.*/##' | grep -oE '\.[a-zA-Z0-9]{2,4}$' | tr -d . | tr '[:upper:]' '[:lower:]') ;;
    esac
    file="$name-$(printf '%02d' "$n").${ext:-img}"
    mv "raw/assets/$name-part" "raw/assets/$file"
    content=${content//"($src"/"(assets/$file"}
    ok=$((ok + 1))
  else
    rm -f "raw/assets/$name-part"
    failed="$failed\n  $abs"
  fi
done <<EOF
$(printf '%s\n' "$content" | grep -oE '!\[[^]]*\]\([^) ]+' | sed -E 's/.*\]\(//' | awk '!seen[$0]++')
EOF

printf '<!-- Captured %s from %s via %s -->\n\n%s\n' "$(date +%F)" "$url" "$extractor" "$content" >"$out"
echo "Saved $out via $extractor: $(wc -w <"$out" | tr -d ' ') words, $ok/$n images in raw/assets/"
[ -n "$failed" ] && printf "Images left remote (download failed):$failed\n"
exit 0
