#!/usr/bin/env bash
# Re-downloads George Kour's paper list from dblp, so _bibliography/papers.bib
# can be brought up to date by hand.
#
# IMPORTANT: this script does NOT overwrite _bibliography/papers.bib.
# papers.bib was cleaned up by hand after the dblp download:
#   - short keys (e.g. kour2025thinkagain) instead of DBLP:... keys;
#   - arXiv copies merged into the published version (arxiv= field);
#   - hand-added fields: selected, abbr, bibtex_show, pdf, html, note;
#   - papers that are not on dblp (bioRxiv 2019, SEC-2017, M.Sc. thesis).
# Copying the dblp file over papers.bib would lose all of that. Instead, this
# script saves the dblp file next to it and lists the dblp titles that are not
# yet in papers.bib. Copy those entries into papers.bib and clean them up the
# same way (merge the hand-added fields back in).
#
# dblp sometimes shows an "are you a bot" check to scripts. If the download
# fails, open https://dblp.org/pid/156/2971.bib in a browser, save the file and
# pass its path:  bash scripts/update-publications.sh ~/Downloads/2971.bib
#
# Usage: bash scripts/update-publications.sh [already-downloaded-dblp.bib]

set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PAPERS="$ROOT/_bibliography/papers.bib"
OUT="${TMPDIR:-/tmp}/dblp-kour.bib"
URL="https://dblp.org/pid/156/2971.bib"

if [ "$#" -ge 1 ]; then
  cp "$1" "$OUT"
else
  echo "Downloading $URL ..."
  curl -fsSL "$URL" -o "$OUT" || {
    echo "Download failed. Save $URL from a browser and pass the file path (see the notes at the top)." >&2
    exit 1
  }
fi

if ! grep -q '^@' "$OUT"; then
  echo "$OUT does not look like a BibTeX file (dblp may have shown a bot check)." >&2
  exit 1
fi

echo "Saved the dblp list to $OUT ($(grep -c '^@' "$OUT") entries)."

# Titles in a bib file, one per line, lower case, letters and digits only.
titles() {
  awk '
    /^[ \t]*title[ \t]*=/ { t = $0; open = 1 }
    open && !/^[ \t]*title[ \t]*=/ { t = t " " $0 }
    open && /},?[ \t]*$/ { print t; open = 0 }
  ' "$1" | sed -E 's/^[ \t]*title[ \t]*=[ \t]*\{//; s/\},?[ \t]*$//' |
    tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9\n'
}

# arXiv copies whose title differs from the published version already in
# papers.bib (they were merged into it on purpose).
MERGED="exploringstraightforwardconversationalredteaming
notenoughdatadeeplearningtotherescue"

missing="$(comm -23 <(titles "$OUT" | sort -u) <( (titles "$PAPERS"; echo "$MERGED") | sort -u))"
if [ -z "$missing" ]; then
  echo "Every dblp title is already in _bibliography/papers.bib."
else
  echo "dblp titles not found in _bibliography/papers.bib (letters and digits only):"
  echo "$missing" | sed 's/^/  - /'
  echo "Add these by hand (see the notes at the top of this script)."
fi
