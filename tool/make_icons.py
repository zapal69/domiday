"""Legacy launcher icons (mipmap-*/ic_launcher.png) from the domiday.com
favicon geometry: yellow square, dark pin, letter D. The SVG is rendered
with macOS QuickLook (qlmanage), then resized with Pillow. No remote assets."""
import subprocess
import tempfile
from pathlib import Path

from PIL import Image

root = Path(__file__).resolve().parents[1]
SVG = """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'>
<rect width='64' height='64' fill='#FFDA38'/>
<path d='M32 58S13 40 13 27a19 19 0 0 1 38 0c0 13-19 31-19 31z' fill='#20211E'/>
<path d='M27.5 18h4.5a9 9 0 0 1 0 18h-4.5z' fill='#FFDA38'/>
<rect x='27.5' y='18' width='5' height='18' fill='#FFDA38'/>
</svg>"""

with tempfile.TemporaryDirectory() as tmp:
    svg = Path(tmp) / "icon.svg"
    svg.write_text(SVG)
    subprocess.run(
        ["qlmanage", "-t", "-s", "864", "-o", tmp, str(svg)],
        check=True, capture_output=True,
    )
    image = Image.open(Path(tmp) / "icon.svg.png").convert("RGB")
    assert image.size == (864, 864), image.size
    for density, size in {
        "mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192
    }.items():
        path = root / "android/app/src/main/res" / f"mipmap-{density}/ic_launcher.png"
        image.resize((size, size), Image.Resampling.LANCZOS).save(path)
print("icons written")
