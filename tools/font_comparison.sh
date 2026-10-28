#!/usr/bin/env bash
# Render previews/font-comparison.png: the horizontal logo with its wording in
# FF DIN (the original) and in free alternatives, each with an overlay against
# the original.
#
#   tools/font_comparison.sh "/path/to/Logo files"
#
# Needs Inkscape, ImageMagick 7 and network access (Barlow is fetched from
# github.com/google/fonts). DIN.ttf comes from the designer's folder and is
# never copied into the repo.
set -euo pipefail

SRC=${1:?usage: tools/font_comparison.sh "/path/to/Logo files"}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT
H="$SRC/Logos (SVG)/IAQI logo horizontal.svg"

mkdir -p "$W/fonts"
cp "$SRC/DIN.ttf" "$ROOT/fonts/d-din/D-DIN.ttf" "$W/fonts/"
for f in barlow/Barlow-Regular.ttf barlowsemicondensed/BarlowSemiCondensed-Regular.ttf; do
  curl -sfL -o "$W/fonts/$(basename "$f")" "https://github.com/google/fonts/raw/main/ofl/$f"
done
cat > "$W/fonts.conf" <<EOF
<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <include ignore_missing="yes">/opt/homebrew/etc/fonts/fonts.conf</include>
  <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
  <dir>$W/fonts</dir><cachedir>$W/fc-cache</cachedir>
</fontconfig>
EOF
export FONTCONFIG_FILE="$W/fonts.conf"
cd "$W"

# variant <n> <css font declarations>: full logo (h<n>.png) and wording only (t<n>.png)
variant() {
  sed "s/font-family: DIN, DIN;/$2/" "$H" > "h$1.svg"
  python3 -I -c 'import re,sys; s=open(sys.argv[1]).read(); open(sys.argv[2],"w").write(re.sub(r"(<text[^>]*>.*?</text>)|<(path|circle|ellipse|rect|line)\b[^>]*/>", lambda m: m.group(1) or "", s, flags=re.S))' "h$1.svg" "t$1.svg"
  inkscape "h$1.svg" -w 1704 -o "h$1.png" 2>/dev/null
  inkscape "t$1.svg" -w 1704 -o "t$1.png" 2>/dev/null
  magick "h$1.png" -background white -flatten "h$1.png"
  magick "t$1.png" -background white -flatten "t$1.png"
  magick "t$1.png" -trim -format "%w" info: > "w$1"
}
variant 1 "font-family: DIN;"
variant 2 "font-family: 'D-DIN';"
variant 3 "font-family: 'Barlow';"
variant 4 "font-family: 'Barlow Semi Condensed';"
# D-DIN letter-spaced so its longest line (13 letters) matches FF DIN's width.
SPACING=$(python3 -I -c "print(round(($(cat w1) - $(cat w2)) / 12, 2))")
variant 5 "font-family: 'D-DIN'; letter-spacing: ${SPACING}px;"

names=("FF DIN (original, commercial)" "D-DIN (free, SIL OFL), same size" "D-DIN, letter-spaced to the original width" "Barlow (free, SIL OFL)" "Barlow Semi Condensed (free, SIL OFL)")
short=("FF DIN" "D-DIN" "D-DIN spaced" "Barlow" "Barlow Semi Condensed")
order=(1 2 5 3 4)
k=0
for i in "${order[@]}"; do
  n=${names[$k]}; s=${short[$k]}; k=$((k + 1))
  pct=$(python3 -I -c "print(round(($(cat "w$i") / $(cat w1) - 1) * 100))")
  lab=$n
  if [ "$i" != 1 ]; then
    if [ "$pct" = 0 ]; then lab="$n:  same width"; else lab="$n:  wording ${pct#-}% narrower"; fi
  fi
  magick "h$i.png" -resize 860x -background white -gravity center -extent 900x360 \
    -gravity northwest -splice 0x40 -fill "#222" -pointsize 21 -annotate +18+10 "$lab" "row$i.png"
  if [ "$i" != 1 ]; then
    magick t1.png -crop 984x683+720+0 +repage base.png
    magick "t$i.png" -crop 984x683+720+0 +repage -colorspace gray -negate mask.png
    magick -size "$(magick identify -format %wx%h mask.png)" xc:"#1f77c9" mask.png -alpha off \
      -compose copyopacity -composite -channel A -evaluate multiply 0.6 +channel blue.png
    magick base.png blue.png -compose over -composite -resize 430x -background white -gravity center -extent 450x360 \
      -gravity northwest -splice 0x40 -fill "#222" -pointsize 16 -annotate +12+12 "Overlay: FF DIN maroon, $s blue" "ov$i.png"
  else
    magick -size 450x400 xc:white -fill "#444" -pointsize 17 -gravity center -annotate +0+0 \
      "The overlays on the right put each\nfree font on top of the original.\nShared strokes look dark purple;\ndifferences show as separate\nmaroon and blue shapes." ov1.png
  fi
  magick "row$i.png" "ov$i.png" +append "r$i.png"
done
magick r1.png r2.png r5.png r3.png r4.png -background "#cccccc" -splice 0x4 -append +repage \
  -define png:exclude-chunks=date,time,tIME "$ROOT/previews/font-comparison.png"
echo "letter-spacing that matches FF DIN: ${SPACING}px at the logo's 130.04px font size"
echo "wrote $ROOT/previews/font-comparison.png"
