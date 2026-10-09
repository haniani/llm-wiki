#!/usr/bin/env bash
# Turns on local semantic search over wiki/ with qmd (https://github.com/tobi/qmd), or refreshes it.
# Usage: enable-search.sh "<one-line description of the wiki, in English>"
# Idempotent: on a fresh clone it creates the index, afterwards it just reindexes.
# The index lives in .qmd/ (git-ignored: its config holds this machine's absolute path).
# Needs Node.js 22+; the first run downloads ~2.4 GB of local models into ~/.cache/qmd/.
set -eu
cd "$(git rev-parse --show-toplevel)"
command -v qmd >/dev/null || { echo "qmd is not installed: npm install -g @tobilu/qmd (needs Node.js 22+)"; exit 2; }

if [ ! -f .qmd/index.yml ]; then
  desc=${1:?usage: enable-search.sh "<one-line description of the wiki>"}
  qmd init >/dev/null
  # Multilingual embeddings: the default embeddinggemma is English-optimized, and wiki pages
  # mix the page language with English terms.
  awk '/^  embed:/ { print "  embed: hf:Qwen/Qwen3-Embedding-0.6B-GGUF/Qwen3-Embedding-0.6B-Q8_0.gguf"; next } { print }' \
    .qmd/index.yml >.qmd/index.yml.tmp && mv .qmd/index.yml.tmp .qmd/index.yml
  qmd collection add wiki --name wiki >/dev/null
  qmd context add qmd://wiki "$desc" >/dev/null
fi

qmd update | grep -i 'indexed' || true
qmd embed | grep -iE 'done|nothing|up to date' || true
