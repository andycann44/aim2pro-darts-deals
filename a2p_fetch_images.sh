#!/bin/bash
: "${HISTTIMEFORMAT:=}"
set -euo pipefail

root="site/static/images"
mkdir -p "$root"/{boards,flights,mats,shafts,surrounds,heroes,brand-target,brand-winmau,brand-unicorn}

# Placeholder so nothing breaks if a download fails
PH="$root/_placeholder.svg"
cat > "$PH" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 600">
  <rect width="100%" height="100%" fill="#12161b"/>
  <text x="50%" y="50%" fill="#8aa1b5" font-family="system-ui" font-size="38" text-anchor="middle" dominant-baseline="middle">
    Image placeholder
  </text>
</svg>
SVG

dl() { # dl <url> <outfile>
  local url="$1" out="$2"
 $out"
  if command -v curl >/dev/null 2>&1; then
    curl -L --fail --silent --show-error "$url" -o "$out" || cp -f "$PH" "$out"
  else
    cp -f "$PH" "$out"
  fi
}

# ---- Category covers (royalty-free stock; generic darts/boards) ----
dl "https://images.unsplash.com/photo-1580894328141-6f3421a182a8?auto=format&fit=crop&w=1600&q=80" "$root/boards/cover.jpg"
dl "https://images.unsplash.com/photo-1600177691578-f5df70545e33?auto=format&fit=crop&w=1600&q=80" "$root/flights/cover.jpg"
dl "https://images.unsplash.com/photo-1666040518944-53c2e0ba3b0d?auto=format&fit=crop&w=1600&q=80" "$root/mats/cover.jpg"
dl "https://images.unsplash.com/photo-1629721671030-a83edbb11211?auto=format&fit=crop&w=1600&q=80" "$root/shafts/cover.jpg"
dl "https://images.unsplash.com/photo-1628440501245-393606514a9e?auto=format&fit=crop&w=1600&q=80" "$root/surrounds/cover.jpg"

# ---- Hero picks placeholders (swap later with your own) ----
dl "https://images.unsplash.com/photo-1697727194477-93f7c10b06f0?auto=format&fit=crop&w=1600&q=80" "$root/heroes/omni.jpg"
dl "https://images.unsplash.com/photo-1628440501245-393606514a9e?auto=format&fit=crop&w=1600&q=80" "$root/heroes/virt.jpg"
dl "https://images.unsplash.com/photo-1579019163248-e7761241d85a?auto=format&fit=crop&w=1600&q=80" "$root/heroes/phil-taylor-gx2.jpg"
dl "https://images.unsplash.com/photo-1600177691578-f5df70545e33?auto=format&fit=crop&w=1600&q=80" "$root/heroes/nathan-aspinall.jpg"

# ---- Brand boxes (neutral  not logos) ----images 
dl "https://images.unsplash.com/photo-1628440501245-393606514a9e?auto=format&fit=crop&w=1600&q=80" "$root/brand-target/cover.jpg"
dl "https://images.unsplash.com/photo-1600177691578-f5df70545e33?auto=format&fit=crop&w=1600&q=80" "$root/brand-winmau/cover.jpg"
dl "https://images.unsplash.com/photo-1580894328141-6f3421a182a8?auto=format&fit=crop&w=1600&q=80" "$root/brand-unicorn/cover.jpg"

# Commit & push
git add site/static/images
git commit -m "Add stock images for categories, heroes and brand boxes" || true
git push || { git fetch origin && git rebase origin/main && git push; }

echo Done. Visit: https://andycann44.github.io/aim2pro-darts-deals/?nocache=1" 
