#!/bin/bash
: "${HISTTIMEFORMAT:=}"; set -euo pipefail
[ -f ./a2p_bash_compat.sh ] && source ./a2p_bash_compat.sh
[ -f /tmp/a2p_env.sh ] && source /tmp/a2p_env.sh

TAG="${TAG:-aim2prodealsuk-21}"
ROOT="site/static"
DATA="site/data/boxes.tsv"
TMP="$(mktemp -d)"

ensure_markers() {
  local f="$1"
  [ -f "$f" ] || { echo "ERR: Missing $f"; return 1; }
  if ! grep -q "<!-- PASTE START -->" "$f"; then
    awk -v c="  <!-- PASTE START -->\n  <!-- PASTE END -->" '
      /<main[^>]*>/ && !ins { print; print c; ins=1; next } { print }
    ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  fi
}

replace_between_markers() {
  local f="$1" payload="$2"
  awk -v P="$payload" '
    BEGIN{skip=0}
    /<!-- PASTE START -->/ { print; print P; skip=1; next }
    skip && /<!-- PASTE END -->/ { print; skip=0; next }
    skip { next }
    { print }
  ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}

build_boxes() {
  awk -v FS="\t" -v TAG="$TAG" -v TD="$TMP" '
    NR==1 { next }                      # skip header
    /^#/ || NF<4 { next }               # comments/blank
    {
      page=$1; title=$2; label=$3; url=$4
      if (!(page in opened)) {
        opened[page]=1; titles[page]=title
        out[page] = "<section class=\"deal-box\">\n  <h2>" title "</h2>\n  <p>Quick picks on Amazon (text links only):</p>\n  <ul>\n"
      }
      u=url
      if (u !~ /[?&]tag=/) u = u ((u ~ /\?/) ? "&" : "?") "tag=" TAG
      out[page] = out[page] "    <li><a href=\"" u "\" target=\"_blank\" rel=\"nofollow sponsored\">" label "</a></li>\n"
    }
    END{
      for (p in out) {
        print out[p] "  </ul>\n</section>" > (TD "/" p ".html")
      }
    }
  ' "$DATA"
}

main() {
  [ -f "$DATA" ] || { echo "ERR: $DATA missing"; exit 1; }
  build_boxes
  # Pages we support (one box per page)
  pages=(boards darts surrounds mats flights shafts under-10)
  for p in "${pages[@]}"; do
    f="$ROOT/$p.html"
    ensure_markers "$f"
    replace_between_markers "$f" "$(cat "$TMP/$p.html" 2>/dev/null || true)"
  done
  echo "✅ Boxes updated from $DATA"
}
main "$@"
