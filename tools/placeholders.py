#!/usr/bin/env python3
"""Make the stand-in images for the conference websites (QIP, QCrypt, TQC).

    python3 tools/placeholders.py

Writes placeholders/*.svg: what a new conference year shows until its own logo,
photos and banner exist. Each one says what to deliver in its place (see
"Stand-ins for conference websites" in README.md). They use the IAQI mark as it
is, from logos/svg/, on IAQI maroon, and contain no conference name or year, so
all three conferences share them. The conference websites get them through the
shared theme (github.com/IAQI/conference-theme, static/images/placeholder/).
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "placeholders"
MAROON, BLUE, WHITE = "#660038", "#B7D8F2", "#FFFFFF"
FONT = "D-DIN, Barlow, 'DIN Alternate', Arial, Helvetica, sans-serif"


def mark(variant, x, y, size):
    """The IAQI mark (logos/svg/iaqi-mark-<variant>.svg), unchanged, as a nested svg."""
    src = (ROOT / "logos" / "svg" / f"iaqi-mark-{variant}.svg").read_text(encoding="utf-8")
    src = re.sub(r"<\?xml[^>]*\?>\s*", "", src)
    view_box = re.search(r'viewBox="([^"]+)"', src).group(1)
    inner = src[src.index(">", src.index("<svg")) + 1:src.rindex("</svg>")]
    return (f'<svg x="{x}" y="{y}" width="{size}" height="{size}" viewBox="{view_box}">'
            f"{inner}</svg>")


def text(x, y, size, content, fill=WHITE, anchor="middle", weight="normal"):
    content = content.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    return (f'<text x="{x}" y="{y}" font-family="{FONT}" font-size="{size}" '
            f'font-weight="{weight}" fill="{fill}" text-anchor="{anchor}">{content}</text>')


def rings(cx, cy, scale, opacity=0.35):
    """Light-blue ellipses, after the orbits in the mark, as a quiet background."""
    out = []
    for rx, ry, rot in ((1.0, 0.36, -18), (1.0, 0.36, 18), (0.62, 0.62, 0)):
        out.append(f'<ellipse cx="{cx}" cy="{cy}" rx="{rx * scale:.0f}" ry="{ry * scale:.0f}" '
                   f'transform="rotate({rot} {cx} {cy})" fill="none" stroke="{BLUE}" '
                   f'stroke-width="{scale / 90:.1f}" opacity="{opacity}"/>')
    return "".join(out)


def svg(w, h, body, background=MAROON, label=""):
    bg = f'<rect width="{w}" height="{h}" fill="{background}"/>' if background else ""
    title = f"<title>{label}</title>" if label else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
            f'viewBox="0 0 {w} {h}">{title}{bg}{body}</svg>\n')


def background():
    # Home page photo: it fills the window (cropped at the sides on most
    # screens), with the logo and the dates in the middle column. So the spec
    # goes to the left of that column, inside what a 1280 px window still shows.
    w, h = 1920, 960
    body = rings(w / 2, h / 2, 900, 0.25)
    x = 240
    body += text(x, 400, 46, "Background photo", anchor="start", weight="bold")
    for i, line in enumerate(("1920 × 960 px JPEG,", "at most 500 KB.", "Keep the subject in the centre:",
                              "it is cropped to the window", "and darkened.")):
        body += text(x, 452 + 38 * i, 30, line, BLUE, "start")
    return svg(w, h, body, label="Stand-in: background photo of the home page")


def logo():
    # The big logo on the home page photo: transparent, white.
    s = 800
    body = (f'<circle cx="{s / 2}" cy="{s / 2}" r="{s / 2 - 12}" fill="{MAROON}" fill-opacity="0.55" '
            f'stroke="{WHITE}" stroke-width="6" stroke-dasharray="24 16"/>')
    body += mark("white", 250, 110, 300)
    body += text(s / 2, 500, 64, "Conference logo", weight="bold")
    body += text(s / 2, 560, 32, "SVG, or transparent PNG", BLUE)
    body += text(s / 2, 600, 32, "at least 800 px wide", BLUE)
    body += text(s / 2, 640, 32, "(shown 400 px wide)", BLUE)
    return svg(s, s, body, background=None, label="Stand-in: conference logo")


def header_logo():
    # Top bar: about 48 px tall and at most 180 px wide. A maroon tile, so it
    # shows on a coloured bar and on a white one.
    w, h = 360, 96
    body = f'<rect width="{w}" height="{h}" rx="14" fill="{MAROON}" stroke="{WHITE}" stroke-width="3"/>'
    body += mark("white", 14, 8, 80)
    body += text(108, 60, 38, "Logo", anchor="start", weight="bold")
    body += text(214, 58, 20, "header", BLUE, "start")
    return svg(w, h, body, background=None, label="Stand-in: header logo")


def banner():
    # Inside pages: shown 300 px high and cropped to the window width around
    # the centre, so everything stays in the middle band.
    w, h = 2000, 800
    body = rings(w / 2, h / 2, 1100, 0.25)
    body += mark("white", 560, 300, 200)
    body += text(800, 380, 64, "Banner", anchor="start", weight="bold")
    body += text(800, 440, 32, "2000 × 800 px JPEG, shown 300 px high", BLUE, "start")
    body += text(800, 485, 32, "Cropped around the centre: keep the subject in the middle", BLUE, "start")
    return svg(w, h, body, label="Stand-in: banner of the inside pages")


def person():
    # Team and speaker photos are small circles: no text, just a silhouette.
    s = 400
    body = (f'<circle cx="200" cy="160" r="78" fill="{MAROON}"/>'
            f'<path d="M 60 400 C 60 300 120 255 200 255 C 280 255 340 300 340 400 Z" fill="{MAROON}"/>')
    return svg(s, s, body, background=BLUE, label="Stand-in: photo (square JPEG, at least 400 px)")


def sponsor():
    # Sponsor logos are scaled to fit their box, so the label stays readable.
    w, h = 600, 200
    body = (f'<rect x="4" y="4" width="{w - 8}" height="{h - 8}" rx="16" fill="{WHITE}" '
            f'stroke="{MAROON}" stroke-width="5" stroke-dasharray="18 12"/>')
    body += mark("coloured", 30, 30, 140)
    body += text(190, 95, 44, "Sponsor logo", MAROON, "start", "bold")
    body += text(190, 140, 24, "SVG or transparent PNG, ≥ 600 px wide", MAROON, "start")
    return svg(w, h, body, background=None, label="Stand-in: sponsor logo")


def main():
    OUT.mkdir(exist_ok=True)
    for name, make in (("background", background), ("logo", logo), ("header-logo", header_logo),
                       ("banner", banner), ("person", person), ("sponsor", sponsor)):
        (OUT / f"{name}.svg").write_text(make(), encoding="utf-8")
        print(f"wrote placeholders/{name}.svg")


if __name__ == "__main__":
    main()
