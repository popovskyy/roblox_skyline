"""Flat worn-cream item icons (The Last of Us / Days Gone look).

Writes assets/icons/svg/<ItemId>.svg and renders assets/icons/<ItemId>.png (256px, transparent)
with headless Chrome, so no extra Python packages are needed.
    python scripts/build_icons.py            # all icons
    python scripts/build_icons.py Club Pipe  # some
"""

import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SVG_DIR = os.path.join(ROOT, "assets", "icons", "svg")
PNG_DIR = os.path.join(ROOT, "assets", "icons")
CHROME = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
]
SIZE = 256
# Long thin items get blown up a bit more so they read at hotbar size.
SCALE = {"Club": 1.22, "Pipe": 1.2, "Machete": 1.25, "Crowbar": 1.18, "Flashlight": 1.15, "Scrap": 1.1}
CREAM = "#e9dfc6"

# Each icon: (body, cut, rotate). body = cream shapes, cut = details knocked out of them (drawn
# black inside a mask). Both in a 0..100 box; rotate turns the whole icon around the centre.
ICONS = {
    "Key": (
        """
        <circle cx="50" cy="24" r="15"/>
        <rect x="45.5" y="36" width="9" height="52" rx="1.5"/>
        <rect x="54" y="70" width="12" height="6" rx="1"/>
        <rect x="54" y="80" width="9" height="6" rx="1"/>""",
        """
        <circle cx="50" cy="24" r="6.5" fill="#000"/>
        <path d="M48 42 L48 66" stroke="#000" stroke-width="1.3"/>""",
        35,
    ),
    "Club": (
        """
        <path d="M46 88 L46 62 C46 52 38 46 38 36 L38 18 Q38 9 50 9 Q62 9 62 18 L62 36
                 C62 46 54 52 54 62 L54 88 Z"/>
        <ellipse cx="50" cy="89" rx="6.5" ry="3.2"/>
        <g fill="none" stroke="{c}" stroke-width="2.4" stroke-linecap="round">
          <path d="M41 20 L33 16"/><path d="M41 30 L32 31"/>
          <path d="M59 23 L67 19"/><path d="M59 34 L68 36"/><path d="M50 11 L52 3"/>
        </g>""",
        """
        <g stroke="#000" stroke-width="1.3"><path d="M44 68 L56 67"/><path d="M44 73 L56 72.5"/>
        <path d="M44 78 L56 77"/><path d="M44 83 L56 82.5"/></g>
        <path d="M45 26 L48 40" stroke="#000" stroke-width="1.2"/>""",
        40,
    ),
    "Pipe": (
        """
        <rect x="43" y="14" width="14" height="72" rx="1.5"/>
        <rect x="39.5" y="10" width="21" height="11" rx="2"/>
        <rect x="39.5" y="79" width="21" height="11" rx="2"/>
        <rect x="41.5" y="45" width="17" height="10" rx="1.5"/>""",
        """
        <g stroke="#000" stroke-width="1.1"><path d="M40 13.5 H60"/><path d="M40 17.5 H60"/>
        <path d="M40 82.5 H60"/><path d="M40 86.5 H60"/></g>
        <path d="M48 24 L48 42 M48 58 L48 76" stroke="#000" stroke-width="1.4"/>""",
        -38,
    ),
    "Machete": (
        """
        <rect x="45" y="66" width="10" height="25" rx="3.5"/>
        <rect x="39" y="62" width="22" height="5" rx="2"/>
        <path d="M45 62 L45 24 Q45 10 57 7 Q64 14 61 32 L56 62 Z"/>""",
        """
        <circle cx="50" cy="73" r="1.7" fill="#000"/><circle cx="50" cy="83" r="1.7" fill="#000"/>
        <circle cx="61.5" cy="41" r="2" fill="#000"/><circle cx="59.6" cy="50" r="1.3" fill="#000"/>
        <path d="M49 58 L49 26 Q49 17 55 13" fill="none" stroke="#000" stroke-width="1.2"/>""",
        42,
    ),
    "Crowbar": (
        """
        <path d="M36 88 L61 24 Q66 9 55 9 Q49 9 46 15" fill="none" stroke="{c}" stroke-width="10"
              stroke-linecap="round" stroke-linejoin="round"/>
        <path d="M31 86 L40 91 L35 94 Z"/>""",
        """
        <path d="M46.5 14.5 L51 12.5" stroke="#000" stroke-width="1.6"/>
        <path d="M39 79 L42 71 M45 63 L47 58" stroke="#000" stroke-width="1.2"/>""",
        0,
    ),
    "Bandage": (
        """
        <circle cx="42" cy="48" r="26"/>
        <path d="M42 66 L84 66 L88 70 L85 73 L89 77 L84 74 L42 74 Z"/>""",
        """
        <circle cx="42" cy="48" r="8.5" fill="#000"/>
        <circle cx="42" cy="48" r="17" fill="none" stroke="#000" stroke-width="1.4"
                stroke-dasharray="70 37"/>
        <g stroke="#000" stroke-width="0.9"><path d="M56 66 L64 74 M64 66 L72 74 M72 66 L80 74"/>
        <path d="M64 66 L56 74 M72 66 L64 74 M80 66 L72 74"/></g>""",
        0,
    ),
    "Medkit": (
        """
        <rect x="13" y="30" width="74" height="53" rx="7"/>
        <path d="M37 31 L37 20 Q37 17 40 17 L60 17 Q63 17 63 20 L63 31" fill="none" stroke="{c}"
              stroke-width="6"/>""",
        """
        <path d="M44 42 H56 V51 H65 V63 H56 V72 H44 V63 H35 V51 H44 Z" fill="#000"/>
        <path d="M13 38 H87" stroke="#000" stroke-width="1.3"/>
        <circle cx="22" cy="75" r="1.6" fill="#000"/><circle cx="78" cy="75" r="1.6" fill="#000"/>""",
        0,
    ),
    "Food": (
        """
        <ellipse cx="50" cy="24" rx="25" ry="7"/>
        <rect x="25" y="24" width="50" height="56"/>
        <ellipse cx="50" cy="80" rx="25" ry="7"/>""",
        """
        <ellipse cx="50" cy="24" rx="19.5" ry="4" fill="none" stroke="#000" stroke-width="1.5"/>
        <circle cx="58" cy="23" r="3" fill="none" stroke="#000" stroke-width="1.2"/>
        <g fill="none" stroke="#000" stroke-width="1.5">
          <path d="M25 37 Q50 44 75 37"/><path d="M25 67 Q50 74 75 67"/></g>
        <path d="M37 50 Q50 46 63 50 Q50 58 37 50 Z M63 50 L69 46 L69 55 Z" fill="#000"/>""",
        0,
    ),
    "Scrap": (
        """
        <polygon points="62,60 51,79.05 29,79.05 18,60 29,40.95 51,40.95"/>
        <polygon points="78,34 73,42.66 63,42.66 58,34 63,25.34 73,25.34"/>
        <path d="M68 34 L88 14" stroke="{c}" stroke-width="8" stroke-linecap="round"/>""",
        """
        <circle cx="40" cy="60" r="9" fill="#000"/>
        <path d="M63 34 H73" stroke="#000" stroke-width="2"/>
        <g stroke="#000" stroke-width="1.1"><path d="M74 21 L80 27 M78 17 L84 23 M82 13 L87 18"/></g>
        <path d="M29 47 L24 56" stroke="#000" stroke-width="1.1"/>""",
        0,
    ),
    "Electronics": (
        """
        <rect x="27" y="27" width="46" height="46" rx="3"/>
        <g stroke="{c}" stroke-width="3.2" stroke-linecap="round">
          <path d="M35 27 V17 M45 27 V17 M55 27 V17 M65 27 V17"/>
          <path d="M35 73 V83 M45 73 V83 M55 73 V83 M65 73 V83"/>
          <path d="M27 35 H17 M27 45 H17 M27 55 H17 M27 65 H17"/>
          <path d="M73 35 H83 M73 45 H83 M73 55 H83 M73 65 H83"/></g>""",
        """
        <rect x="38" y="38" width="24" height="24" rx="1.5" fill="none" stroke="#000" stroke-width="1.5"/>
        <circle cx="33" cy="33" r="2.2" fill="#000"/>
        <path d="M44 50 H56 M50 44 V56" stroke="#000" stroke-width="1.3"/>""",
        0,
    ),
    "Cable": (
        """
        <g fill="none" stroke="{c}" stroke-width="6" stroke-linecap="round">
          <circle cx="42" cy="56" r="25"/><circle cx="46" cy="58" r="16"/>
          <path d="M66 46 Q82 40 79 27"/></g>
        <rect x="71" y="12" width="16" height="15" rx="2"/>
        <g stroke="{c}" stroke-width="2.8"><path d="M75.5 12 V4 M82.5 12 V4"/></g>""",
        """
        <path d="M71 21 H87" stroke="#000" stroke-width="1.2"/>""",
        0,
    ),
    "Motor": (
        """
        <rect x="16" y="30" width="54" height="44" rx="6"/>
        <rect x="69" y="36" width="9" height="32" rx="2"/>
        <rect x="77" y="49" width="15" height="6" rx="1"/>
        <rect x="22" y="73" width="42" height="7"/>
        <rect x="16" y="79" width="54" height="5" rx="1"/>""",
        """
        <g stroke="#000" stroke-width="2"><path d="M26 34 V70 M34 34 V70 M42 34 V70 M50 34 V70 M58 34 V70"/></g>
        <path d="M84 49 V55" stroke="#000" stroke-width="1.2"/>
        <circle cx="22" cy="81.5" r="1.3" fill="#000"/><circle cx="64" cy="81.5" r="1.3" fill="#000"/>""",
        0,
    ),
    "Flashlight": (
        """
        <rect x="44" y="40" width="12" height="49" rx="3"/>
        <path d="M37 19 L63 19 L58 41 L42 41 Z"/>
        <g stroke="{c}" stroke-width="3" stroke-linecap="round">
          <path d="M50 13 V4"/><path d="M40 14 L33 7"/><path d="M60 14 L67 7"/></g>""",
        """
        <path d="M38 23 H62" stroke="#000" stroke-width="1.4"/>
        <rect x="47.5" y="48" width="5" height="8" rx="1" fill="#000"/>
        <g stroke="#000" stroke-width="1.1"><path d="M44 66 H56 M44 71 H56 M44 76 H56 M44 81 H56"/></g>""",
        34,
    ),
}

FILTER = """
<filter id="worn" x="-15%" y="-15%" width="130%" height="130%">
  <feTurbulence type="fractalNoise" baseFrequency="0.55" numOctaves="2" seed="{seed}" result="n"/>
  <feDisplacementMap in="SourceGraphic" in2="n" scale="1.8" xChannelSelector="R" yChannelSelector="G" result="d"/>
  <feTurbulence type="fractalNoise" baseFrequency="0.06" numOctaves="3" seed="{seed2}" result="blot"/>
  <feColorMatrix in="blot" type="matrix" result="blotMask"
     values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  -10 0 0 0 7.6"/>
  <feTurbulence type="fractalNoise" baseFrequency="1.6" numOctaves="1" seed="{seed3}" result="grain"/>
  <feColorMatrix in="grain" type="matrix" result="grainMask"
     values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  -12 0 0 0 9.0"/>
  <feComposite in="d" in2="blotMask" operator="in" result="d2"/>
  <feComposite in="d2" in2="grainMask" operator="in" result="worn"/>
  <feDropShadow in="worn" dx="0" dy="1.2" stdDeviation="0.8" flood-color="#000" flood-opacity="0.55"/>
</filter>"""


def svg_for(name, index):
    body, cut, rot = ICONS[name]
    body = body.replace("{c}", CREAM)
    scale = SCALE.get(name, 1.08)
    filt = FILTER.format(seed=11 + index, seed2=31 + index * 7, seed3=5 + index * 3)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" viewBox="0 0 100 100">
<defs>{filt}
<mask id="cut" maskUnits="userSpaceOnUse" x="-20" y="-20" width="140" height="140">
  <rect x="-20" y="-20" width="140" height="140" fill="#fff"/>
  <g transform="translate(50 50) scale({scale}) translate(-50 -50) rotate({rot} 50 50)">{cut}</g>
</mask></defs>
<g filter="url(#worn)"><g mask="url(#cut)"><g transform="translate(50 50) scale({scale}) translate(-50 -50) rotate({rot} 50 50)" fill="{CREAM}">{body}</g></g></g>
</svg>
"""


def render(svg_path, png_path):
    chrome = next(p for p in CHROME if os.path.exists(p))
    html = svg_path[:-4] + ".html"
    with open(html, "w", encoding="utf-8") as f:
        f.write(
            "<html><body style='margin:0;background:transparent'>"
            f"<img src='{os.path.basename(svg_path)}' width='{SIZE}' height='{SIZE}' style='display:block'>"
            "</body></html>"
        )
    subprocess.run(
        [
            chrome,
            "--headless",
            "--disable-gpu",
            "--hide-scrollbars",
            "--default-background-color=00000000",
            f"--window-size={SIZE},{SIZE}",
            f"--screenshot={png_path}",
            "file:///" + html.replace("\\", "/"),
        ],
        check=True,
        capture_output=True,
    )
    os.remove(html)


def main():
    os.makedirs(SVG_DIR, exist_ok=True)
    names = sys.argv[1:] or list(ICONS)
    for i, name in enumerate(ICONS):
        if name not in names:
            continue
        svg_path = os.path.join(SVG_DIR, name + ".svg")
        with open(svg_path, "w", encoding="utf-8") as f:
            f.write(svg_for(name, i))
        render(svg_path, os.path.join(PNG_DIR, name + ".png"))
        print("icon", name)


if __name__ == "__main__":
    main()
