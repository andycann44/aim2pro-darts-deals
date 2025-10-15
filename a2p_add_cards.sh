#!/bin/bash
: "${HISTTIMEFORMAT:=}"
set -euo pipefail
PAGE="${1:-}"; LIST="${2:-}"
[ -n "$PAGE" ] && [ -f "$LIST" ] || { echo "Usage: $0 heroes|flights|darts|under10 items.txt"; exit 1; }

case "$PAGE" in
  heroes)  FILE="site/static/heroes.html" ;;
  flights) FILE="site/static/flights.html" ;;
  darts)   FILE="site/static/darts.html" ;;
  under10) FILE="site/static/under-10.html" ;;
  *) echo "Bad PAGE. Use heroes|flights|darts|under10"; exit 1;;
esac

mkdir -p site/static/img
# Ensure CSS exists (idempotent)
if [ ! -f site/static/style.css ]; then
  cat > site/static/style.css <<'CSS'
:root { --bg:#0b0e14; --panel:#121722; --text:#e6e6e6; --muted:#a7b0c0; --accent:#32d4a4; --card:#161b28; }
html,body{margin:0;background:var(--bg);color:var(--text);font:16px -apple-system,Segoe UI,Roboto,Arial}
.header{max-width:1100px;margin:0 auto;padding:24px}
.nav{display:flex;flex-wrap:wrap;gap:10px}
.nav a{padding:8px 12px;border-radius:12px;background:#121722;color:var(--text);text-decoration:none}
.brand{font-weight:700;margin-right:auto}
.container{max-width:1100px;margin:20px auto;padding:0 20px}
.hero{position:relative;padding:18px 20px;border-radius:16px;background:#121722;border:1px solid #232a3a;margin-bottom:18px}
.callout{background:#122236;border:1px dashed #2a5672;border-radius:12px;padding:10px 12px;margin:10px 0}
.footer{opacity:.7;color:var(--muted);text-align:center;padding:30px}
.product-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:14px;margin:18px 0}
.product-card{background:var(--card);border:1px solid #232a3a;border-radius:16px;padding:10px 12px}
.product-card .pic{width:100%;height:140px;border-radius:12px;overflow:hidden;background:#0f1422;margin-bottom:10px;display:flex;align-items:center;justify-content:center}
.product-card .pic img{width:100%;height:100%;object-fit:cover;display:block}
.product-card h4{margin:0 0 6px 0;font-size:15px}
.product-card p{margin:0 0 8px 0;color:var(--muted);font-size:13px}
CSS
fi

# Ensure the page exists and has markers (idempotent)
if [ ! -f "$FILE" ]; then
  cat > "$FILE" <<HTML
<!doctype html><html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${PAGE^} • Aim2Pro Darts Deals</title>
<link rel="stylesheet" href="./style.css"></head><body>
<header class="header"><div class="nav">
  <span class="brand">🎯 Aim2Pro Darts Deals</span>
  <a href="./heroes.html">Hero Picks</a><a href="./under-10.html">Under £10</a>
  <a href="./boards.html">Boards</a><a href="./darts.html">Darts</a>
  <a href="./surrounds.html">Surrounds</a><a href="./mats.html">Mats</a>
  <a href="./flights.html">Flights</a><a href="./shafts.html">Shafts</a>
</div></header>
<main class="container">
  <section class="hero"><h1>${PAGE^}</h1>
    <p>Curated ${PAGE} picks.</p>
  </section>
  <!-- PASTE START -->
  <!-- PASTE END -->
  <!-- AUTO-INSERT:START -->
  <!-- AUTO-INSERT:END -->
</main>
<footer class="footer">As an Amazon Associate I earn from qualifying purchases.</footer>
</body></html>
HTML
fi

# Build HTML cards from lines: URL - Title - img:filename
python3 - "$LIST" > block.html <<'PY'
import sys, re, html, pathlib
lines = [l.strip() for l in pathlib.Path(sys.argv[1]).read_text().splitlines() if l.strip()]
out = ['<!-- Generated block -->','<div class="product-grid">']
for line in lines:
    url, rest = (line.split(None,1)+[""])[:2]
    m = re.search(r'img:([^\s]+)', rest, flags=re.I)
    img = m.group(1) if m else "placeholder.svg"
    title = re.sub(r'img:[^\s]+','', rest, flags=re.I).strip(" -–") or url
    out.append('<div class="product-card">')
    out.append(f'<div class="pic"><img loading="lazy" src="./img/{html.escape(img)}" alt="{html.escape(title)}"></div>')
    out.append(f'<h4><a href="{html.escape(url)}" target="_blank" rel="nofollow sponsored">{html.escape(title)}</a></h4>')
    out.append('<p class="note">Affiliate link</p></div>')
out.append('</div>')
print("\n".join(out))
PY

# Insert between markers
perl -0777 -pe '
  BEGIN{local $/;}
  my $r = do { local $/; open my $fh,"<","block.html"; <$fh> };
  s/<!-- AUTO-INSERT:START -->.*?<!-- AUTO-INSERT:END -->/<!-- AUTO-INSERT:START -->\n$r\n<!-- AUTO-INSERT:END -->/s
' -i "$FILE"

git add "$FILE" site/static/style.css 2>/dev/null || true
git commit -m "content($PAGE): add product cards from $LIST" || true
git push
echo "Done → $FILE updated."
