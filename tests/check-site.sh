#!/usr/bin/env bash
# Builds the al-folio (Jekyll) site into _site and checks the result:
# the 4 page addresses, the root redirect to /home/, page titles, the nav
# (Home, Publications, Teaching, Links & Resources, in that order), the CNAME,
# the 404 page and that every local href/src points to a file in _site.
# Needs Homebrew Ruby (see the PATH below) and the gems from the Gemfile.
# Usage: bash tests/check-site.sh   (from anywhere)

set -u

export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

fail=0
err() {
  echo "FAIL: $*" >&2
  fail=1
}

# 1. Build the site (quietly). Install the gems first if they are missing.
if ! bundle check >/dev/null 2>&1; then
  bundle install --quiet >/tmp/check-site-bundle.log 2>&1 || {
    echo "FAIL: bundle install failed (see /tmp/check-site-bundle.log)" >&2
    exit 1
  }
fi
rm -rf _site
if ! bundle exec jekyll build --quiet --destination _site >/tmp/check-site-build.log 2>&1; then
  cat /tmp/check-site-build.log >&2
  echo "FAIL: bundle exec jekyll build failed" >&2
  exit 1
fi

SITE="$ROOT/_site"
PAGES="home/index.html publications/index.html teaching/index.html links-resources/index.html"

# 2. Page files exist.
for f in $PAGES index.html 404.html; do
  [ -f "$SITE/$f" ] || err "missing page in _site: $f"
done
[ "$fail" -eq 0 ] || { echo "check-site: FAILED" >&2; exit 1; }

# Put a page on one line, so tags that span lines can be matched.
flat() { tr '\n\r' '  ' <"$SITE/$1"; }

# 3. The root page sends visitors to /home/.
root_html="$(flat index.html)"
echo "$root_html" | grep -Eqi '<meta http-equiv="refresh" content="[0-9]+; *url=/home/"' ||
  err "index.html: no meta refresh to /home/"
echo "$root_html" | grep -qi '<link rel="canonical" href="https://www.kour.me/home"' ||
  err "index.html: no canonical link to https://www.kour.me/home"

# 4. Every page has a non-empty <title>.
for f in $PAGES index.html 404.html; do
  flat "$f" | grep -Eqi '<title>[[:space:]]*[^<[:space:]][^<]*</title>' || err "$f: missing or empty <title>"
done

# 5. The nav lists the 4 pages, in order, with the right labels and addresses.
EXPECTED_NAV="/home/|Home;/publications/|Publications;/teaching/|Teaching;/links-resources/|Links & Resources;"
for f in $PAGES 404.html; do
  nav="$(flat "$f" | sed -n 's:.*<nav id="navbar"\(.*\)</nav>.*:\1:p')"
  [ -n "$nav" ] || { err "$f: no <nav id=\"navbar\">"; continue; }
  got="$(echo "$nav" | grep -o '<a class="nav-link"[^>]*href="[^"]*">[^<]*' |
    sed -e 's:.*href="\([^"]*\)">[[:space:]]*\(.*\):\1|\2:' -e 's/[[:space:]]*$//' -e 's/&amp;/\&/g' |
    tr '\n' ';')"
  [ "$got" = "$EXPECTED_NAV" ] || err "$f: nav is '$got', expected '$EXPECTED_NAV'"
done

# 6. Old Google Sites heading anchors are kept.
check_ids() {
  local f="$1"; shift
  for id in "$@"; do
    grep -q "id=\"$id\"" "$SITE/$f" || err "$f: missing heading anchor id=\"$id\""
  done
}
check_ids home/index.html h.q4wcjinfbaz1 h.p_lujnsfikmTVd h.p_zqA8I2zFqZvP
check_ids publications/index.html h.fclsdrvmgzrm h.p_xY_nY1xX4Ypv
check_ids teaching/index.html h.ao2ziu9eq497 h.p_oQxnhJbmk8UM h.k58d4jgpt5mj h.hrj399f848kb
check_ids links-resources/index.html h.p_kd8WZCiBFKhc h.p_9RovSi7yLXnI

# 7. CNAME is copied into _site with the domain.
if [ -f "$SITE/CNAME" ]; then
  [ "$(tr -d '[:space:]' <"$SITE/CNAME")" = "www.kour.me" ] || err "_site/CNAME is not www.kour.me"
else
  err "missing _site/CNAME"
fi

# 8. Every local href/src points to a file in _site.
for f in $PAGES index.html 404.html; do
  for addr in $(flat "$f" | grep -Eo '(href|src)=["'"'"'][^"'"'"']*["'"'"']' |
    sed -E 's/^(href|src)=.//; s/.$//'); do
    case "$addr" in
      //* | *://* | mailto:* | tel:* | javascript:* | data:* | '#'* | '') continue ;;
    esac
    path="${addr%%#*}"
    path="${path%%\?*}"
    case "$path" in
      /*) target="$SITE$path" ;;
      *) target="$(dirname "$SITE/$f")/$path" ;;
    esac
    case "$target" in */) target="${target}index.html" ;; esac
    [ -d "$target" ] && target="$target/index.html"
    [ -f "$target" ] || err "$f: local link '$addr' has no file in _site"
  done
done

if [ "$fail" -ne 0 ]; then
  echo "check-site: FAILED" >&2
  exit 1
fi
echo "check-site: OK"
