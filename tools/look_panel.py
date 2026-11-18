"""Build docs/looks/panel.jpg: 4x2 sheet of look_A..look_H, each cell 960x540 with letter + name on a dark strip."""
import os, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
D = os.path.join(ROOT, "docs", "looks")
NAMES = [("A", "Magenta Rain"), ("B", "Sodium Noir"), ("C", "Acid Industrial"), ("D", "Red Lantern"),
         ("E", "Cold Corporate"), ("F", "Predawn Smog"), ("G", "Mono Red"), ("H", "Vapor Bloom")]
CW, CH, STRIP = 960, 540, 64
out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(D, "panel.jpg")


def font(size):
    for p in ["/System/Library/Fonts/Supplemental/Arial Bold.ttf", "/System/Library/Fonts/Helvetica.ttc",
              "/Library/Fonts/Arial.ttf"]:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()

big, mid = font(44), font(34)
sheet = Image.new("RGB", (CW * 4, CH * 2), (8, 8, 10))
for i, (lid, name) in enumerate(NAMES):
    p = os.path.join(D, "look_%s.png" % lid)
    x, y = (i % 4) * CW, (i // 4) * CH
    if os.path.exists(p):
        sheet.paste(Image.open(p).convert("RGB").resize((CW, CH), Image.LANCZOS), (x, y))
    ov = Image.new("RGBA", (CW, STRIP), (0, 0, 0, 200))
    sheet.paste(ov, (x, y + CH - STRIP), ov)
    d = ImageDraw.Draw(sheet)
    d.text((x + 22, y + CH - STRIP + 8), lid, font=big, fill=(255, 255, 255))
    d.text((x + 78, y + CH - STRIP + 14), name, font=mid, fill=(230, 230, 230))
    d.rectangle([x, y, x + CW - 1, y + CH - 1], outline=(0, 0, 0), width=2)
sheet.save(out, quality=90)
print("->", out)
