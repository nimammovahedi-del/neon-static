# Large pieces: elevated rail girder + pillar, train car, pedestrian skybridge, megatowers.
# Rail / train / skybridge run along X. Towers: origin at base centre, metres, faces in all directions.
from kitlib import Piece, build_and_export, rot_z, tr
import math


def rail_girder():
    """24 m box-girder segment along X; deck top at z = 0, girder below, rails + walkway on top."""
    p = Piece("rail_girder", 601)
    L = 24.0
    prof = [(-3.2, 0.0), (3.2, 0.0), (3.2, -0.35), (2.4, -0.5), (1.9, -2.1), (-1.9, -2.1), (-2.4, -0.5), (-3.2, -0.35)]
    p.prism_x(prof, -L / 2, L / 2, "concrete", bev=0.05)
    # side ribs
    for i in range(13):
        x = -L / 2 + 0.5 + i * (L - 1) / 12
        for s in (-1, 1):
            p.prism_x([(s * 2.35, -0.5), (s * 2.5, -0.5), (s * 2.05, -2.05), (s * 1.9, -2.05)], x - 0.12, x + 0.12, "concrete_dark", bev=0.02)
    # underside LED strips + light bar
    for s in (-1, 1):
        p.box(-L / 2, s * 1.5 - 0.06, -2.14, L / 2, s * 1.5 + 0.06, -2.1, "led_strip")
        p.box(-L / 2, s * 3.18, -0.3, L / 2, s * 3.22, -0.22, "led_strip")
    # rails + sleepers
    for y in (-1.6, -0.6, 0.6, 1.6):
        p.box(-L / 2, y - 0.04, 0.1, L / 2, y + 0.04, 0.22, "metal_bare", bev=0.01)
    for i in range(40):
        x = -L / 2 + 0.3 + i * (L - 0.6) / 39
        p.box(x - 0.12, -2.1, 0.0, x + 0.12, 2.1, 0.1, "concrete_dark")
    # walkway railings and cable trays on both sides
    for s in (-1, 1):
        y = s * 3.1
        for i in range(25):
            x = -L / 2 + i * L / 24
            p.box(x - 0.03, y - 0.03, 0.0, x + 0.03, y + 0.03, 1.1, "metal_dark")
        p.box(-L / 2, y - 0.04, 1.06, L / 2, y + 0.04, 1.12, "metal_dark")
        p.box(-L / 2, y - 0.015, 0.55, L / 2, y + 0.015, 0.58, "metal_dark")
        p.box(-L / 2, s * 3.25, -0.7, L / 2, s * 3.45, -0.55, "metal_bare")
        p.tube([(-L / 2, s * 3.35, -0.5), (L / 2, s * 3.35, -0.5)], 0.06, "cable", segs=6, caps=False)
    # catenary masts
    for x in (-L / 2 + 2, L / 2 - 2):
        for s in (-1, 1):
            p.box(x - 0.1, s * 2.6 - 0.1, 0.0, x + 0.1, s * 2.6 + 0.1, 4.8, "metal_dark", bev=0.02)
        p.box(x - 0.08, -2.7, 4.6, x + 0.08, 2.7, 4.8, "metal_dark")
    for y in (-1.1, 1.1):
        p.tube([(-L / 2, y, 4.4), (L / 2, y, 4.4)], 0.015, "cable", segs=4, caps=False)
    # long sign band on the girder side (faces -Y)
    p.box(-8.0, -3.32, -1.9, 8.0, -3.2, -0.75, "sign_body", bev=0.02)
    p.quad([(-7.9, -3.33, -1.8), (7.9, -3.33, -1.8), (7.9, -3.33, -0.85), (-7.9, -3.33, -0.85)], "sign_face", uvk=1)
    return p


def rail_pillar():
    p = Piece("rail_pillar", 602)
    h = 12.0
    p.box(-1.0, -1.0, 0, 1.0, 1.0, 0.4, "concrete", bev=0.05)
    p.prism([(-0.75, -0.75), (0.75, -0.75), (0.75, 0.75), (-0.75, 0.75)], 0.4, h - 2.5, "concrete", bev=0.12)
    prof = [(-1.0, h - 2.5), (1.0, h - 2.5), (3.0, h - 0.6), (3.0, h), (-3.0, h), (-3.0, h - 0.6)]
    p.push(rot_z(90))
    p.prism_x(prof, -1.2, 1.2, "concrete", bev=0.06)
    p.pop()
    for s in (-1, 1):
        p.box(s * 0.76 - 0.02, -0.4, 1.0, s * 0.76 + 0.02, 0.4, h - 3.0, "concrete_dark")
    p.tube([(0.8, 0.0, 0.4), (0.8, 0.0, h - 2.6), (1.0, 0.0, h - 2.2)], 0.07, "plastic_dark", segs=8)
    p.box(-0.5, -0.82, 2.0, 0.5, -0.76, 3.6, "sign_face", uvk_front=1)
    p.box(-0.4, -0.85, 4.2, 0.4, -0.76, 4.5, "led_strip")
    return p


def train_car():
    """18 m rail car along X with a lit window band and roof equipment. Origin at rail top."""
    p = Piece("train_car", 603)
    L = 18.0
    prof = [(-1.45, 0.45), (1.45, 0.45), (1.55, 1.0), (1.55, 2.9), (1.25, 3.6), (-1.25, 3.6), (-1.55, 2.9), (-1.55, 1.0)]
    p.prism_x(prof, -L / 2 + 0.4, L / 2 - 0.4, "metal_panel", bev=0.08)
    # rounded ends
    for s in (-1, 1):
        p.prism_x([(-1.4, 0.55), (1.4, 0.55), (1.45, 2.85), (1.15, 3.5), (-1.15, 3.5), (-1.45, 2.85)], s * (L / 2 - 0.4), s * (L / 2 - 0.05), "metal_panel", bev=0.12)
    # window band both sides (lit interior)
    for s in (-1, 1):
        y = s * 1.56
        p.box(-L / 2 + 0.8, y - 0.005, 1.55, L / 2 - 0.8, y + 0.005, 2.6, "interior")
        for i in range(12):
            x = -L / 2 + 0.8 + i * (L - 1.6) / 12
            p.box(x - 0.06, y - 0.03 * s - 0.01, 1.5, x + 0.06, y + 0.03 * s + 0.01, 2.65, "metal_dark")
        p.box(-L / 2 + 0.8, y - 0.02, 1.47, L / 2 - 0.8, y + 0.02, 1.53, "metal_dark")
        p.box(-L / 2 + 0.8, y - 0.02, 2.62, L / 2 - 0.8, y + 0.02, 2.68, "metal_dark")
        p.box(-L / 2 + 0.5, y - 0.02, 3.0, L / 2 - 0.5, y + 0.02, 3.08, "led_strip")
        for x in (-5.0, 5.0):
            p.box(x - 0.7, y - 0.012, 0.6, x + 0.7, y + 0.012, 2.75, "plastic_dark")
    # cab windows at both ends
    for s in (-1, 1):
        x = s * (L / 2 - 0.04)
        p.box(x - 0.02, -1.0, 2.0, x + 0.02, 1.0, 2.9, "glass_car")
        p.box(x - 0.03, -1.1, 1.2, x + 0.03, -0.6, 1.4, "light_head" if s < 0 else "light_tail")
        p.box(x - 0.03, 0.6, 1.2, x + 0.03, 1.1, 1.4, "light_head" if s < 0 else "light_tail")
    # bogies + roof units
    for x in (-L / 2 + 3.0, L / 2 - 3.0):
        p.box(x - 1.4, -1.2, 0.0, x + 1.4, 1.2, 0.5, "metal_dark", bev=0.04)
        for xx in (x - 0.9, x + 0.9):
            for s in (-1, 1):
                p.cyl(xx, s * 0.75, 0.38, 0.38, 0.12, "metal_dark", axis='Y', segs=14)
    for x in (-5.0, 0.0, 5.0):
        p.box(x - 1.5, -0.9, 3.6, x + 1.5, 0.9, 4.0, "metal_bare", bev=0.05)
    p.tube([(-2.0, 0, 4.0), (-1.0, 0, 4.7), (0.5, 0, 4.7)], 0.03, "metal_dark", segs=4)
    return p


def skybridge():
    """Enclosed pedestrian bridge 20 m along X, glazed sides, LED edge strips."""
    p = Piece("skybridge", 604)
    L = 20.0
    p.box(-L / 2, -1.8, 0.0, L / 2, 1.8, 0.6, "metal_panel", bev=0.06, segs=2)
    p.box(-L / 2, -1.8, 3.4, L / 2, 1.8, 3.9, "metal_panel", bev=0.06, segs=2)
    for s in (-1, 1):
        y = s * 1.7
        p.box(-L / 2, y - 0.004, 0.6, L / 2, y + 0.004, 3.4, "glass_window" if False else "interior")
        q = [(-L / 2, y + 0.05 * s, 0.6), (L / 2, y + 0.05 * s, 0.6), (L / 2, y + 0.05 * s, 3.4), (-L / 2, y + 0.05 * s, 3.4)]
        if s > 0:
            q = list(reversed(q))
        p.quad(q, "glass_shop", uvk=1)
        for i in range(11):
            x = -L / 2 + i * L / 10
            p.box(x - 0.07, y - 0.08, 0.6, x + 0.07, y + 0.08, 3.4, "metal_dark")
        p.box(-L / 2, y - 0.1, 0.0, L / 2, y + 0.1, 0.06, "led_strip")
        p.box(-L / 2, y - 0.1, 3.84, L / 2, y + 0.1, 3.9, "led_strip")
    for i in range(5):
        x = -L / 2 + 2 + i * 4
        p.box(x - 0.8, -1.2, 3.35, x + 0.8, 1.2, 3.4, "shop_light")
    p.box(-L / 2, -1.8, -1.2, L / 2, -1.68, 0.0, "sign_body")
    p.quad([(-6.0, -1.81, -1.1), (6.0, -1.81, -1.1), (6.0, -1.81, -0.1), (-6.0, -1.81, -0.1)], "sign_face", uvk=1)
    return p


# -------------------------------------------------------------------- megatowers
def poly_chamfer(hx, hy, c):
    return [(-hx + c, -hy), (hx - c, -hy), (hx, -hy + c), (hx, hy - c), (hx - c, hy), (-hx + c, hy), (-hx, hy - c), (-hx, -hy + c)]


def led_corners(p, poly, z0, z1, w=0.25):
    for (x, y) in poly:
        p.box(x - w, y - w, z0, x + w, y + w, z1, "led_strip")


def tower_a():
    """Chamfered square tower with a setback, fins, crown and spire."""
    p = Piece("tower_a", 701)
    poly = poly_chamfer(18, 18, 4)
    p.prism(poly, 0, 150, "tower_glass", uvk=2)
    for z in range(30, 150, 30):
        p.prism(poly_chamfer(18.6, 18.6, 4.2), z - 0.8, z, "metal_panel")
        p.prism(poly_chamfer(18.65, 18.65, 4.25), z - 0.5, z - 0.3, "led_strip")
    led_corners(p, [((a[0] + b[0]) / 2, (a[1] + b[1]) / 2) for a, b in zip(poly[1::2], poly[2::2] + poly[:1])], 0, 150, 0.3)
    poly2 = poly_chamfer(14, 14, 3)
    p.prism(poly_chamfer(18.4, 18.4, 4.1), 150, 152, "metal_panel")
    p.prism(poly2, 152, 195, "tower_glass", uvk=2)
    for (x, y) in ((-14, -14), (14, -14), (14, 14), (-14, 14)):
        p.prism([(x - 1.0, y - 1.0), (x + 1.0, y - 1.0), (x + 1.0, y + 1.0), (x - 1.0, y + 1.0)], 150, 215, "metal_panel")
        p.box(x - 1.05, y - 1.05, 200, x + 1.05, y + 1.05, 214, "led_strip")
        p.cyl(x, y, 215, 0.6, 1.0, "blinker", segs=8)
    p.prism(poly_chamfer(14.5, 14.5, 3.2), 195, 198, "metal_panel")
    p.cyl(0, 0, 198, 3.0, 6.0, "metal_dark", segs=12)
    p.cyl(0, 0, 204, 0.8, 40, "metal_bare", segs=8, r2=0.2)
    p.cyl(0, 0, 244, 0.7, 1.2, "blinker", segs=8)
    p.cyl(0, 0, 225, 0.9, 0.8, "blinker", segs=8)
    return p


def tower_b():
    """Round-ish tower with banded rings and a crown ring."""
    p = Piece("tower_b", 702)
    n = 16
    poly = [(20 * math.cos(2 * math.pi * i / n), 20 * math.sin(2 * math.pi * i / n)) for i in range(n)]
    p.prism(poly, 0, 240, "tower_glass", uvk=2)
    for z in range(24, 240, 24):
        ring = [(21 * math.cos(2 * math.pi * i / n), 21 * math.sin(2 * math.pi * i / n)) for i in range(n)]
        p.prism(ring, z - 1.2, z, "metal_panel")
        ring2 = [(21.1 * math.cos(2 * math.pi * i / n), 21.1 * math.sin(2 * math.pi * i / n)) for i in range(n)]
        p.prism(ring2, z - 0.8, z - 0.5, "led_strip")
    ring = [(17 * math.cos(2 * math.pi * i / n), 17 * math.sin(2 * math.pi * i / n)) for i in range(n)]
    p.prism(ring, 240, 262, "tower_glass", uvk=2)
    crown = [(23 * math.cos(2 * math.pi * i / n), 23 * math.sin(2 * math.pi * i / n)) for i in range(n)]
    p.prism(crown, 262, 266, "metal_panel")
    crown2 = [(23.1 * math.cos(2 * math.pi * i / n), 23.1 * math.sin(2 * math.pi * i / n)) for i in range(n)]
    p.prism(crown2, 263, 264.5, "led_strip")
    for i in range(0, n, 2):
        a = 2 * math.pi * i / n
        p.box(20 * math.cos(a) - 0.4, 20 * math.sin(a) - 0.4, 0, 20 * math.cos(a) + 0.4, 20 * math.sin(a) + 0.4, 240, "metal_panel")
    p.cyl(0, 0, 266, 0.6, 30, "metal_bare", segs=8, r2=0.15)
    p.cyl(0, 0, 296, 0.6, 1.0, "blinker", segs=8)
    for a in (0, 120, 240):
        x, y = 12 * math.cos(math.radians(a)), 12 * math.sin(math.radians(a))
        p.cyl(x, y, 266, 0.3, 12, "metal_bare", segs=6)
        p.cyl(x, y, 278, 0.45, 0.7, "blinker", segs=8)
    return p


def tower_c():
    """Wide slab with an attached taller core tower and a crown billboard frame."""
    p = Piece("tower_c", 703)
    p.prism([(-32, -12), (32, -12), (32, 12), (-32, 12)], 0, 140, "tower_glass", uvk=2)
    for z in range(20, 140, 20):
        p.box(-32.6, -12.6, z - 0.7, 32.6, 12.6, z, "metal_panel")
    p.box(-6, -13, 0, 6, -12, 140, "metal_panel")
    p.box(-0.5, -13.1, 0, 0.5, -12.9, 140, "led_strip")
    p.prism([(20, -10), (42, -10), (42, 12), (20, 12)], 0, 190, "tower_glass", uvk=2)
    for (x, y) in ((20, -10), (42, -10), (42, 12), (20, 12)):
        p.box(x - 0.35, y - 0.35, 0, x + 0.35, y + 0.35, 190, "led_strip")
    p.box(19, -11, 190, 43, 13, 193, "metal_panel")
    p.box(-30, -6, 140, 10, 6, 146, "metal_panel")
    # crown billboard frame facing -Y
    p.box(-26, -4.5, 146, 6, -3.5, 166, "metal_dark")
    p.quad([(-25.5, -4.55, 146.5), (5.5, -4.55, 146.5), (5.5, -4.55, 165.5), (-25.5, -4.55, 165.5)], "screen", uvk=1)
    p.cyl(31, 1, 193, 0.5, 25, "metal_bare", segs=8, r2=0.15)
    p.cyl(31, 1, 218, 0.6, 1.0, "blinker", segs=8)
    for x in (-26, 6):
        p.cyl(x, -4, 166, 0.5, 0.8, "blinker", segs=8)
    return p


def tower_d():
    """Stepped tower (four tiers) with ledge lights and an antenna cluster."""
    p = Piece("tower_d", 704)
    tiers = [(25, 0, 55), (20, 55, 105), (15, 105, 150), (10, 150, 180)]
    for (h, z0, z1) in tiers:
        poly = poly_chamfer(h, h, 1.5)
        p.prism(poly, z0, z1, "tower_glass", uvk=2)
        p.prism(poly_chamfer(h + 0.8, h + 0.8, 1.8), z1, z1 + 1.2, "metal_panel")
        p.prism(poly_chamfer(h + 0.85, h + 0.85, 1.85), z1 + 0.3, z1 + 0.7, "led_strip")
        for (x, y) in ((-h, -h), (h, -h), (h, h), (-h, h)):
            p.cyl(x * 0.97, y * 0.97, z1 + 1.2, 0.35, 0.6, "blinker", segs=6)
    for (x, y, hh) in ((-4, -3, 30), (3, 4, 22), (5, -5, 16)):
        p.cyl(x, y, 181.2, 0.4, hh, "metal_bare", segs=6, r2=0.1)
        p.cyl(x, y, 181.2 + hh, 0.5, 0.8, "blinker", segs=8)
    return p


def build_all(only=None):
    for fn in (rail_girder, rail_pillar, train_car, skybridge, tower_a, tower_b, tower_c, tower_d):
        p = fn()
        if only and p.name not in only:
            continue
        build_and_export(p)
