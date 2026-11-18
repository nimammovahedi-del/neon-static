#!/usr/bin/env python3
"""Generate the sign / billboard / screen art used by the Neon Static look test.

All art is stored as RGB MASKS, not colours, so every look can recolour it from its preset:
    R = panel / background area (may carry gradients and patterns)
    G = main text or main shape (the bright part)
    B = accent (borders, underlines, icons, stripes)
The shaders (godot/shaders/sign.gdshader, screen.gdshader, holo.gdshader) mix three preset colours.

Outputs (godot/assets/tex):
    signs_h.png    4 x 8 cells of 512x128   horizontal box signs / fascias / bands
    signs_v.png    8 x 2 cells of 128x512   vertical blade signs (stacked letters)
    glyph_cells.png 8 x 8 cells of 128x128  one glyph per cell (cube signs, small panels)
    billboards.png 2 x 4 cells of 1024x512  big billboards / holograms / LED screens
Run:  python3 tools/gen_textures.py
Words are invented (no brands). Text uses Pillow's bundled default font (rasterised into the PNG;
no font file is copied into the project) or the neon stroke font from tools/blender/glyphs.py.
"""
import os, sys, math, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "blender"))
from glyphs import GLYPHS  # noqa: E402

OUT = os.path.normpath(os.path.join(HERE, "..", "godot", "assets", "tex"))
os.makedirs(OUT, exist_ok=True)
rng = random.Random(7)

WORDS_H = ["NOVA", "KITE", "24H", "RAMEN", "PAWN", "HOTEL", "DATA", "ORBIT", "LUX", "MOTEL", "VOLT", "HALO",
           "ZENIT", "MIRA", "NOODLE", "BAR", "CLUB", "OPEN", "CAFE", "DINER", "ARCADE", "REPAIR", "PARTS", "CHIPS",
           "LIVE", "CLINIC", "KARAOKE", "NET", "BIO", "LAB", "GYM", "TAXI"]
WORDS_V = ["HOTEL", "RAMEN", "NOVA", "BAR", "KITE", "PAWN", "24H", "MIRA", "LUX", "HALO", "VOLT", "DATA",
           "ORBIT", "CLUB", "ZENIT", "MOTEL"]


def font(size):
    return ImageFont.load_default(size=size)


def stroke_text(draw, text, x, y, h, width, fill=255, spacing=0.22):
    """Draw text with the neon stroke font; (x, y) = top-left, h = cap height in px."""
    cx = x
    for ch in text:
        if ch == " ":
            cx += h * 0.5
            continue
        w, strokes = GLYPHS.get(ch, GLYPHS["O"])
        for s in strokes:
            pts = [(cx + px * h, y + (1 - py) * h) for px, py in s]
            draw.line(pts, fill=fill, width=width, joint="curve")
            r = width / 2
            for (px, py) in (pts[0], pts[-1]):
                draw.ellipse([px - r, py - r, px + r, py + r], fill=fill)
        cx += (w + spacing) * h
    return cx


def fit_stroke(draw, text, x, y, maxw, h, width):
    """Stroke text scaled down so it fits maxw; vertically centred on the requested box."""
    tw = stroke_width_of(text, h)
    if tw > maxw:
        k = maxw / tw
        y += h * (1 - k) / 2
        h *= k
        width = max(4, int(width * k))
    return stroke_text(draw, text, x, y, h, width)


def stroke_width_of(text, h, spacing=0.22):
    return sum(((GLYPHS.get(c, GLYPHS["O"])[0] + spacing) * h) if c != " " else h * 0.5 for c in text) - spacing * h


def fit_font(text, max_w, max_h, stroke=0):
    s = int(max_h)
    while s > 8:
        f = font(s)
        b = f.getbbox(text, stroke_width=stroke)
        if b[2] - b[0] <= max_w and b[3] - b[1] <= max_h:
            return f, b
        s -= 2
    return font(8), font(8).getbbox(text)


def channel_image(w, h):
    return [Image.new("L", (w, h), 0) for _ in range(3)]


def merge(ch):
    return Image.merge("RGB", ch)


# ------------------------------------------------------------------ horizontal signs
def sign_h(word, style):
    W, H = 512, 128
    R, G, B = channel_image(W, H)
    dr, dg, db = ImageDraw.Draw(R), ImageDraw.Draw(G), ImageDraw.Draw(B)
    m = 8
    if style == 0:  # plain lit panel, bold text
        dr.rectangle([0, 0, W, H], fill=200)
        f, b = fit_font(word, W - 60, H - 40, stroke=3)
        dg.text(((W - (b[2] - b[0])) / 2 - b[0], (H - (b[3] - b[1])) / 2 - b[1]), word, font=f, fill=255, stroke_width=3, stroke_fill=255)
        db.rectangle([m, m, W - m, H - m], outline=255, width=4)
    elif style == 1:  # neon stroke word on dark panel, underline accent
        dr.rectangle([0, 0, W, H], fill=40)
        hh = 74
        tw = stroke_width_of(word, hh)
        sc = min(1.0, (W - 60) / tw)
        hh *= sc
        tw = stroke_width_of(word, hh)
        stroke_text(dg, word, (W - tw) / 2, (H - hh) / 2 - 6, hh, max(6, int(9 * sc)))
        db.line([(40, H - 14), (W - 40, H - 14)], fill=255, width=5)
    elif style == 2:  # split panel: icon block left, text right
        dr.rectangle([0, 0, W, H], fill=170)
        db.rectangle([0, 0, H, H], fill=255)
        icon = rng.choice(["star", "bolt", "diamond", "ring", "cup", "bowl", "heart", "arrow"])
        w, strokes = GLYPHS[icon]
        for s in strokes:
            pts = [(18 + px * 92 / max(w, 1), 18 + (1 - py) * 92) for px, py in s]
            dg.line(pts, fill=255, width=8, joint="curve")
            dr.line(pts, fill=0, width=12, joint="curve")
        f, b = fit_font(word, W - H - 40, H - 44, stroke=2)
        dg.text((H + 20 - b[0], (H - (b[3] - b[1])) / 2 - b[1]), word, font=f, fill=255, stroke_width=2, stroke_fill=255)
    elif style == 3:  # stripes background, big text, chevrons
        for i in range(0, W, 24):
            dr.polygon([(i, 0), (i + 12, 0), (i + 12 - 30, H), (i - 30, H)], fill=120)
        dr.rectangle([0, 18, W, H - 18], fill=60)
        f, b = fit_font(word, W - 140, H - 50, stroke=2)
        dg.text(((W - (b[2] - b[0])) / 2 - b[0], (H - (b[3] - b[1])) / 2 - b[1]), word, font=f, fill=255, stroke_width=2, stroke_fill=255)
        for k in range(3):
            x = 16 + k * 16
            db.line([(x, 40), (x + 14, 64), (x, 88)], fill=255, width=6)
            x = W - 30 - k * 16
            db.line([(x + 14, 40), (x, 64), (x + 14, 88)], fill=255, width=6)
    else:  # gradient panel with outlined text and dots
        for y in range(H):
            dr.line([(0, y), (W, y)], fill=int(60 + 150 * (y / H)))
        f, b = fit_font(word, W - 80, H - 36, stroke=4)
        dg.text(((W - (b[2] - b[0])) / 2 - b[0], (H - (b[3] - b[1])) / 2 - b[1]), word, font=f, fill=0, stroke_width=4, stroke_fill=255)
        for i in range(12):
            x = 20 + i * (W - 40) / 11
            db.ellipse([x - 4, 8, x + 4, 16], fill=255)
            db.ellipse([x - 4, H - 16, x + 4, H - 8], fill=255)
    return merge([R, G, B])


def sign_v(word, style):
    W, H = 128, 512
    R, G, B = channel_image(W, H)
    dr, dg, db = ImageDraw.Draw(R), ImageDraw.Draw(G), ImageDraw.Draw(B)
    n = len(word)
    cell = (H - 40) / max(n, 3)
    dr.rectangle([0, 0, W, H], fill=50 if style % 2 else 190)
    for i, ch in enumerate(word):
        y = 20 + i * cell
        if style % 2:
            hh = min(cell * 0.72, 86)
            wch = GLYPHS.get(ch, GLYPHS["O"])[0] * hh
            stroke_text(dg, ch, (W - wch) / 2, y + (cell - hh) / 2, hh, 9)
        else:
            f, b = fit_font(ch, W - 30, cell - 16, stroke=2)
            dg.text(((W - (b[2] - b[0])) / 2 - b[0], y + (cell - (b[3] - b[1])) / 2 - b[1]), ch, font=f, fill=255, stroke_width=2, stroke_fill=255)
    db.rectangle([6, 6, W - 6, H - 6], outline=255, width=5)
    if style >= 2:
        db.rectangle([0, 0, W, 14], fill=255)
        db.rectangle([0, H - 14, W, H], fill=255)
    return merge([R, G, B])


def glyph_cell(ch, style):
    W = 128
    R, G, B = channel_image(W, W)
    dr, dg, db = ImageDraw.Draw(R), ImageDraw.Draw(G), ImageDraw.Draw(B)
    dr.rectangle([0, 0, W, W], fill=60 if style else 180)
    if ch in GLYPHS and len(ch) > 1 or style:
        w, strokes = GLYPHS.get(ch, GLYPHS["O"])
        hh = 84
        sc = hh / max(1.0, w if w > 1 else 1.0)
        x0 = (W - w * sc) / 2
        for s in strokes:
            pts = [(x0 + px * sc, (W - hh) / 2 + (1 - py) * hh) for px, py in s]
            dg.line(pts, fill=255, width=9, joint="curve")
    else:
        f, b = fit_font(ch, W - 30, W - 30, stroke=2)
        dg.text(((W - (b[2] - b[0])) / 2 - b[0], (W - (b[3] - b[1])) / 2 - b[1]), ch, font=f, fill=255, stroke_width=2, stroke_fill=255)
    db.rectangle([5, 5, W - 5, W - 5], outline=255, width=5)
    return merge([R, G, B])


# ------------------------------------------------------------------ billboards
def billboard(idx):
    W, H = 1024, 512
    R, G, B = channel_image(W, H)
    dr, dg, db = ImageDraw.Draw(R), ImageDraw.Draw(G), ImageDraw.Draw(B)
    for y in range(H):  # base gradient in R
        dr.line([(0, y), (W, y)], fill=int(40 + 110 * (1 - y / H)))
    if idx == 0:  # ORBIT: striped sun + rings
        cx, cy, r = 700, 250, 200
        db.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
        for k in range(8):
            y = cy + 20 + k * 24
            db.rectangle([cx - r, y, cx + r, y + 6 + k * 2], fill=0)
        for k in range(3):
            rr = r + 40 + k * 26
            dg.ellipse([cx - rr * 1.6, cy - rr * 0.35, cx + rr * 1.6, cy + rr * 0.35], outline=255, width=6)
        fit_stroke(dg, "ORBIT", 40, 330, 440, 140, 20)
    elif idx == 1:  # MIRA: diamond emblem + tagline bars
        cx, cy = 260, 256
        for k in range(5):
            s = 200 - k * 36
            (db if k % 2 == 0 else dr).polygon([(cx, cy - s), (cx + s, cy), (cx, cy + s), (cx - s, cy)], fill=255 if k % 2 == 0 else 20)
        f, b = fit_font("MIRA", 520, 220, stroke=6)
        dg.text((500 - b[0], 120 - b[1]), "MIRA", font=f, fill=255, stroke_width=6, stroke_fill=255)
        for k in range(3):
            db.rectangle([500, 380 + k * 30, 500 + 420 - k * 110, 392 + k * 30], fill=255)
    elif idx == 2:  # VOLT: drink can silhouette + bolt
        cx = 300
        db.rounded_rectangle([cx - 110, 70, cx + 110, 470], radius=40, fill=255)
        dr.rectangle([cx - 110, 200, cx + 110, 330], fill=255)
        w, strokes = GLYPHS["bolt"]
        for s in strokes:
            dg.polygon([(cx - 90 + px * 300, 120 + (1 - py) * 300) for px, py in s], fill=255)
        fit_stroke(dg, "VOLT", 470, 130, 520, 190, 26)
        for i in range(30):
            x = rng.randint(480, 1000); y = rng.randint(380, 490)
            db.ellipse([x - 5, y - 5, x + 5, y + 5], fill=255)
    elif idx == 3:  # ZENIT: wave field
        for k in range(14):
            pts = [(x, 300 + 40 * math.sin(x * 0.012 + k * 0.5) + k * 14) for x in range(0, W, 8)]
            (db if k % 2 else dg).line(pts, fill=255, width=6)
        f, b = fit_font("ZENIT", 760, 200, stroke=5)
        dg.text(((W - (b[2] - b[0])) / 2 - b[0], 40 - b[1]), "ZENIT", font=f, fill=255, stroke_width=5, stroke_fill=255)
    elif idx == 4:  # HALO: eye ring
        cx, cy = 512, 230
        for k in range(6):
            rr = 220 - k * 30
            (dg if k % 2 == 0 else db).ellipse([cx - rr, cy - rr * 0.7, cx + rr, cy + rr * 0.7], outline=255, width=12)
        dg.ellipse([cx - 50, cy - 50, cx + 50, cy + 50], fill=255)
        stroke_text(dg, "HALO", 330, 400, 90, 14)
    elif idx == 5:  # 24H: giant numerals + arrows
        fit_stroke(dg, "24H", 60, 80, 640, 340, 40)
        for k in range(4):
            x = 760 + k * 60
            db.line([(x, 120), (x + 50, 250), (x, 380)], fill=255, width=22)
    elif idx == 6:  # KITE: geometric bird/kite + grid
        for i in range(0, W, 48):
            dr.line([(i, 0), (i, H)], fill=200, width=2)
        for j in range(0, H, 48):
            dr.line([(0, j), (W, j)], fill=200, width=2)
        db.polygon([(250, 60), (420, 250), (250, 470), (80, 250)], fill=255)
        dg.line([(250, 60), (250, 470)], fill=255, width=10)
        dg.line([(80, 250), (420, 250)], fill=255, width=10)
        f, b = fit_font("KITE", 480, 230, stroke=6)
        dg.text((500 - b[0], 140 - b[1]), "KITE", font=f, fill=255, stroke_width=6, stroke_fill=255)
    else:  # NOVA: starburst
        cx, cy = 300, 256
        for k in range(24):
            a = k * math.pi / 12
            L = 230 if k % 2 == 0 else 140
            db.polygon([(cx, cy), (cx + L * math.cos(a - 0.08), cy + L * math.sin(a - 0.08)), (cx + L * math.cos(a + 0.08), cy + L * math.sin(a + 0.08))], fill=255)
        dg.ellipse([cx - 70, cy - 70, cx + 70, cy + 70], fill=255)
        fit_stroke(dg, "NOVA", 560, 170, 430, 160, 22)
    # soft glow in G so text blooms nicely in the texture too
    G2 = G.filter(ImageFilter.GaussianBlur(6))
    G = ImageChops.lighter(G, G2.point(lambda v: int(v * 0.5)))
    return merge([R, G, B])


def atlas(cells, cols, cw, ch):
    rows = (len(cells) + cols - 1) // cols
    im = Image.new("RGB", (cols * cw, rows * ch), (0, 0, 0))
    for i, c in enumerate(cells):
        im.paste(c, ((i % cols) * cw, (i // cols) * ch))
    return im


IMPORT = """[remap]

importer="texture"
type="CompressedTexture2D"

[params]

compress/mode=0
mipmaps/generate=true
detect_3d/compress_to=0
"""


def save(im, name):
    path = os.path.join(OUT, name)
    im.save(path)
    imp = path + ".import"
    if not os.path.exists(imp):
        with open(imp, "w") as f:
            f.write(IMPORT)
    print("TEX", name, im.size)


if __name__ == "__main__":
    save(atlas([sign_h(w, i % 5) for i, w in enumerate(WORDS_H)], 4, 512, 128), "signs_h.png")
    save(atlas([sign_v(w, i % 4) for i, w in enumerate(WORDS_V)], 8, 128, 512), "signs_v.png")
    chars = list("ABCDEHIKLMNOPRSTUVWXZ0123456789") + ["star", "bolt", "diamond", "ring", "cup", "bowl", "heart", "arrow",
                                                         "chevron", "wave", "eye"]
    chars = (chars * 2)[:64]
    save(atlas([glyph_cell(c, (i // 32)) for i, c in enumerate(chars)], 8, 128, 128), "glyph_cells.png")
    save(atlas([billboard(i) for i in range(8)], 2, 1024, 512), "billboards.png")
