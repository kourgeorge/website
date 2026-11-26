#!/usr/bin/env bash
# Prints the current GitHub star count of every github.com/kourgeorge repo
# listed in _data/github_projects.yml, next to the number typed in there,
# so you can update the "stars:" lines by hand. Needs the gh CLI (logged in).
# Usage: bash scripts/update-github-stars.sh   (from anywhere)

set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA="$ROOT/_data/github_projects.yml"

command -v gh >/dev/null 2>&1 || { echo "gh is not installed" >&2; exit 1; }

# Pair each url with the stars value that follows it in the same entry.
awk '
  /^- / { if (repo != "") print repo, stars; repo = ""; stars = "-" }
  /^  url: "https:\/\/github\.com\// { u = $2; gsub(/"/, "", u); sub(/^https:\/\/github\.com\//, "", u); repo = u }
  /^  stars:/ { stars = $2 }
  END { if (repo != "") print repo, stars }
' "$DATA" | while read -r repo typed; do
  now="$(gh api "repos/$repo" --jq .stargazers_count 2>/dev/null || echo "?")"
  mark=""
  [ "$typed" = "-" ] && typed=0
  [ "$now" != "$typed" ] && mark="  <- update"
  printf '%-40s yml: %-6s github: %s%s\n' "$repo" "$typed" "$now" "$mark"
done
