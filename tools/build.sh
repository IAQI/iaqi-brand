#!/usr/bin/env bash
# Rebuild every asset in this repo from the designer's original files.
#
#   tools/build.sh "/path/to/Logo files"
#
# Needs Inkscape and ImageMagick 7 (`magick`). The source folder must contain
# DIN.ttf (FF DIN, a commercial FontShop/Monotype font): it is used only to
# outline the logo text and is never copied into the repo.
set -euo pipefail

SRC=${1:?usage: tools/build.sh "/path/to/Logo files"}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

MAROON="#660038"

# Private fontconfig that adds DIN.ttf without installing it system-wide.
mkdir -p "$WORK/fonts"
cp "$SRC/DIN.ttf" "$WORK/fonts/"
cat > "$WORK/fonts.conf" <<EOF
<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <include ignore_missing="yes">/opt/homebrew/etc/fonts/fonts.conf</include>
  <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
  <dir>$WORK/fonts</dir>
  <cachedir>$WORK/fc-cache</cachedir>
</fontconfig>
EOF
export FONTCONFIG_FILE="$WORK/fonts.conf"

cd "$ROOT"
mkdir -p logos/svg logos/png logos/jpg favicon source previews

# ── SVG: outline the DIN text so the logo renders without the font ──────────
svg() { inkscape "$SRC/Logos (SVG)/$1.svg" --export-text-to-path --export-plain-svg -o "logos/svg/$2.svg" 2>/dev/null; }
svg "IAQI logo coloured"             iaqi-logo-coloured
svg "IAQI logo black"                iaqi-logo-black
svg "IAQI logo white"                iaqi-logo-white
svg "IAQI logo horizontal"           iaqi-logo-horizontal
svg "IAQI logo coloured - no text"   iaqi-mark-coloured
svg "IAQI logo black - no text"      iaqi-mark-black
svg "IAQI logo white - no text"      iaqi-mark-white
if grep -l '<text' logos/svg/*.svg; then echo "error: un-outlined text left in the SVGs above" >&2; exit 1; fi

# ── PNG and JPEG: designer exports, renamed ──────────────────────────────────
P="$SRC/Logos (PNG)"; J="$SRC/Logos (JPEG)"
for c in coloured black white; do
  cp "$P/IAQI logo $c.png"                logos/png/iaqi-logo-$c.png
  cp "$P/IAQI logo $c - no text.png"      logos/png/iaqi-mark-$c.png
  cp "$P/IAQI logo $c - no text 200px.png" logos/png/iaqi-mark-$c-200.png
  cp "$J/IAQI logo _$c - no text.jpg"     logos/jpg/iaqi-mark-$c.jpg
done
cp "$P/IAQI logo horizontal logo.png"          logos/png/iaqi-logo-horizontal.png
cp "$P/IAQI logo horizontal 240x56.png"        logos/png/iaqi-logo-horizontal-240x56.png
cp "$P/IAQI logo horizontal white 240x56.png"  logos/png/iaqi-logo-horizontal-white-240x56.png
cp "$P/IAQI logo coloured - no text 240x56.png" logos/png/iaqi-mark-coloured-240x56.png
cp "$P/IAQI logo white - no text 240x56.png"   logos/png/iaqi-mark-white-240x56.png
cp "$J/IAQI logo _coloured.jpg"                logos/jpg/iaqi-logo-coloured.jpg
cp "$J/IAQI logo _black.jpg"                   logos/jpg/iaqi-logo-black.jpg
cp "$J/IAQI logo _horizontal logo.jpg"         logos/jpg/iaqi-logo-horizontal.jpg
# The designer's "_white.jpg" is white on white (blank); rebuild it on maroon,
# like the white mark JPEG.
magick logos/png/iaqi-logo-white.png -background "$MAROON" -flatten -quality 92 logos/jpg/iaqi-logo-white.jpg

cp "$SRC/IAQI logo - working file.ai" source/IAQI-logo-working-file.ai

# ── Favicon set, rendered from favicon/favicon.svg (kept in the repo) ────────
r() { inkscape "$1" -w "$2" -h "$2" -o "$3" 2>/dev/null; }
r favicon/favicon.svg 512 favicon/icon-512.png
r favicon/favicon.svg 192 favicon/icon-192.png
r favicon/favicon.svg 16 "$WORK/f16.png"; r favicon/favicon.svg 32 "$WORK/f32.png"; r favicon/favicon.svg 48 "$WORK/f48.png"
magick "$WORK/f16.png" "$WORK/f32.png" "$WORK/f48.png" favicon/favicon.ico
# iOS rounds the corners itself and shows transparency as black: fill them.
r favicon/favicon.svg 180 "$WORK/touch.png"
magick "$WORK/touch.png" -background "$MAROON" -flatten favicon/apple-touch-icon.png

# ── README previews ──────────────────────────────────────────────────────────
prev() { # svg, background, output
  inkscape "logos/svg/$1.svg" -w 560 -o "$WORK/p.png" 2>/dev/null
  magick "$WORK/p.png" -resize 280x280 -background "$2" -gravity center -extent 360x360 "previews/$1.png"
}
for c in coloured black; do prev iaqi-logo-$c white; prev iaqi-mark-$c white; done
prev iaqi-logo-white "$MAROON"; prev iaqi-mark-white "$MAROON"
inkscape logos/svg/iaqi-logo-horizontal.svg -w 1200 -o "$WORK/h.png" 2>/dev/null
magick "$WORK/h.png" -resize 640x -background white -gravity center -extent 740x320 previews/iaqi-logo-horizontal.png

# Favicon at the sizes browsers use, enlarged with nearest-neighbour.
fav=()
for s in 16 32 48; do
  r favicon/favicon.svg $s "$WORK/fs$s.png"
  magick "$WORK/fs$s.png" -filter point -resize 96x96 -background none -gravity center -extent 120x120 "$WORK/fz$s.png"
  fav+=("$WORK/fz$s.png")
done
r favicon/favicon.svg 96 "$WORK/fz96.png"
magick "$WORK/fz96.png" -background none -gravity center -extent 120x120 "$WORK/fz96b.png"
magick "${fav[@]}" "$WORK/fz96b.png" +append +repage -background white -flatten previews/favicon.png

# Clear space: the shaded band is the minimum free margin, 1/8 of the logo width.
inkscape logos/svg/iaqi-mark-coloured.svg -w 400 -h 400 -o "$WORK/m.png" 2>/dev/null
magick -size 500x500 xc:"#EAF3FB" -fill white -draw "rectangle 50,50 449,449" \
  "$WORK/m.png" -gravity center -composite \
  -fill none -stroke "#7FA9CC" -strokewidth 1 -draw "rectangle 50,50 449,449" -draw "rectangle 0,0 499,499" \
  -stroke none -fill "#3D6A8F" -pointsize 20 -draw "text 0,-226 'x'" -draw "text -226,0 'x'" \
  -gravity south -background white -splice 0x40 -fill "#333" -annotate +0+10 "x = 1/8 of the logo width, on every side" \
  previews/clear-space.png

# Minimum sizes: each variant just below and at its recommended minimum.
cell() { # svg, width, caption, colour, output
  inkscape "logos/svg/$1.svg" -w "$2" -o "$WORK/c.png" 2>/dev/null
  magick "$WORK/c.png" -background white -flatten -gravity center -extent 230x230 \
    -gravity south -splice 0x34 -fill "$4" -pointsize 15 -annotate +0+8 "$3" "$5"
}
cell iaqi-mark-coloured 24  "mark 24px: too small"  "#B00020" "$WORK/s1.png"
cell iaqi-mark-coloured 48  "mark 48px: minimum"    "#1E6B30" "$WORK/s2.png"
cell iaqi-logo-coloured 120 "logo 120px: too small" "#B00020" "$WORK/s3.png"
cell iaqi-logo-coloured 200 "logo 200px: minimum"   "#1E6B30" "$WORK/s4.png"
magick "$WORK"/s[1-4].png +append +repage previews/minimum-sizes.png

# Colour swatches for the README.
for h in 660038 B7D8F2 FFFFFF 000000; do
  magick -size 22x22 xc:"#$h" -bordercolor "#999999" -border 1 "previews/swatch-$h.png"
done

echo "built into $ROOT"
