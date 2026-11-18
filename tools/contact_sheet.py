#!/usr/bin/env python3
"""Contact sheet of all rendered looks in docs/looks (neutral.png + look_*.png) with labels.
Usage: python3 tools/contact_sheet.py <looks dir> <out.png>"""
import sys, os, glob
from PIL import Image, ImageDraw, ImageFont

src, out = sys.argv[1], sys.argv[2]
files = []
if os.path.exists(os.path.join(src, "neutral.png")):
    files.append(("N", os.path.join(src, "neutral.png")))
for p in sorted(glob.glob(os.path.join(src, "look_*.png"))):
    files.append((os.path.basename(p)[5:-4], p))
if not files:
    sys.exit("no looks found")
cols = 3
tw, th = 960, 540
rows = (len(files) + cols - 1) // cols
sheet = Image.new("RGB", (cols * tw, rows * (th + 50)), (10, 10, 12))
d = ImageDraw.Draw(sheet)
f = ImageFont.load_default(size=34)
for i, (lid, p) in enumerate(files):
    im = Image.open(p).convert("RGB").resize((tw, th), Image.LANCZOS)
    x, y = (i % cols) * tw, (i // cols) * (th + 50)
    sheet.paste(im, (x, y + 50))
    d.text((x + 10, y + 8), "look " + lid, font=f, fill=(240, 240, 240))
sheet.save(out)
print("CONTACT", out, sheet.size)
