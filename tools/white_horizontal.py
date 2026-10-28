"""Compose the white horizontal logo, which the designer did not export as SVG.

It is the designer's white mark (a single-colour drawing: everything white,
no blue ellipses) placed where the mark sits in the horizontal logo, plus the
horizontal logo's wording in white. The wording is still live FF DIN text;
build.sh outlines it afterwards.

    python3 tools/white_horizontal.py WHITE_MARK.svg HORIZONTAL.svg OUT.svg
"""
import re
import sys

# The horizontal logo's mark is the standalone mark shifted by this offset
# (measured from the vertical stroke of the right-hand "I").
DX, DY = -93.02, -0.30

white_mark, horizontal, out = sys.argv[1:4]
mark = open(white_mark, encoding="utf-8").read()
horiz = open(horizontal, encoding="utf-8").read()

viewbox = re.search(r'viewBox="([^"]+)"', horiz).group(1)
mark_body = re.search(r'<g id="Layer_1-2"[^>]*>(.*)</g>\s*</svg>', mark, re.S).group(1)
text = re.search(r"<text\b.*?</text>", horiz, re.S).group(0)
text_class = re.search(r'<text class="([^"]+)"', text).group(1)
font_size = re.search(r"\." + text_class + r"\s*\{[^}]*font-size:\s*([\d.]+px)", horiz, re.S).group(1)
text = re.sub(r' class="[^"]+"', f' fill="#fff" font-family="DIN" font-size="{font_size}"', text, count=1)

svg = f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="{viewbox}">
  <defs><style>.cls-1, .cls-2 {{ fill: #fff; }}</style></defs>
  <g transform="translate({DX} {DY})">{mark_body}</g>
  {text}
</svg>
"""
open(out, "w", encoding="utf-8").write(svg)
