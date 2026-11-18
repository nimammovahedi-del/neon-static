#!/usr/bin/env python3
"""Assemble the kit sheet: build/kit_shots/shot_XX.png (+ .txt captions) -> docs/looks/kit_sheet.png.
Usage: python3 tools/kit_sheet.py <shots dir> <out.png>   (called by tools/render_looks.sh kit)"""
import sys, os, glob, textwrap
from PIL import Image, ImageDraw, ImageFont

src, out = sys.argv[1], sys.argv[2]
shots = sorted(glob.glob(os.path.join(src, "shot_*.png")))
if not shots:
    sys.exit("no shots in " + src)
cols = 5
tw = 1000
first = Image.open(shots[0])
th = int(tw * first.height / first.width)
cap = 90
pad = 18
rows = (len(shots) + cols - 1) // cols
W = cols * tw + (cols + 1) * pad
H = 120 + rows * (th + cap + pad) + pad
sheet = Image.new("RGB", (W, H), (12, 12, 16))
d = ImageDraw.Draw(sheet)
ft = ImageFont.load_default(size=54)
fh = ImageFont.load_default(size=34)
fs = ImageFont.load_default(size=22)
d.text((pad, 30), "NEON STATIC - model kit (Blender-generated GLBs, Godot materials, look N)", font=ft, fill=(235, 235, 245))
for i, path in enumerate(shots):
    im = Image.open(path).convert("RGB").resize((tw, th), Image.LANCZOS)
    x = pad + (i % cols) * (tw + pad)
    y = 120 + (i // cols) * (th + cap + pad)
    sheet.paste(im, (x, y))
    txt = path[:-4] + ".txt"
    title, names = os.path.basename(path), ""
    if os.path.exists(txt):
        lines = open(txt).read().split("\n", 1)
        title = lines[0]
        names = lines[1] if len(lines) > 1 else ""
    d.text((x + 4, y + th + 8), title, font=fh, fill=(255, 120, 200))
    d.text((x + 4, y + th + 50), textwrap.shorten(names, 88), font=fs, fill=(170, 200, 220))
sheet.save(out)
print("KIT SHEET", out, sheet.size)
