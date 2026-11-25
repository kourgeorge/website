#!/usr/bin/env bash
# Checks the static site: page files, titles, local links, stylesheet, nav order,
# the root redirect, the 404 page and the GitHub Pages files (CNAME, .nojekyll). Needs only standard macOS/Linux tools.
# Usage: bash tests/check-site.sh   (from anywhere)

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

fail=0
err() {
  echo "FAIL: $*" >&2
  fail=1
}

PAGES="home/index.html publications/index.html teaching/index.html links-resources/index.html"
NAV_PAGES="$PAGES 404.html"
ALL_HTML="index.html $NAV_PAGES"
EXPECTED_NAV="/home/|Home;/publications/|Publications;/teaching/|Teaching;/links-resources/|Links &amp; Resources;"

# 1. Files exist.
for f in $ALL_HTML; do
  [ -f "$f" ] || err "missing page file: $f"
done
[ -f assets/css/style.css ] || err "missing stylesheet: assets/css/style.css"
[ "$fail" -eq 0 ] || { echo "check-site: FAILED" >&2; exit 1; }

# Resolve a local address (as written in href/src/url()) to a file path.
# $1 = address, $2 = file it appears in.
resolve() {
  local ref="$1" from="$2" path
  path="${ref%%#*}"
  path="${path%%\?*}"
  [ -z "$path" ] && { echo ""; return; }
  case "$path" in
    /*) path="${path#/}" ;;
    *) path="$(dirname "$from")/$path" ;;
  esac
  [ -z "$path" ] && path="index.html"
  case "$path" in
    */) path="${path}index.html" ;;
  esac
  if [ -d "$path" ]; then path="$path/index.html"; fi
  echo "$path"
}

is_local() {
  case "$1" in
    http:*|https:*|//*|mailto:*|tel:*|data:*|javascript:*|\#*|"") return 1 ;;
  esac
  return 0
}

for f in $ALL_HTML; do
  flat="$(tr '\n\r' '  ' < "$f")"

  # 2. Title.
  if ! printf '%s' "$flat" | grep -Eq '<title>[^<]+</title>'; then
    err "$f has no <title>"
  fi

  # 3. Stylesheet link.
  if ! printf '%s' "$flat" | grep -Eq '<link[^>]*rel="stylesheet"[^>]*href="/assets/css/style\.css"'; then
    err "$f does not link to /assets/css/style.css"
  fi

  # 4. Every local href/src points to an existing file.
  refs="$(printf '%s' "$flat" | grep -Eo '(href|src)="[^"]*"' | sed -E 's/^(href|src)="//; s/"$//')"
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    is_local "$ref" || continue
    target="$(resolve "$ref" "$f")"
    [ -z "$target" ] && continue
    [ -f "$target" ] || err "$f links to '$ref', but $target does not exist"
  done <<EOF
$refs
EOF
done

# 4b. Local url(...) references in the stylesheet.
css_refs="$(grep -Eo 'url\([^)]*\)' assets/css/style.css | sed -E "s/^url\(//; s/\)$//; s/^[\"']//; s/[\"']$//")"
while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  is_local "$ref" || continue
  target="$(resolve "$ref" assets/css/style.css)"
  [ -f "$target" ] || err "assets/css/style.css refers to '$ref', but $target does not exist"
done <<EOF
$css_refs
EOF

# 5. Nav on every page lists the 4 pages in order.
for f in $NAV_PAGES; do
  nav="$(tr '\n\r' '  ' < "$f" | grep -Eo '<nav[^>]*>.*</nav>' | head -n 1)"
  if [ -z "$nav" ]; then
    err "$f has no <nav>"
    continue
  fi
  got="$(printf '%s' "$nav" | grep -Eo '<a [^>]*href="[^"]*"[^>]*>[^<]*</a>' \
    | sed -E 's/.*href="([^"]*)"[^>]*>([^<]*)<\/a>/\1|\2/' | tr '\n' ';')"
  if [ "$got" != "$EXPECTED_NAV" ]; then
    err "$f nav is wrong. Expected: $EXPECTED_NAV  Got: $got"
  fi
  # The site title links to /home/.
  if ! tr '\n\r' '  ' < "$f" | grep -Eq '<a class="site-title" href="/home/">George Kour, Ph\.D\.</a>'; then
    err "$f header has no site title 'George Kour, Ph.D.' linking to /home/"
  fi
done

# 6. Root index.html sends visitors to /home/.
root_flat="$(tr '\n\r' '  ' < index.html)"
printf '%s' "$root_flat" | grep -Eqi '<meta http-equiv="refresh" content="0; *url=/home/"' \
  || err "index.html has no meta refresh to /home/"
printf '%s' "$root_flat" | grep -Eq '<a href="/home/"' \
  || err "index.html has no plain link to /home/"
printf '%s' "$root_flat" | grep -Eq '<link rel="canonical" href="https://www\.kour\.me/home">' \
  || err "index.html has no canonical link to https://www.kour.me/home"

# 7. GitHub Pages files.
if [ -f CNAME ]; then
  cname="$(tr -d ' \t\r\n' < CNAME)"
  [ "$cname" = "www.kour.me" ] || err "CNAME should contain www.kour.me, but contains '$cname'"
else
  err "missing CNAME file"
fi
[ -f .nojekyll ] || err "missing .nojekyll file"

# 8. 404.html links back to the Home page (root-relative, so it works at any address).
tr '\n\r' '  ' < 404.html | grep -Eq '<main[^>]*>.*<a href="/home/"' \
  || err "404.html has no link to /home/ in its main content"

if [ "$fail" -ne 0 ]; then
  echo "check-site: FAILED" >&2
  exit 1
fi
echo "check-site: all checks passed"
