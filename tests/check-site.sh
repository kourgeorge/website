#!/usr/bin/env bash
# Builds the al-folio (Jekyll) site into _site and checks the result:
# the 4 page addresses, the root redirect to /home/, page titles, the nav
# (Home, Publications, Teaching, Links & Resources, in that order), the CNAME,
# the 404 page, that every local href/src points to a file in _site, and
# that the publication list (from _bibliography/papers.bib) is shown, and
# that the built CSS keeps the small Home banner social icons (font-size 1.25rem),
# that the accent colour is deep teal (no old pink b509ac, dev or production),
# and that the 4 pages have the page banner with its picture, and that
# llms.txt and robots.txt are built and allow indexing, and that a
# production build (JEKYLL_ENV=production, into _site_prod) keeps their lines
# and has the Google Analytics tag on every page, while the dev build has none,
# and that the footer is only "© <year> George Kour. All Rights Reserved.",
# and that Links & Resources and Teaching show their projects as cards, with
# their section and course headings and no empty paragraphs, and that Home
# has its sections in order (with a News list of 7 dated items, newest
# first, including the Reichman University talk), 7 interest tags, 3 organization cards and the
# social icons with a CV button in the banner (no bottom icon row).
# Before building, it checks that every paper in _bibliography/papers.bib has
# a chapter and a tldr of at most 30 words, and that _data/research_journey.yml
# has the chapters, and that Publications shows them as "a journey of ideas"
# (chapters in order, a card with a TL;DR per paper, the DOI links, the
# Classic list, clean BibTeX pop-ups).
# The interactive talk (talks/what-it-pays-attention-to/) is copied into
# _site, _site_prod and _site_preview byte for byte, is the first item of the
# Talks list, and has no "Ask George" text or network scripts/styles.
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

# 0. The Deploy workflow runs on every push to main: its push trigger has no
# "paths:" allow-list, and any paths-ignore does not skip _sass, llms.txt or
# robots.txt (a paths: filter once skipped a push that only changed llms.txt).
DEPLOY=".github/workflows/deploy.yml"
PUSH_BLOCK="$(awk '/^  push:/{on=1; next} on && /^  [^ #]/{on=0} on' "$DEPLOY")"
if [ -z "$PUSH_BLOCK" ]; then
  err "$DEPLOY: no push trigger found"
else
  echo "$PUSH_BLOCK" | grep -Eq '^ +paths:' &&
    err "$DEPLOY: push trigger has a paths: list (some changes would not deploy)"
  echo "$PUSH_BLOCK" | grep -Eq '^ +- +"?(_sass|llms\.txt|robots\.txt|(\*\*/?\*?)?\.(txt|scss)"?$|\*\*?"?$)' &&
    err "$DEPLOY: push paths-ignore excludes _sass, llms.txt or robots.txt changes"
fi

# 0b. Every paper in _bibliography/papers.bib has a chapter (prelude, quality,
# safety, agents or side, the ids in _data/research_journey.yml) and a tldr of
# at most 30 words, for the "journey of ideas" on the Publications page.
BIB_PROBLEMS="$(awk '
  function done_tldr() { n = split(tl, w, /[ \t]+/); c = 0
    for (i = 1; i <= n; i++) if (w[i] != "") c++
    if (c > 30) print key ": tldr has " c " words (at most 30)"; intl = 0 }
  /^@[a-zA-Z]+\{/ { key = $0; sub(/^@[a-zA-Z]+\{/, "", key); sub(/,.*/, "", key)
    inentry = 1; has_t = 0; has_c = 0; next }
  inentry && intl { tl = tl " " $0; if ($0 ~ /\},?[ \t]*$/) done_tldr(); next }
  inentry && /^  tldr[ \t]*=/ { has_t = 1; tl = $0; sub(/^[^{]*\{/, "", tl); intl = 1
    if ($0 ~ /\},?[ \t]*$/) done_tldr(); next }
  inentry && /^  chapter[ \t]*=/ { has_c = 1
    if ($0 !~ /\{(prelude|quality|safety|agents|side)\}/) print key ": bad chapter: " $0 }
  inentry && /^\}/ { inentry = 0
    if (!has_t) print key ": no tldr"; if (!has_c) print key ": no chapter" }
' _bibliography/papers.bib)"
[ -z "$BIB_PROBLEMS" ] || err "_bibliography/papers.bib: $BIB_PROBLEMS"
n_bib="$(grep -c '^@' _bibliography/papers.bib)"
n_tldr="$(grep -c '^  tldr ' _bibliography/papers.bib)"
n_chap="$(grep -c '^  chapter ' _bibliography/papers.bib)"
[ "$n_tldr" -eq "$n_bib" ] && [ "$n_chap" -eq "$n_bib" ] ||
  err "_bibliography/papers.bib: $n_bib entries but $n_tldr tldr and $n_chap chapter fields"
for id in prelude quality safety agents side next; do
  grep -q "^- id: $id\$" _data/research_journey.yml ||
    err "_data/research_journey.yml: no chapter with id $id"
done

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

# 10. The small social icons in the Home banner (from _sass/_custom.scss,
# loaded by assets/css/main.scss): the built CSS has a
# ".page-banner-social .contact-icons" rule with font-size 1.25rem.
CSS="$SITE/assets/css/main.css"
if [ ! -s "$CSS" ]; then
  err "missing or empty _site/assets/css/main.css"
else
  icon_rules="$(tr '\n\r' '  ' <"$CSS" | grep -o '\.page-banner-social \.contact-icons *{[^}]*}')"
  if [ -z "$icon_rules" ]; then
    err "main.css: no '.page-banner-social .contact-icons' rule (is '@use \"custom\";' still in assets/css/main.scss?)"
  elif ! echo "$icon_rules" | grep -Eq '(^|[{;])[[:space:]]*font-size:[[:space:]]*1\.25rem[[:space:]]*(;|})'; then
    err "main.css: '.page-banner-social .contact-icons' rule has no font-size:1.25rem (got: $icon_rules)"
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
  # 10c. Accent colour is deep teal (_sass/_variables.scss, _sass/_custom.scss):
  # the theme's old pink/purple (#b509ac) is gone and the teal values are set.
  ! grep -qi 'b509ac' "$CSS" || err "main.css: still has the old pink accent b509ac"
  grep -qi '#0f766e' "$CSS" || err "main.css: no light-mode teal accent #0f766e"
  grep -qi '#2dd4bf' "$CSS" || err "main.css: no dark-mode teal accent #2dd4bf"
fi
# The Home list uses the compact wrapper and still lists at least 1 paper;
# the Publications page does not use it.
n_sel_c="$(echo "$home_html" | grep -o '<div class="publications selected-papers">.*' |
  grep -o '<div class="row">' | wc -l | tr -d ' ')"
[ "$n_sel_c" -ge 1 ] || err "home/index.html: no papers inside <div class=\"publications selected-papers\">"
grep -q 'selected-papers' "$SITE/publications/index.html" &&
  err "publications/index.html: uses the Home-only 'selected-papers' class"

# 9b. T-43: Publications as "a journey of ideas" (_includes/publications_journey.liquid,
# _layouts/journey_entry.liquid). The chapters from _data/research_journey.yml
# are shown in order (prelude, quality, safety, agents, then the "next" end
# dot) with their titles, followed by the folded Side quests; there is one
# paper card per entry of papers.bib (at least 20), each with a TL;DR line and
# a linked title (the SEC-2017 card may have no link: it has no DOI/URL and
# its pdf is the wrong paper, so it has no PDF button); every DOI in papers.bib
# is linked; builds-on links point to a card on the page; the Classic list
# (al-folio's list by year) is in the page; the switch script is loaded and
# guards localStorage; and the BibTeX pop-ups (here and on Home) do not show
# the journey fields.
pub_html="$(flat publications/index.html)"
got_ch="$(echo "$pub_html" | grep -o '<section class="jr-chapter[^"]*" id="chapter-[a-z]*"' |
  sed 's:.*id="chapter-::; s:"$::' | tr '\n' ';')"
[ "$got_ch" = "prelude;quality;safety;agents;next;" ] ||
  err "publications/index.html: journey chapters are '$got_ch', expected 'prelude;quality;safety;agents;next;'"
echo "$pub_html" | grep -q '<details class="jr-side" id="chapter-side"' ||
  err "publications/index.html: no folded Side quests section (<details class=\"jr-side\">)"
p_next="$(echo "$pub_html" | grep -bo 'id="chapter-next"' | head -n 1 | cut -d: -f1)"
p_side="$(echo "$pub_html" | grep -bo 'id="chapter-side"' | head -n 1 | cut -d: -f1)"
p_pat="$(echo "$pub_html" | grep -bo '<h3 id="h.p_xY_nY1xX4Ypv"[^>]*>Patents:</h3>' | head -n 1 | cut -d: -f1)"
if [ -z "$p_next" ] || [ -z "$p_side" ] || [ -z "$p_pat" ]; then
  err "publications/index.html: missing the next dot ('$p_next'), Side quests ('$p_side') or the Patents: heading ('$p_pat')"
elif ! [ "$p_next" -lt "$p_side" ] || ! [ "$p_side" -lt "$p_pat" ]; then
  err "publications/index.html: not in the order journey, Side quests, Patents"
fi
awk '/^- id: /{id=$3} /^  title: /{t=$0; sub(/^  title: "?/, "", t); sub(/"$/, "", t)
  if (id != "next" && id != "side") print t}' _data/research_journey.yml |
  while IFS= read -r t; do
    echo "$pub_html" | grep -qF "<h4 class=\"jr-title\">$t</h4>" || echo "$t"
  done >/tmp/check-site-missing-chapters.txt
[ -s /tmp/check-site-missing-chapters.txt ] &&
  err "publications/index.html: no chapter heading for: $(tr '\n' ';' </tmp/check-site-missing-chapters.txt)"
cards="$(echo "$pub_html" | sed 's:<div class="gp-card jr-card":\
&:g' | grep '^<div class="gp-card jr-card"')"
n_cards="$(echo "$cards" | grep -c 'jr-card')"
[ "$n_cards" -ge 20 ] || err "publications/index.html: $n_cards paper cards, expected at least 20"
[ "$n_cards" -eq "$n_bib" ] || err "publications/index.html: $n_cards paper cards for $n_bib papers in papers.bib"
n_tl="$(echo "$cards" | grep -c '<p class="jr-tldr"><strong class="jr-tldr-label">TL;DR</strong> [^<]')"
[ "$n_tl" -eq "$n_cards" ] || err "publications/index.html: only $n_tl of $n_cards cards have a TL;DR line"
n_tlink="$(echo "$cards" | grep -c '<div class="title jr-paper-title"><a href="https\?://')"
[ "$n_tlink" -ge 20 ] && [ "$n_tlink" -ge $((n_cards - 1)) ] ||
  err "publications/index.html: only $n_tlink of $n_cards cards have a linked title"
sec_card="$(echo "$cards" | grep 'id="paper-kour2017handlingtime"')"
[ -n "$sec_card" ] || err "publications/index.html: no card for kour2017handlingtime"
echo "$sec_card" | grep -q 'role="button">PDF</a>' &&
  err "publications/index.html: the SEC-2017 card has a PDF button (its pdf is the ADMA 2016 paper)"
for doi in $(sed -n 's/^  doi *= *{\([^}]*\)}.*/\1/p' _bibliography/papers.bib); do
  n_d="$(echo "$cards" | grep -cF "href=\"https://doi.org/$doi\"")"
  [ "$n_d" -ge 1 ] || err "publications/index.html: no journey card links to https://doi.org/$doi"
done
for t in $(echo "$pub_html" | grep -o 'class="jr-builds-link" href="#paper-[^"]*"' | sed 's:.*#::; s:"$::'); do
  echo "$pub_html" | grep -q "id=\"$t\"" || err "publications/index.html: builds-on link to #$t has no card"
done
n_bo="$(grep -c '^  builds_on ' _bibliography/papers.bib)"
n_bol="$(echo "$pub_html" | grep -o 'class="jr-builds-link"' | wc -l | tr -d ' ')"
[ "$n_bol" -eq "$n_bo" ] || err "publications/index.html: $n_bol builds-on links, expected $n_bo"
classic="$(echo "$pub_html" | grep -o '<div class="jr-classic publications" id="classic-list">.*' | sed 's:<h3 id="h.p_xY_nY1xX4Ypv".*::')"
n_classic="$(echo "$classic" | grep -o '<div class="row">' | wc -l | tr -d ' ')"
[ "$n_classic" -eq "$n_bib" ] || err "publications/index.html: Classic list has $n_classic papers, expected $n_bib"
echo "$classic" | grep -q '<h2 class="bibliography">2026</h2>' || err "publications/index.html: Classic list has no 2026 year heading"
for b in 'data-jr-view="journey"' 'data-jr-view="classic"' 'data-jr-filter="all"' 'data-jr-filter="prelude"' 'data-jr-filter="quality"' 'data-jr-filter="safety"' 'data-jr-filter="agents"'; do
  echo "$pub_html" | grep -q "<button type=\"button\" class=\"jr-[a-z-]*\" $b" || err "publications/index.html: no button with $b"
done
echo "$pub_html" | grep -q '<script src="/assets/js/publications-journey.js">' ||
  err "publications/index.html: does not load /assets/js/publications-journey.js"
grep -q 'try' "$SITE/assets/js/publications-journey.js" 2>/dev/null ||
  err "_site/assets/js/publications-journey.js: missing, or localStorage not inside try/catch"
for f in publications/index.html home/index.html; do
  grep -Eq '<span class="na">(tldr|chapter|builds_on|talk_chapter)</span>' "$SITE/$f" &&
    err "$f: a BibTeX pop-up shows a journey field (tldr/chapter/builds_on)"
  grep -q '<span class="err">' "$SITE/$f" && err "$f: a BibTeX pop-up has leftover lines of a hidden field"
done
grep -q '#2dd4bf\|jr-thread' "$CSS" && grep -q '\.jr-chapter' "$CSS" ||
  err "main.css: no journey (.jr-*) styles"

# 19. Home layout (T-26). The banner has the social icons (from
# _data/socials.yml) and a "CV" button linking to the CV on Drive, with the
# plugin's own CV icon taken out so it is not shown twice; there is no
# bottom <div class="social"> icon row. The main content runs: short bio,
# News, Research Interests, Selected publications, Supported Organizations
# (T-36 moved Research Interests above Selected publications); the 7
# interests are tags and the 3 organizations are cards; the emails are shown
# in the "(at)" form; the 1-column / 3-column org grid is in the CSS.
banner_html="$(echo "$home_html" | grep -o '<div class="page-banner page-banner-home".*' | sed 's:<div class="container mt-5".*::')"
banner_social="$(echo "$banner_html" | grep -o '<div class="page-banner-social">.*')"
if [ -z "$banner_social" ]; then
  err "home/index.html: no <div class=\"page-banner-social\"> in the banner"
else
  for u in 'https://github.com/kourgeorge' 'https://www.linkedin.com/in/georgekour' 'https://scholar.google.com/citations?user=Yx8ov1wAAAAJ' 'https://dblp.uni-trier.de/pers/hd/k/Kour:George'; do
    echo "$banner_social" | grep -qF "href=\"$u" || err "home/index.html: banner has no icon link to $u"
  done
  echo "$banner_social" | grep -Eq '<a class="page-banner-cv" href="https://drive\.google\.com/file/d/1jKShjChFSWVyrwjqUwpUAGDPcxdn__so/[^"]*"[^>]*>.*CV</a>' ||
    err "home/index.html: banner has no CV button linking to the CV on Drive"
  n_cv="$(echo "$banner_social" | grep -o 'href="https://drive.google.com/file/d/1jKShjChFSWVyrwjqUwpUAGDPcxdn__so' | wc -l | tr -d ' ')"
  [ "$n_cv" -eq 1 ] || err "home/index.html: the banner links to the CV $n_cv times, expected 1"
fi
echo "$home_html" | grep -q '<div class="social">' && err "home/index.html: the old bottom social icon row is still there"
home_main="$(echo "$home_html" | grep -o '<article>.*</article>')"
pos() { echo "$home_main" | grep -bo "$1" | head -n 1 | cut -d: -f1; }
p_bio="$(pos 'I am a senior researcher in the Language and Conversation Group')"
p_pub="$(pos '<h3 id="selected-publications" class="lr-section">')"
p_ri="$(pos '<h3 id="h.q4wcjinfbaz1" class="lr-section">Research Interests</h3>')"
p_so="$(pos '<h3 id="h.p_zqA8I2zFqZvP" class="lr-section">Supported Organizations</h3>')"
if [ -z "$p_bio" ] || [ -z "$p_pub" ] || [ -z "$p_ri" ] || [ -z "$p_so" ]; then
  err "home/index.html: missing a section (bio '$p_bio', selected publications '$p_pub', Research Interests '$p_ri', Supported Organizations '$p_so')"
elif ! [ "$p_bio" -lt "$p_ri" ] || ! [ "$p_ri" -lt "$p_pub" ] || ! [ "$p_pub" -lt "$p_so" ]; then
  err "home/index.html: sections are not in the order bio, Research Interests, selected publications, Supported Organizations"
fi
# 19c. News on Home (T-35, from _news/ via _includes/home_news.liquid): a
# "News" heading between the bio and Research Interests, with 7 items (T-37),
# each with a <time datetime="YYYY-MM" or "YYYY"> date shown as "Sep 2026"
# or "2025", newest first (years never go up; months never go up within a
# year when both items have one). Every link in the list is local (and has a
# file in _site; step 8 checks the whole page too) or starts with https://.
# The items have no pages of their own (no _site/news/).
p_news="$(pos '<h3 id="news" class="lr-section">News</h3>')"
if [ -z "$p_news" ]; then
  err "home/index.html: no News heading (<h3 id=\"news\" class=\"lr-section\">News</h3>)"
elif [ -n "$p_bio" ] && [ -n "$p_ri" ] && { ! [ "$p_bio" -lt "$p_news" ] || ! [ "$p_news" -lt "$p_ri" ]; }; then
  err "home/index.html: News is not between the bio and Research Interests"
fi
news_html="$(echo "$home_main" | grep -o '<ul class="hm-news">.*' | sed 's:</ul>.*::')"
n_news="$(echo "$news_html" | grep -o '<li class="hm-news-item">' | wc -l | tr -d ' ')"
[ "$n_news" -eq 7 ] || err "home/index.html: $n_news News items, expected 7"
# T-37: the Reichman University talk is in the News, linking to its slides.
reichman_url='https://docs.google.com/presentation/d/1c64eM0zZNFOd2uVuEXeiDCLWcfzDCsHr/edit?usp=sharing'
echo "$news_html" | grep -q "Talk at Reichman University: <a href=\"$reichman_url\"[^>]*>From Quality to Safety to Security: A Research Trajectory in AI Evaluation</a>" ||
  err "home/index.html: no Reichman University talk in the News linking to its slides"
echo "$news_html" | grep -q 'ouid=' && err "home/index.html: a News link has the personal ouid= parameter"
n_dated="$(echo "$news_html" | grep -Eo '<li class="hm-news-item"> *<time class="hm-news-date" datetime="[0-9]{4}(-[0-9]{2})?">([A-Z][a-z]{2} )?[0-9]{4}</time>' | wc -l | tr -d ' ')"
[ "$n_dated" -eq "$n_news" ] || err "home/index.html: only $n_dated of $n_news News items start with a date"
prev_y=9999
prev_m=""
for dt in $(echo "$news_html" | grep -Eo 'datetime="[0-9-]+"' | sed -E 's/datetime="//; s/"$//'); do
  y="${dt%%-*}"
  m=""
  case "$dt" in *-*) m="${dt#*-}" ;; esac
  if [ "$y" -gt "$prev_y" ]; then
    err "home/index.html: News is not newest first ($dt after $prev_y)"
  elif [ "$y" -eq "$prev_y" ] && [ -n "$m" ] && [ -n "$prev_m" ] && [ "$m" \> "$prev_m" ]; then
    err "home/index.html: News is not newest first ($dt after $prev_y-$prev_m)"
  fi
  if [ "$y" -ne "$prev_y" ] || [ -n "$m" ]; then prev_m="$m"; fi
  prev_y="$y"
done
for addr in $(echo "$news_html" | grep -Eo 'href="[^"]*"' | sed -E 's/^href="//; s/"$//'); do
  case "$addr" in
    https://*) ;;
    /*)
      path="${addr%%#*}"
      target="$SITE$path"
      case "$target" in */) target="${target}index.html" ;; esac
      [ -f "$target" ] || err "home/index.html: News link '$addr' has no file in _site"
      frag="${addr#*#}"
      if [ "$frag" != "$addr" ] && [ -n "$frag" ]; then
        grep -q "id=\"$frag\"" "$target" 2>/dev/null || err "home/index.html: News link '$addr' has no id=\"$frag\" on its page"
      fi
      ;;
    *) err "home/index.html: News link '$addr' is neither local (/...) nor https://" ;;
  esac
done
[ -e "$SITE/news" ] && err "_site/news exists: News items should not have pages of their own"
echo "$home_main" | grep -q 'href="/teaching/#agentic-workshop">workshop on autonomous AI agents</a>' ||
  err "home/index.html: bio has no link to the agents workshop on Teaching"
for name in "Dana Ron" "Raid Saabni" "Genela Morris"; do
  echo "$home_main" | grep -q "$name" && err "home/index.html: still names the supervisor $name"
done
n_tags="$(echo "$home_main" | grep -o '<li class="hm-tag">[^<]*</li>' | wc -l | tr -d ' ')"
[ "$n_tags" -eq 7 ] || err "home/index.html: $n_tags research interest tags, expected 7"
orgs_html="$(echo "$home_main" | grep -o '<section class="gh-projects hm-orgs">.*' | sed 's:</section>.*::')"
n_orgs="$(echo "$orgs_html" | grep -o '<li class="gp-card hm-org">' | wc -l | tr -d ' ')"
[ "$n_orgs" -eq 3 ] || err "home/index.html: $n_orgs organization cards, expected 3"
for u in 'http://www.reutsadaka.org/' 'https://www.sams-usa.net/' 'http://www.tsofen.org/'; do
  echo "$orgs_html" | grep -qF "href=\"$u\"" || err "home/index.html: no organization card linking to $u"
done
echo "$home_main" | grep -qF 'gkour(at)ibm.com / kourgeorge(at)gmail.com' ||
  err "home/index.html: the emails are not shown as gkour(at)ibm.com / kourgeorge(at)gmail.com"
echo "$home_main" | grep -Eq '<[a-z0-9]+ id="h\.p_lujnsfikmTVd"[^>]*>.*\(at\)ibm\.com' ||
  err "home/index.html: the Online Presence anchor is not on the email line"
tr '\n\r' '  ' <"$CSS" | grep -Eq '@media ?\(min-width: ?768px\) *\{[^}]*\.hm-orgs \.gp-grid *\{[^}]*grid-template-columns: ?repeat\(3' ||
  err "main.css: no 3-column .hm-orgs .gp-grid rule for screens 768px and wider"

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
# Layout (T-25, like Links & Resources): the workshop heading has class
# "lr-section", then the 4 old courses follow in order, each an
# <h3 class="tc-course"> with its paragraph right below; the 4 projects are
# cards (<li class="gp-card sp-card">) in a <ul class="gp-grid"> under a
# "gp-group" year label; and the main content has no <hr> or empty <p></p>.
teach_html="$(flat teaching/index.html)"
echo "$teach_html" | grep -q '<h3 id="agentic-workshop" class="lr-section[^"]*">Workshop in Learning Systems and Autonomous Agents</h3>' ||
  err "teaching/index.html: no workshop heading with id=\"agentic-workshop\""
echo "$teach_html" | grep -q 'Supervised Student Projects' &&
  err "teaching/index.html: the old 'Supervised Student Projects' section is still there"
# The workshop section: from its heading up to the next <h3> (or the end).
ws_html="$(echo "$teach_html" | sed -n 's:.*\(<h3 id="agentic-workshop"[^>]*>.*\):\1:p' |
  sed 's:^<h3 id="agentic-workshop"[^>]*>[^<]*</h3>::' | sed 's:<h3[ >].*::')"
if [ -z "$ws_html" ]; then
  err "teaching/index.html: workshop section is empty"
else
  echo "$ws_html" | grep -q '<h4 id="student-projects"[^>]*>Student projects</h4>' ||
    err "teaching/index.html: no 'Student projects' sub-heading (id=\"student-projects\") inside the workshop section"
  sp_html="$(echo "$ws_html" | grep -o '<section class="student-projects[^"]*".*' | sed 's:</section>.*::')"
  if [ -z "$sp_html" ]; then
    err "teaching/index.html: no <section class=\"student-projects\"> inside the workshop section"
  else
    n_sp="$(echo "$sp_html" | grep -o '<li class="gp-card sp-card">' | wc -l | tr -d ' ')"
    [ "$n_sp" -eq 4 ] || err "teaching/index.html: $n_sp student project cards (gp-card), expected 4"
    echo "$sp_html" | grep -q '<ul class="gp-grid">' || err "teaching/index.html: student projects are not in a gp-grid"
    echo "$sp_html" | grep -q '<h5 class="gp-group sp-year">2026</h5>' || err "teaching/index.html: no 2026 year label (gp-group)"
    echo "$sp_html" | grep -q 'course 150070' &&
      err "teaching/index.html: the project list still shows the redundant 'workshop' line"
  fi
  ws_text="$(echo "$ws_html" | sed 's/<[^>]*>/ /g')"
  echo "$ws_html" | grep -Eq '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|mailto:' &&
    err "teaching/index.html: workshop section has an email address"
  echo "$ws_text" | grep -Eq '(\+972|\b0[2-9])[- ]?[0-9]{1,2}[- ]?[0-9]{3}[- ]?[0-9]{4}|[0-9]{9,}' &&
    err "teaching/index.html: workshop section has a phone/ID-number-like string"
fi
got_courses="$(echo "$teach_html" | grep -o '<h3 id="[^"]*" class="[^"]*">[^<]*</h3>' |
  sed 's:<h3 id="\([^"]*\)" class="\([^"]*\)">\([^<]*\)</h3>:\1|\2|\3:' | tr '\n' ';')"
want_courses="agentic-workshop|lr-section tc-current|Workshop in Learning Systems and Autonomous Agents;h.ao2ziu9eq497|tc-course|Introduction to Machine Learning in Python;h.p_oQxnhJbmk8UM|tc-course|Introduction to Scientific Programming in MATLAB;h.k58d4jgpt5mj|tc-course|Git for gits;h.hrj399f848kb|tc-course|Deep learning for Sequential Data;"
[ "$got_courses" = "$want_courses" ] ||
  err "teaching/index.html: course headings are '$got_courses', expected '$want_courses'"
n_tc_text="$(echo "$teach_html" | grep -Eo '</h3>[[:space:]]*<p class="tc-text">' | wc -l | tr -d ' ')"
[ "$n_tc_text" -eq 5 ] || err "teaching/index.html: $n_tc_text course headings with their paragraph right below, expected 5"
teach_main="$(echo "$teach_html" | grep -o '<article>.*</article>')"
[ -n "$teach_main" ] || err "teaching/index.html: no <article> main content"
echo "$teach_main" | grep -Eq '<p[^>]*>[[:space:]]*(<br */?>[[:space:]]*)*</p>' &&
  err "teaching/index.html: empty <p></p> in the main content"
echo "$teach_main" | grep -q '<hr' && err "teaching/index.html: stray <hr> in the main content"

# 18. Projects and Data-sets on Links & Resources (from
# _data/github_projects.yml via _includes/github_projects.liquid): the 5 group
# headings in order, at least 14 entries, links to arxiv-style and to the
# ibm-research Hugging Face datasets, and no link to the old Arabic letters
# Drive file (id 0B1ZvWH6..., now behind a sign-in). agents-patterns-atlas
# links to https://agents.kour.me/, not the old github.io address that
# redirects there. The old anchor ids are
# checked in step 6.
# Layout (T-24): the projects are cards (<li class="gp-card">) in its own
# <section class="gh-projects"> (not the Teaching student-projects classes),
# both section headings have class "lr-section", the talks sit in
# <div class="lr-talks">, the main content has no empty <p></p> and no <hr>
# left over from Google Sites, and the built CSS has the 2-column card grid.
lr_html="$(flat links-resources/index.html)"
gp_html="$(echo "$lr_html" | grep -o '<section class="gh-projects".*' | sed 's:</section>.*::')"
if [ -z "$gp_html" ]; then
  err "links-resources/index.html: no <section class=\"gh-projects\">"
else
  got_groups="$(echo "$gp_html" | grep -o '<h5 class="gp-group">[^<]*</h5>' |
    sed 's:<[^>]*>::g; s/&amp;/\&/g' | tr '\n' ';')"
  want_groups="AI safety & LLM evaluation;AI agents & agent tools;Simulators & artificial life;Research code & data;LaTeX templates;"
  [ "$got_groups" = "$want_groups" ] ||
    err "links-resources/index.html: project groups are '$got_groups', expected '$want_groups'"
  n_gp="$(echo "$gp_html" | grep -o '<li class="gp-card">' | wc -l | tr -d ' ')"
  [ "$n_gp" -ge 14 ] || err "links-resources/index.html: $n_gp project cards, expected at least 14"
  echo "$gp_html" | grep -q 'class="[^"]*\bsp-' &&
    err "links-resources/index.html: projects still use Teaching's sp-* classes"
fi
echo "$lr_html" | grep -q '<h3 id="h.p_kd8WZCiBFKhc" class="lr-section">Projects and Data-sets:</h3>' ||
  err "links-resources/index.html: no 'Projects and Data-sets:' section heading (class lr-section)"
echo "$lr_html" | grep -q '<h3 id="h.p_9RovSi7yLXnI" class="lr-section">Talks and Presentations:</h3>' ||
  err "links-resources/index.html: no 'Talks and Presentations:' section heading (class lr-section)"
lr_main="$(echo "$lr_html" | grep -o '<article>.*</article>')"
n_talks="$(echo "$lr_main" | grep -o '<div class="lr-talks">.*' | sed 's:</div>.*::' | grep -o '<li>' | wc -l | tr -d ' ')"
[ "$n_talks" -ge 10 ] || err "links-resources/index.html: $n_talks talks inside <div class=\"lr-talks\">, expected at least 10"
talk_items="$(echo "$lr_main" | grep -o '<div class="lr-talks">.*' | sed 's:</div>.*::' | sed 's:<li>:\
<li>:g' | grep '^<li>' | sed 's:</li>.*::')"
# T-39: the first talk is the interactive talk, linking to its page on the site.
first_talk="$(echo "$talk_items" | sed -n 1p)"
echo "$first_talk" | grep -q 'What It Pays Attention To: an interactive talk on my research journey, from models to brains and back to AI safety.' ||
  err "links-resources/index.html: the first talk is not 'What It Pays Attention To'"
echo "$first_talk" | grep -q 'href="/talks/what-it-pays-attention-to/"[^>]*>open the talk</a>' ||
  err "links-resources/index.html: the first talk does not link to /talks/what-it-pays-attention-to/"
# T-37: the second talk is the Reichman University 2026 talk, linking to its
# slides (without the personal ouid= parameter).
second_talk="$(echo "$talk_items" | sed -n 2p)"
echo "$second_talk" | grep -q 'Reichman University, May 2026' ||
  err "links-resources/index.html: the second talk is not the Reichman University May 2026 talk"
echo "$second_talk" | grep -q 'href="https://docs.google.com/presentation/d/1c64eM0zZNFOd2uVuEXeiDCLWcfzDCsHr/edit?usp=sharing"[^>]*>slides</a>' ||
  err "links-resources/index.html: the second talk does not link to the Reichman slides"
echo "$lr_main" | grep -q 'ouid=' && err "links-resources/index.html: a link has the personal ouid= parameter"
echo "$lr_main" | grep -Eq '<p[^>]*>[[:space:]]*(<br */?>[[:space:]]*)*</p>' &&
  err "links-resources/index.html: empty <p></p> in the main content"
echo "$lr_main" | grep -q '<hr' && err "links-resources/index.html: stray <hr> in the main content"
tr '\n\r' '  ' <"$CSS" | grep -Eq '@media ?\(min-width: ?768px\) *\{[^}]*\.gh-projects \.gp-grid *\{[^}]*grid-template-columns: ?repeat\(2' ||
  err "main.css: no 2-column .gh-projects .gp-grid rule for screens 768px and wider"
echo "$lr_html" | grep -q 'href="https://github.com/kourgeorge/arxiv-style"' ||
  err "links-resources/index.html: no link to github.com/kourgeorge/arxiv-style"
echo "$lr_html" | grep -q 'href="https://huggingface.co/datasets/ibm-research/' ||
  err "links-resources/index.html: no link to huggingface.co/datasets/ibm-research"
echo "$lr_html" | grep -q 'huggingface.co/datasets/ibm/' &&
  err "links-resources/index.html: still links to the old huggingface.co/datasets/ibm/ address"
echo "$lr_html" | grep -q '0B1ZvWH6' &&
  err "links-resources/index.html: still links to the old Arabic letters Drive file"
echo "$lr_html" | grep -q 'href="https://agents.kour.me/"' ||
  err "links-resources/index.html: no link to https://agents.kour.me/"
echo "$lr_html" | grep -q 'kourgeorge.github.io/agents-patterns-atlas' &&
  err "links-resources/index.html: still links to kourgeorge.github.io/agents-patterns-atlas"
echo "$lr_html" | grep -q 'href="https://github.com/kourgeorge"' ||
  err "links-resources/index.html: no link to the GitHub profile"
echo "$lr_html" | grep -q 'Talks and Presentations' ||
  err "links-resources/index.html: the Talks and Presentations section is gone"

# 17. Footer (from _includes/footer.liquid, a copy of al-folio's): on the 4
# pages it reads "© <year> George Kour. All Rights Reserved." and has no
# theme or hosting credit.
YEAR="$(date +%Y)"
for f in $PAGES; do
  footer="$(flat "$f" | grep -o '<footer[ >].*</footer>' | sed 's:</footer>.*::')"
  [ -n "$footer" ] || { err "$f: no <footer>"; continue; }
  ftext="$(echo "$footer" | sed 's/<[^>]*>/ /g' | tr -s ' ')"
  echo "$ftext" | grep -Fq "George Kour. All Rights Reserved." ||
    err "$f: footer has no 'George Kour. All Rights Reserved.' (got: $ftext)"
  echo "$ftext" | grep -Eq "(&copy;|©) $YEAR George Kour\. All Rights Reserved\." ||
    err "$f: footer is not '© $YEAR George Kour. All Rights Reserved.' (got: $ftext)"
  for bad in "Powered by" "al-folio" "Hosted by"; do
    echo "$footer" | grep -Fq "$bad" && err "$f: footer still has '$bad'"
  done
done

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

# 15. Production build (JEKYLL_ENV=production, like the Deploy action, which
# turns on jekyll-minifier) into _site_prod: the .txt files keep their line
# breaks (they are in jekyll-minifier's exclude list in _config.yml).
PROD="$ROOT/_site_prod"
GA_ID="G-4Q9QNQR0H2"
rm -rf "$PROD"
if ! JEKYLL_ENV=production bundle exec jekyll build --quiet --destination "$PROD" \
  >/tmp/check-site-prod-build.log 2>&1; then
  cat /tmp/check-site-prod-build.log >&2
  err "production build (JEKYLL_ENV=production) failed"
else
  PLLMS="$PROD/llms.txt"
  if [ ! -s "$PLLMS" ]; then
    err "missing or empty _site_prod/llms.txt"
  else
    n_lines="$(wc -l <"$PLLMS" | tr -d ' ')"
    [ "$n_lines" -gt 10 ] || err "_site_prod/llms.txt: only $n_lines lines (squashed by the minifier?)"
    [ "$(head -n 1 "$PLLMS")" = "# George Kour" ] || err "_site_prod/llms.txt: first line is not exactly '# George Kour'"
    grep -q '^## ' "$PLLMS" || err "_site_prod/llms.txt: no line starting with '## '"
    grep -q '^- \[' "$PLLMS" || err "_site_prod/llms.txt: no line starting with '- ['"
  fi
  PROBOTS="$PROD/robots.txt"
  if [ ! -s "$PROBOTS" ]; then
    err "missing or empty _site_prod/robots.txt"
  else
    grep -qx 'User-agent: \*' "$PROBOTS" || err "_site_prod/robots.txt: no 'User-agent: *' line of its own"
    grep -Eq '^Disallow:[[:space:]]*$' "$PROBOTS" || err "_site_prod/robots.txt: no 'Disallow:' line of its own"
  fi
  # 16. Google Analytics (GA4, from analytics.google in _config.yml via
  # _includes/google_analytics.liquid): the 4 pages and 404.html of the
  # production build load gtag.js and call gtag('config', ...) with the ID.
  # 15b. The production CSS has no old pink accent either.
  if [ -s "$PROD/assets/css/main.css" ]; then
    ! grep -qi 'b509ac' "$PROD/assets/css/main.css" || err "_site_prod main.css: still has the old pink accent b509ac"
  else
    err "missing or empty _site_prod/assets/css/main.css"
  fi
  for f in $PAGES 404.html; do
    [ -f "$PROD/$f" ] || { err "missing page in _site_prod: $f"; continue; }
    grep -q "googletagmanager.com/gtag/js?id=$GA_ID" "$PROD/$f" ||
      err "_site_prod/$f: no googletagmanager.com/gtag/js?id=$GA_ID script"
    grep -Eq "gtag\\(['\"]config['\"], *['\"]$GA_ID['\"]\\)" "$PROD/$f" ||
      err "_site_prod/$f: no gtag('config', '$GA_ID') call"
  done
fi

# 16b. The normal (dev) build has no Google Analytics, so local visits are
# not counted.
GA_DEV="$(grep -rl "$GA_ID" "$SITE" --include='*.html' 2>/dev/null | head -n 3)"
[ -z "$GA_DEV" ] || err "dev build _site has the analytics ID $GA_ID in: $GA_DEV"

# 17. T-39: the interactive talk is served exactly as built, in the dev,
# production and preview builds (no front matter, skipped by jekyll-minifier).
TALK="talks/what-it-pays-attention-to/index.html"
if [ ! -s "$ROOT/$TALK" ]; then
  err "missing or empty $TALK"
else
  head -n 1 "$ROOT/$TALK" | grep -q '^---' && err "$TALK has front matter (Jekyll would change it)"
  for d in "$SITE" "$PROD" "$PREVIEW"; do
    if [ ! -f "$d/$TALK" ]; then
      err "missing $(basename "$d")/$TALK"
    else
      cmp -s "$ROOT/$TALK" "$d/$TALK" || err "$(basename "$d")/$TALK is not byte-identical to $TALK"
    fi
  done
  grep -q 'Ask George' "$ROOT/$TALK" && err "$TALK has 'Ask George' text"
  grep -Eiq '<script[^>]*src=["'"'"']?(https?:)?//' "$ROOT/$TALK" && err "$TALK loads a <script src> from the network"
  grep -Eiq '<link[^>]*href=["'"'"']?(https?:)?//' "$ROOT/$TALK" && err "$TALK loads a <link href> from the network"
fi

if [ "$fail" -ne 0 ]; then
  echo "check-site: FAILED" >&2
  exit 1
fi
echo "check-site: OK"
