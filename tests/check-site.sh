#!/usr/bin/env bash
# Builds the al-folio (Jekyll) site into _site and checks the result:
# the 4 page addresses, the root redirect to /home/, page titles, the nav
# (Home, Publications, Teaching, Links & Resources, in that order), the CNAME,
# the 404 page, that every local href/src points to a file in _site, and
# that the publication list (from _bibliography/papers.bib) is shown, and
# that the built CSS keeps the small Home social icons (font-size 1.75rem),
# and that the 4 pages have the page banner with its picture, and that
# llms.txt and robots.txt are built and allow indexing.
# It also builds the github.io preview (_config.preview.yml) into _site_preview
# and checks that its local links all start with /website/ and work.
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

# 9. The publication list is built from _bibliography/papers.bib: the
# Publications page shows at least 10 entries (one <div class="row"> each),
# and the Home page shows the "selected publications" list.
n_pubs="$(flat publications/index.html | grep -o '<ol class="bibliography">.*</ol>' |
  grep -o '<div class="row">' | wc -l | tr -d ' ')"
[ "$n_pubs" -ge 10 ] || err "publications/index.html: $n_pubs bibliography entries, expected at least 10"
home_html="$(flat home/index.html)"
echo "$home_html" | grep -qi 'selected publications' || err "home/index.html: no \"selected publications\" heading"
n_sel="$(echo "$home_html" | grep -o '<div class="row">' | wc -l | tr -d ' ')"
[ "$n_sel" -ge 1 ] || err "home/index.html: no selected publications listed"

# 10. The small social icons on Home (from _sass/_custom.scss, loaded by
# assets/css/main.scss): the built CSS has a ".social .contact-icons" rule
# with font-size 1.75rem.
CSS="$SITE/assets/css/main.css"
if [ ! -s "$CSS" ]; then
  err "missing or empty _site/assets/css/main.css"
else
  icon_rules="$(tr '\n\r' '  ' <"$CSS" | grep -o '\.social \.contact-icons *{[^}]*}')"
  if [ -z "$icon_rules" ]; then
    err "main.css: no '.social .contact-icons' rule (is '@use \"custom\";' still in assets/css/main.scss?)"
  elif ! echo "$icon_rules" | grep -Eq '(^|[{;])[[:space:]]*font-size:[[:space:]]*1\.75rem[[:space:]]*(;|})'; then
    err "main.css: '.social .contact-icons' rule has no font-size:1.75rem (got: $icon_rules)"
  fi
  # 10b. Compact selected publications on Home: the built CSS has a
  # ".publications.selected-papers ol.bibliography li" rule with font-size
  # .875rem, and hides the button row there.
  sel_css="$(tr '\n\r' '  ' <"$CSS")"
  sel_rule="$(echo "$sel_css" | grep -o '\.publications\.selected-papers ol\.bibliography li *{[^}]*}')"
  if [ -z "$sel_rule" ]; then
    err "main.css: no '.publications.selected-papers ol.bibliography li' rule"
  elif ! echo "$sel_rule" | grep -Eq '(^|[{;])[[:space:]]*font-size:[[:space:]]*0?\.875rem[[:space:]]*(;|})'; then
    err "main.css: selected-papers item rule has no font-size .875rem (got: $sel_rule)"
  fi
  echo "$sel_css" | grep -Eq '\.publications\.selected-papers ol\.bibliography li \.links[^{]*\{[^}]*display:[[:space:]]*none' ||
    err "main.css: the button row (.links) is not hidden in the Home selected publications"
fi
# The Home list uses the compact wrapper and still lists at least 1 paper;
# the Publications page does not use it.
n_sel_c="$(echo "$home_html" | grep -o '<div class="publications selected-papers">.*' |
  grep -o '<div class="row">' | wc -l | tr -d ' ')"
[ "$n_sel_c" -ge 1 ] || err "home/index.html: no papers inside <div class=\"publications selected-papers\">"
grep -q 'selected-papers' "$SITE/publications/index.html" &&
  err "publications/index.html: uses the Home-only 'selected-papers' class"

# 12. Page banners (from _includes/page_banner.liquid): each of the 4 pages
# has a <div class="page-banner ..."> with the chalk-brain picture as its
# background, Home shows the name, subtitle and photo, the other pages show
# their title, and the picture file is in _site.
BANNER_IMG="assets/img/home-header-background.png"
for f in $PAGES; do
  flat "$f" | grep -Eq "<div class=\"page-banner [^\"]*\" style=\"background-image: url\('/$BANNER_IMG'\);\"" ||
    err "$f: no page banner with background /$BANNER_IMG"
done
echo "$home_html" | grep -o '<div class="page-banner page-banner-home".*' | grep -Eq '<h1 class="page-banner-title">[[:space:]]*George Kour[[:space:]]*</h1>' ||
  err "home/index.html: banner has no 'George Kour' title"
echo "$home_html" | grep -q '<p class="page-banner-subtitle">Research Scientist, IBM Research Labs</p>' ||
  err "home/index.html: banner has no 'Research Scientist, IBM Research Labs' line"
echo "$home_html" | grep -Eq '<img[^>]*class="page-banner-photo"[^>]*src="/assets/img/prof_pic.png"' ||
  err "home/index.html: banner has no profile photo"
for pair in "publications/index.html|Publications" "teaching/index.html|Teaching" "links-resources/index.html|Links &amp; Resources"; do
  f="${pair%%|*}"
  t="${pair#*|}"
  flat "$f" | grep -q "<h1 class=\"page-banner-title\">$t</h1>" || err "$f: banner has no title '$t'"
done
[ -s "$SITE/$BANNER_IMG" ] || err "missing _site/$BANNER_IMG"
grep -q '\.page-banner' "$CSS" 2>/dev/null || err "main.css: no .page-banner rules"

# 13. The Autonomous Agents workshop course on Teaching, with its student
# projects (from _data/student_projects.yml via
# _includes/student_projects.liquid): the heading id="agentic-workshop"
# exists; the "Student projects" sub-heading id="student-projects" and the
# project list sit inside the workshop section (after its heading, before the
# next <h3> or the end); the list has 4 projects under a 2026 heading and
# does not show the redundant "workshop" line; the old separate "Supervised
# Student Projects" heading is gone; and the workshop section shows no email
# addresses or phone/ID-number-like strings.
# (The 4 old course anchor ids are checked in step 6.)
teach_html="$(flat teaching/index.html)"
echo "$teach_html" | grep -q '<h3 id="agentic-workshop">Workshop in Learning Systems and Autonomous Agents</h3>' ||
  err "teaching/index.html: no workshop heading with id=\"agentic-workshop\""
echo "$teach_html" | grep -q 'Supervised Student Projects' &&
  err "teaching/index.html: the old 'Supervised Student Projects' section is still there"
# The workshop section: from its heading up to the next <h3> (or the end).
ws_html="$(echo "$teach_html" | sed -n 's:.*\(<h3 id="agentic-workshop">.*\):\1:p' |
  sed 's:^<h3 id="agentic-workshop">[^<]*</h3>::' | sed 's:<h3[ >].*::')"
if [ -z "$ws_html" ]; then
  err "teaching/index.html: workshop section is empty"
else
  echo "$ws_html" | grep -q '<h4 id="student-projects">Student projects</h4>' ||
    err "teaching/index.html: no 'Student projects' sub-heading (id=\"student-projects\") inside the workshop section"
  sp_html="$(echo "$ws_html" | grep -o '<section class="student-projects".*' | sed 's:</section>.*::')"
  if [ -z "$sp_html" ]; then
    err "teaching/index.html: no <section class=\"student-projects\"> inside the workshop section"
  else
    n_sp="$(echo "$sp_html" | grep -o '<li class="sp-item">' | wc -l | tr -d ' ')"
    [ "$n_sp" -eq 4 ] || err "teaching/index.html: $n_sp student projects, expected 4"
    echo "$sp_html" | grep -q '<h5 class="sp-year">2026</h5>' || err "teaching/index.html: no 2026 year heading"
    echo "$sp_html" | grep -q 'course 150070' &&
      err "teaching/index.html: the project list still shows the redundant 'workshop' line"
  fi
  ws_text="$(echo "$ws_html" | sed 's/<[^>]*>/ /g')"
  echo "$ws_html" | grep -Eq '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|mailto:' &&
    err "teaching/index.html: workshop section has an email address"
  echo "$ws_text" | grep -Eq '(\+972|\b0[2-9])[- ]?[0-9]{1,2}[- ]?[0-9]{3}[- ]?[0-9]{4}|[0-9]{9,}' &&
    err "teaching/index.html: workshop section has a phone/ID-number-like string"
fi

# 14. llms.txt (from llms.txt at the repo root, https://llmstxt.org) for AI
# search tools: it starts with "# George Kour", links to the 4 pages with
# https://www.kour.me, and has no '@' (so no email addresses). robots.txt
# allows everything ("Disallow:" with nothing after it) and points to the
# sitemap.
LLMS="$SITE/llms.txt"
if [ ! -s "$LLMS" ]; then
  err "missing or empty _site/llms.txt"
else
  [ "$(head -n 1 "$LLMS")" = "# George Kour" ] || err "_site/llms.txt: first line is not '# George Kour'"
  for p in home publications teaching links-resources; do
    grep -qF "(https://www.kour.me/$p/)" "$LLMS" || err "_site/llms.txt: no link to https://www.kour.me/$p/"
  done
  grep -q '@' "$LLMS" && err "_site/llms.txt: has an '@' character"
  grep -q '{{\|{%' "$LLMS" && err "_site/llms.txt: has unrendered Liquid"
fi
ROBOTS="$SITE/robots.txt"
if [ ! -s "$ROBOTS" ]; then
  err "missing or empty _site/robots.txt"
else
  grep -Eq '^Disallow:[[:space:]]*$' "$ROBOTS" || err "_site/robots.txt: no empty 'Disallow:' line"
  grep -Eq '^Disallow:[[:space:]]*[^[:space:]]' "$ROBOTS" && err "_site/robots.txt: disallows something"
  grep -qx 'Sitemap: https://www.kour.me/sitemap.xml' "$ROBOTS" || err "_site/robots.txt: no 'Sitemap: https://www.kour.me/sitemap.xml' line"
fi

# 11. Preview build for https://kourgeorge.github.io/website/ (what the Deploy
# action builds when the repo variable SITE_PREVIEW is 'true'). Built into
# _site_preview. The 4 pages exist, and every local href/src that starts
# with / starts with /website/ and points to a file in that build.
PREVIEW="$ROOT/_site_preview"
rm -rf "$PREVIEW"
if ! bundle exec jekyll build --quiet --config _config.yml,_config.preview.yml \
  --destination "$PREVIEW" >/tmp/check-site-preview-build.log 2>&1; then
  cat /tmp/check-site-preview-build.log >&2
  err "preview build (--config _config.yml,_config.preview.yml) failed"
else
  for f in $PAGES index.html 404.html; do
    [ -f "$PREVIEW/$f" ] || { err "missing page in _site_preview: $f"; continue; }
    for addr in $(tr '\n\r' '  ' <"$PREVIEW/$f" | grep -Eo '(href|src)=["'"'"'][^"'"'"']*["'"'"']' |
      sed -E 's/^(href|src)=.//; s/.$//'); do
      case "$addr" in
        //*) continue ;;
        /website/*) ;;
        /*) err "_site_preview/$f: local link '$addr' does not start with /website/"; continue ;;
        *) continue ;;
      esac
      path="${addr%%#*}"
      path="${path%%\?*}"
      target="$PREVIEW/${path#/website/}"
      case "$target" in */) target="${target}index.html" ;; esac
      [ -d "$target" ] && target="$target/index.html"
      [ -f "$target" ] || err "_site_preview/$f: local link '$addr' has no file in _site_preview"
    done
  done
  grep -Eqi 'url=/website/home/"' "$PREVIEW/index.html" ||
    err "_site_preview/index.html: no meta refresh to /website/home/"
  # 12b. The banner picture is in the preview build, and the banners point
  # to it under /website/.
  [ -s "$PREVIEW/$BANNER_IMG" ] || err "missing _site_preview/$BANNER_IMG"
  for f in $PAGES; do
    grep -q "url('/website/$BANNER_IMG')" "$PREVIEW/$f" 2>/dev/null ||
      err "_site_preview/$f: banner background is not /website/$BANNER_IMG"
  done
  # 14b. llms.txt in the preview build links to the preview address.
  grep -qF '(https://kourgeorge.github.io/website/home/)' "$PREVIEW/llms.txt" 2>/dev/null ||
    err "_site_preview/llms.txt: no link to https://kourgeorge.github.io/website/home/"
fi

if [ "$fail" -ne 0 ]; then
  echo "check-site: FAILED" >&2
  exit 1
fi
echo "check-site: OK"
