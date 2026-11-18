# Facade modules (one storey bay, 4 m x 3.5 m), ground-floor shopfronts (4 m x 5 m), parapets
# and wall attachments (AC units, pipes, conduits, fire escapes, awnings).
# Front faces -Y in Blender (+Z in Godot). Wall plane y = 0, wall body back to y = T.
from kitlib import Piece, build_and_export, rot_z, tr
import math

W, H, G, T = 4.0, 3.5, 5.0, 0.45


# ---------------------------------------------------------------- shared helpers
def wall_around(p, x0, x1, z0, z1, ox0, ox1, oz0, oz1, mat, depth=T, bev=0.02, seam=0.012):
    """Wall slab with one rectangular opening, built from four bevelled blocks."""
    x0 += seam; x1 -= seam
    p.box(x0, 0, z0, ox0, depth, z1, mat, bev=bev)
    p.box(ox1, 0, z0, x1, depth, z1, mat, bev=bev)
    if oz0 > z0 + 0.01:
        p.box(ox0, 0, z0, ox1, depth, oz0, mat, bev=bev)
    if z1 > oz1 + 0.01:
        p.box(ox0, 0, oz1, ox1, depth, z1, mat, bev=bev)


def window(p, ox0, ox1, oz0, oz1, rev=0.22, frame=0.07, mullions=(), transoms=(), fmat="metal_dark",
           glass="glass_window", sill=True, sill_mat="concrete", lintel=None):
    """Glass + frame + mullions inside an opening. mullions/transoms are fractions 0..1."""
    gy = rev
    p.quad([(ox0, gy, oz0), (ox1, gy, oz0), (ox1, gy, oz1), (ox0, gy, oz1)], glass, uvk=1)
    f = frame
    d0, d1 = gy - 0.07, gy + 0.01
    p.box(ox0, d0, oz0, ox0 + f, d1, oz1, fmat, bev=0.01)
    p.box(ox1 - f, d0, oz0, ox1, d1, oz1, fmat, bev=0.01)
    p.box(ox0, d0, oz0, ox1, d1, oz0 + f, fmat, bev=0.01)
    p.box(ox0, d0, oz1 - f, ox1, d1, oz1, fmat, bev=0.01)
    for m in mullions:
        x = ox0 + (ox1 - ox0) * m
        p.box(x - 0.03, d0 + 0.01, oz0, x + 0.03, d1, oz1, fmat, bev=0.008)
    for t in transoms:
        z = oz0 + (oz1 - oz0) * t
        p.box(ox0, d0 + 0.01, z - 0.03, ox1, d1, z + 0.03, fmat, bev=0.008)
    if sill:
        p.box(ox0 - 0.1, -0.08, oz0 - 0.08, ox1 + 0.1, gy, oz0, sill_mat, bev=0.015)
    if lintel:
        p.box(ox0 - 0.12, -0.04, oz1, ox1 + 0.12, 0.05, oz1 + 0.22, lintel, bev=0.015)


def ledge(p, z, mat="concrete", out=0.14, h=0.22, x0=-W / 2, x1=W / 2):
    p.box(x0, -out, z, x1, 0.05, z + h, mat, bev=0.03, segs=1)


def ac_unit(p, x, z, w=0.82, h=0.58, d=0.34, rot=0.0, y=0.0):
    """AC unit hanging on the wall; (x, z) = bottom centre on the wall plane."""
    p.push(tr(x, y, z) @ rot_z(rot))
    p.box(-w / 2, -d - 0.04, 0, w / 2, -0.04, h, "metal_bare", bev=0.025)
    # fan grille: ring + spokes on the front face
    cx, cz, r = -w * 0.12, h / 2, h * 0.36
    ring = [(cx + r * math.cos(a * math.pi / 8), -d - 0.05, cz + r * math.sin(a * math.pi / 8)) for a in range(16)]
    p.tube(ring, 0.012, "metal_dark", segs=4, closed=True)
    ring2 = [(cx + r * 0.55 * math.cos(a * math.pi / 6), -d - 0.05, cz + r * 0.55 * math.sin(a * math.pi / 6)) for a in range(12)]
    p.tube(ring2, 0.01, "metal_dark", segs=4, closed=True)
    p.cyl(cx, -d - 0.045, cz, r * 0.95, 0.01, "grate", axis='Y', segs=16)
    p.box(cx - r, -d - 0.052, cz - 0.008, cx + r, -d - 0.04, cz + 0.008, "metal_dark")
    p.box(cx - 0.008, -d - 0.052, cz - r, cx + 0.008, -d - 0.04, cz + r, "metal_dark")
    # side louvres
    for i in range(5):
        zz = 0.1 + i * 0.09
        p.box(w * 0.18, -d - 0.055, zz, w * 0.45, -d - 0.04, zz + 0.035, "metal_dark")
    # brackets
    for bx in (-w / 2 + 0.08, w / 2 - 0.08):
        p.box(bx - 0.02, -d - 0.08, -0.05, bx + 0.02, 0.0, -0.01, "metal_dark")
        p.tube([(bx, -d - 0.06, -0.03), (bx, -0.01, -0.35)], 0.015, "metal_dark", segs=5)
    # drip pipe
    p.tube([(w / 2 - 0.1, -0.2, 0.02), (w / 2 - 0.1, -0.2, -0.25), (w / 2 - 0.1, -0.05, -0.4)], 0.012, "plastic_dark", segs=5)
    p.pop()


def railing(p, x0, x1, y, z, h=1.05, posts=0.9, mat="metal_dark", side=None):
    """Straight railing along X at depth y, base height z."""
    n = max(1, int(round((x1 - x0) / posts)))
    for i in range(n + 1):
        x = x0 + (x1 - x0) * i / n
        p.box(x - 0.025, y - 0.025, z, x + 0.025, y + 0.025, z + h, mat, bev=0.006)
    p.box(x0, y - 0.035, z + h - 0.04, x1, y + 0.035, z + h + 0.01, mat, bev=0.01)
    for k in (0.35, 0.65):
        p.box(x0, y - 0.012, z + h * k - 0.012, x1, y + 0.012, z + h * k + 0.012, mat)


def railing_y(p, y0, y1, x, z, h=1.05, posts=0.9, mat="metal_dark"):
    n = max(1, int(round(abs(y1 - y0) / posts)))
    for i in range(n + 1):
        y = y0 + (y1 - y0) * i / n
        p.box(x - 0.025, y - 0.025, z, x + 0.025, y + 0.025, z + h, mat, bev=0.006)
    p.box(x - 0.035, min(y0, y1), z + h - 0.04, x + 0.035, max(y0, y1), z + h + 0.01, mat, bev=0.01)
    for k in (0.35, 0.65):
        p.box(x - 0.012, min(y0, y1), z + h * k - 0.012, x + 0.012, max(y0, y1), z + h * k + 0.012, mat)


# ---------------------------------------------------------------- storey bays
def fac_concrete_a():
    p = Piece("fac_concrete_a", 11)
    ox0, ox1, oz0, oz1 = -1.35, 1.35, 0.95, 2.85
    wall_around(p, -W / 2, W / 2, 0, H, ox0, ox1, oz0, oz1, "concrete")
    window(p, ox0, ox1, oz0, oz1, mullions=(0.33, 0.66), transoms=(0.72,))
    ledge(p, 0.0)
    # recessed vertical panel joints either side of the window
    for x in (-1.72, 1.72):
        p.box(x - 0.015, -0.006, 0.25, x + 0.015, 0.02, H, "concrete_dark")
    return p


def fac_concrete_b():
    p = Piece("fac_concrete_b", 12)
    # two tall narrow windows
    s = 0.012
    p.box(-W / 2 + s, 0, 0, -1.25, T, H, "concrete", bev=0.02)
    p.box(-0.45, 0, 0, 0.45, T, H, "concrete", bev=0.02)
    p.box(1.25, 0, 0, W / 2 - s, T, H, "concrete", bev=0.02)
    for (a, b) in ((-1.25, -0.45), (0.45, 1.25)):
        p.box(a, 0, 0, b, T, 0.7, "concrete", bev=0.02)
        p.box(a, 0, 3.0, b, T, H, "concrete", bev=0.02)
        window(p, a, b, 0.7, 3.0, rev=0.2, transoms=(0.78,), sill=True)
    # vertical fins
    for x in (-1.6, 1.6):
        p.box(x - 0.06, -0.35, 0, x + 0.06, 0.02, H, "concrete", bev=0.025)
    ledge(p, 0.0, out=0.1, h=0.16)
    ac_unit(p, 0.85, 0.08, rot=0)
    # vent grille
    p.box(-1.05, -0.03, 0.25, -0.65, 0.0, 0.55, "metal_dark", bev=0.008)
    for i in range(5):
        p.box(-1.02, -0.05, 0.28 + i * 0.055, -0.68, -0.025, 0.3 + i * 0.055, "grate")
    return p


def fac_brick_a():
    p = Piece("fac_brick_a", 13)
    ox0, ox1, oz0, oz1 = -0.8, 0.8, 0.85, 2.85
    wall_around(p, -W / 2, W / 2, 0, H, ox0, ox1, oz0, oz1, "brick", bev=0.01, seam=0.0)
    window(p, ox0, ox1, oz0, oz1, rev=0.16, mullions=(0.5,), transoms=(0.5,), fmat="metal_dark",
           sill=True, sill_mat="concrete", lintel="concrete")
    # brick band course + quoins
    p.box(-W / 2, -0.04, 0.0, W / 2, 0.02, 0.18, "concrete", bev=0.012)
    # metal window grille cage on some (thin bars)
    for i in range(6):
        x = ox0 - 0.05 + (ox1 - ox0 + 0.1) * i / 5
        p.box(x - 0.012, -0.32, oz0 - 0.05, x + 0.012, -0.3, oz1 - 0.2, "metal_dark")
    for z in (oz0 - 0.05, (oz0 + oz1) / 2 - 0.1, oz1 - 0.2):
        p.box(ox0 - 0.06, -0.33, z - 0.015, ox1 + 0.06, -0.3, z + 0.015, "metal_dark")
    for x in (ox0 - 0.06, ox1 + 0.06):
        for z in (oz0 - 0.05, oz1 - 0.2):
            p.box(x - 0.015, -0.32, z - 0.015, x + 0.015, 0.0, z + 0.015, "metal_dark")
    p.box(ox0 - 0.06, -0.33, oz0 - 0.07, ox1 + 0.06, 0.0, oz0 - 0.04, "metal_dark")
    # small pot plant on the grille floor
    p.cyl(0.45, -0.18, oz0 - 0.04, 0.09, 0.16, "plastic_dark", segs=10, r2=0.11)
    return p


def fac_brick_b():
    p = Piece("fac_brick_b", 14)
    s = 0.0
    p.box(-W / 2, 0, 0, -1.45, T, H, "brick", bev=0.01)
    p.box(-0.35, 0, 0, 0.35, T, H, "brick", bev=0.01)
    p.box(1.45, 0, 0, W / 2, T, H, "brick", bev=0.01)
    for (a, b) in ((-1.45, -0.35), (0.35, 1.45)):
        p.box(a, 0, 0, b, T, 0.8, "brick", bev=0.01)
        p.box(a, 0, 2.75, b, T, H, "brick", bev=0.01)
        window(p, a, b, 0.8, 2.75, rev=0.15, mullions=(0.5,), transoms=(0.62,), sill=True,
               sill_mat="concrete", lintel="concrete")
    # pilasters at edges
    for x in (-W / 2, W / 2):
        p.box(x - 0.18, -0.08, 0, x + 0.18, 0.02, H, "brick", bev=0.015)
    p.box(-W / 2, -0.06, 0.0, W / 2, 0.02, 0.15, "concrete", bev=0.012)
    ac_unit(p, -0.9, 0.12, w=0.7, h=0.5, d=0.3)
    return p


def panel_wall(p, x0, x1, z0, z1, pw=1.0, ph=1.75, mat="metal_panel", gap=0.014):
    nx = max(1, int(round((x1 - x0) / pw)))
    nz = max(1, int(round((z1 - z0) / ph)))
    for i in range(nx):
        for j in range(nz):
            a = x0 + (x1 - x0) * i / nx; b = x0 + (x1 - x0) * (i + 1) / nx
            c = z0 + (z1 - z0) * j / nz; d = z0 + (z1 - z0) * (j + 1) / nz
            p.box(a + gap / 2, 0, c + gap / 2, b - gap / 2, 0.08, d - gap / 2, mat, bev=0.012)
    p.box(x0, 0.05, z0, x1, T, z1, "metal_dark")


def fac_panel_a():
    p = Piece("fac_panel_a", 15)
    oz0, oz1 = 1.05, 2.35
    panel_wall(p, -W / 2 + 0.01, W / 2 - 0.01, 0, oz0, pw=1.0, ph=1.05)
    panel_wall(p, -W / 2 + 0.01, W / 2 - 0.01, oz1, H, pw=1.0, ph=1.15)
    # ribbon window
    p.box(-W / 2, 0.05, oz0, W / 2, 0.4, oz0 + 0.01, "metal_dark")
    window(p, -W / 2 + 0.01, W / 2 - 0.01, oz0, oz1, rev=0.12, frame=0.06,
           mullions=(0.25, 0.5, 0.75), sill=False)
    p.box(-W / 2, -0.1, oz0 - 0.06, W / 2, 0.08, oz0, "metal_dark", bev=0.01)
    p.box(-W / 2, -0.06, oz1, W / 2, 0.08, oz1 + 0.05, "metal_dark", bev=0.01)
    # cable tray + conduits along the top
    zt = 3.1
    p.box(-W / 2, -0.32, zt, W / 2, -0.3, zt + 0.12, "metal_bare")
    p.box(-W / 2, -0.32, zt, W / 2, -0.12, zt + 0.012, "metal_bare")
    for k, r in enumerate((0.035, 0.025, 0.03)):
        y = -0.27 + k * 0.06
        p.tube([(-W / 2, y, zt + 0.05 + r), (W / 2, y, zt + 0.05 + r)], r, "plastic_dark" if k else "metal_bare", segs=6, caps=False)
    for x in (-1.5, 0.5):
        p.box(x - 0.02, -0.32, zt - 0.04, x + 0.02, 0.0, zt, "metal_dark")
    return p


def fac_balcony_a():
    p = Piece("fac_balcony_a", 16)
    ox0, ox1, oz0, oz1 = -1.3, 1.3, 0.2, 2.7
    wall_around(p, -W / 2, W / 2, 0, H, ox0, ox1, oz0, oz1, "concrete")
    window(p, ox0, ox1, oz0, oz1, rev=0.25, mullions=(0.5,), transoms=(0.85,), sill=False)
    # balcony slab (drip edge), railing, divider walls
    p.box(-1.85, -1.15, -0.02, 1.85, 0.05, 0.2, "concrete", bev=0.035, segs=2)
    p.box(-1.85, -1.17, -0.06, 1.85, -1.08, 0.2, "concrete_dark", bev=0.01)
    railing(p, -1.8, 1.8, -1.08, 0.2, h=1.0, posts=0.6)
    railing_y(p, -1.08, 0.0, -1.8, 0.2, h=1.0, posts=0.5)
    railing_y(p, -1.08, 0.0, 1.8, 0.2, h=1.0, posts=0.5)
    # frosted lower panels on the railing
    p.box(-1.78, -1.1, 0.25, 1.78, -1.07, 0.75, "glass_shop")
    # clutter: crates, pot, small ac
    p.box(1.1, -0.9, 0.2, 1.55, -0.45, 0.55, "plastic_dark", bev=0.02)
    p.box(1.15, -0.85, 0.55, 1.5, -0.5, 0.8, "wood", bev=0.015)
    p.cyl(-1.45, -0.75, 0.2, 0.16, 0.35, "plastic_dark", segs=10, r2=0.2)
    p.cyl(-1.45, -0.75, 0.55, 0.22, 0.25, "fabric", segs=7, r2=0.05)
    # laundry line
    p.tube([(-1.75, -0.95, 2.1), (1.75, -0.95, 2.05)], 0.006, "cable", segs=4, caps=False)
    for i, x in enumerate((-1.2, -0.6, 0.1, 0.8)):
        p.box(x, -0.96, 1.55 + (i % 2) * 0.15, x + 0.45, -0.94, 2.07, "fabric", bev=0.0)
    return p


def fac_tile_a():
    """Tiled tenement bay with a projecting glazed bay window and a security cage."""
    p = Piece("fac_tile_a", 17)
    ox0, ox1, oz0, oz1 = -1.4, 1.4, 0.75, 2.75
    wall_around(p, -W / 2, W / 2, 0, H, ox0, ox1, oz0, oz1, "tile", bev=0.012, seam=0.0)
    # bay box
    d = 0.6
    p.box(ox0 - 0.1, -d - 0.05, oz0 - 0.22, ox1 + 0.1, 0.05, oz0, "concrete", bev=0.03)
    p.box(ox0 - 0.1, -d - 0.05, oz1, ox1 + 0.1, 0.05, oz1 + 0.18, "concrete", bev=0.03)
    p.quad([(ox0, -d, oz0), (ox1, -d, oz0), (ox1, -d, oz1), (ox0, -d, oz1)], "glass_window", uvk=1)
    p.quad([(ox0, 0.0, oz0), (ox0, -d, oz0), (ox0, -d, oz1), (ox0, 0.0, oz1)], "glass_window", uvk=1)
    p.quad([(ox1, -d, oz0), (ox1, 0.0, oz0), (ox1, 0.0, oz1), (ox1, -d, oz1)], "glass_window", uvk=1)
    for x in (ox0, ox0 + (ox1 - ox0) / 3, ox0 + 2 * (ox1 - ox0) / 3, ox1):
        p.box(x - 0.035, -d - 0.035, oz0, x + 0.035, -d + 0.035, oz1, "metal_bare", bev=0.008)
    for y in (0.0, -d / 2):
        for x in (ox0, ox1):
            p.box(x - 0.035, y - 0.035, oz0, x + 0.035, y + 0.035, oz1, "metal_bare", bev=0.008)
    p.box(ox0, -d - 0.03, (oz0 + oz1) / 2 + 0.25, ox1, -d + 0.03, (oz0 + oz1) / 2 + 0.3, "metal_bare")
    # cage bars in front
    cy = -d - 0.22
    for i in range(10):
        x = ox0 - 0.15 + (ox1 - ox0 + 0.3) * i / 9
        p.box(x - 0.01, cy - 0.01, oz0 - 0.2, x + 0.01, cy + 0.01, oz1 + 0.15, "metal_rust")
    for z in (oz0 - 0.2, oz0 + 0.6, oz0 + 1.3, oz1 + 0.15):
        p.box(ox0 - 0.16, cy - 0.015, z - 0.015, ox1 + 0.16, cy + 0.015, z + 0.015, "metal_rust")
    p.box(ox0 - 0.16, cy, oz0 - 0.21, ox1 + 0.16, -d - 0.05, oz0 - 0.18, "metal_rust")
    p.box(ox0 - 0.16, cy, oz1 + 0.14, ox1 + 0.16, -d - 0.05, oz1 + 0.17, "metal_rust")
    # stuff stored in the cage
    p.box(ox1 - 0.55, cy + 0.03, oz0 - 0.18, ox1 - 0.1, -d - 0.06, oz0 + 0.2, "plastic_dark", bev=0.02)
    p.cyl(ox0 + 0.3, cy + 0.12, oz0 - 0.18, 0.08, 0.3, "fabric", segs=8)
    ledge(p, 0.0, mat="concrete", out=0.08, h=0.12)
    ac_unit(p, 1.45, 0.2, w=0.62, h=0.45, d=0.28)
    return p


def fac_glass_a():
    """Curtain wall bay for corporate buildings."""
    p = Piece("fac_glass_a", 18)
    p.box(-W / 2, 0.0, 0.0, W / 2, 0.3, 0.75, "metal_panel", bev=0.01)
    p.quad([(-W / 2, 0.05, 0.75), (W / 2, 0.05, 0.75), (W / 2, 0.05, H), (-W / 2, 0.05, H)], "glass_window", uvk=1)
    p.box(-W / 2, 0.06, 0.0, W / 2, 0.4, H, "metal_dark")
    for i in range(4):
        x = -W / 2 + i * (W / 3)
        p.box(x - 0.04, -0.14, 0, x + 0.04, 0.06, H, "metal_bare", bev=0.012)
    p.box(-W / 2, -0.08, 0.7, W / 2, 0.06, 0.78, "metal_bare", bev=0.01)
    p.box(-W / 2, -0.05, H - 0.04, W / 2, 0.06, H, "metal_bare", bev=0.01)
    return p


def fac_blank_a():
    """Blank service wall bay: vents, a pipe run, small window."""
    p = Piece("fac_blank_a", 19)
    ox0, ox1, oz0, oz1 = 0.6, 1.3, 1.6, 2.5
    wall_around(p, -W / 2, W / 2, 0, H, ox0, ox1, oz0, oz1, "concrete")
    window(p, ox0, ox1, oz0, oz1, rev=0.18, sill=True)
    ledge(p, 0.0, out=0.06, h=0.1)
    for i in range(3):
        p.box(-1.3 + i * 0.5, -0.06, 2.4, -0.95 + i * 0.5, 0.0, 2.75, "metal_bare", bev=0.01)
        for k in range(4):
            p.box(-1.28 + i * 0.5, -0.08, 2.44 + k * 0.075, -0.97 + i * 0.5, -0.05, 2.47 + k * 0.075, "grate")
    p.box(-1.6, -0.15, 0.6, -1.0, 0.0, 1.4, "metal_panel", bev=0.02)
    p.box(-1.56, -0.17, 1.2, -1.04, -0.14, 1.32, "plastic_dark")
    return p


# ---------------------------------------------------------------- ground floor
def shop_interior(p, x0, x1, z0, z1, depth=3.2, seed=0):
    """Lit shop box behind a shopfront: floor, walls, ceiling lights, shelves with goods."""
    y0 = 0.35
    p.box(x0, y0, z0 - 0.05, x1, depth, z0, "interior_dark")  # floor
    p.box(x0, depth, z0, x1, depth + 0.05, z1, "interior")   # back wall
    p.box(x0 - 0.05, y0, z0, x0, depth, z1, "interior_dark")  # side walls
    p.box(x1, y0, z0, x1 + 0.05, depth, z1, "interior_dark")
    p.box(x0, y0, z1, x1, depth, z1 + 0.05, "interior_dark")  # ceiling
    for k in range(3):
        y = y0 + 0.5 + k * 0.9
        p.box(x0 + 0.3, y, z1 - 0.06, x1 - 0.3, y + 0.18, z1 - 0.01, "shop_light")
    # back shelves with goods
    for lev in range(4):
        z = z0 + 0.45 + lev * 0.55
        p.box(x0 + 0.1, depth - 0.45, z, x1 - 0.1, depth, z + 0.04, "metal_bare")
        x = x0 + 0.15
        while x < x1 - 0.3:
            w = 0.12 + p.rng.random() * 0.22
            h = 0.15 + p.rng.random() * 0.3
            p.box(x, depth - 0.4, z + 0.04, x + w, depth - 0.1, z + 0.04 + h, "goods", bev=0.01)
            x += w + 0.03
    # shelving units along both side walls
    for sx, inward in ((x0 + 0.05, 1), (x1 - 0.05, -1)):
        xa, xb = (sx, sx + 0.4 * inward) if inward > 0 else (sx + 0.4 * inward, sx)
        p.box(xa, y0 + 0.4, z0, xb, depth - 0.6, z0 + 2.3, "metal_dark", bev=0.01)
        for lev in range(5):
            z = z0 + 0.3 + lev * 0.45
            y = y0 + 0.5
            while y < depth - 0.8:
                d = 0.1 + p.rng.random() * 0.2
                hh = 0.12 + p.rng.random() * 0.22
                xi0, xi1 = (xa + 0.02, xb - 0.12) if inward < 0 else (xa + 0.12, xb - 0.02)
                p.box(xi0, y, z, xi1, y + d, z + hh, "goods", bev=0.008)
                y += d + 0.02
    # island shelf + counter
    p.box(x0 + 0.5, 1.3, z0, x0 + 1.6, 1.9, z0 + 1.2, "metal_bare", bev=0.02)
    for lev in range(2):
        x = x0 + 0.55
        while x < x0 + 1.5:
            w = 0.1 + p.rng.random() * 0.15
            p.box(x, 1.32, z0 + 0.6 + lev * 0.6, x + w, 1.6, z0 + 0.85 + lev * 0.6, "goods", bev=0.01)
            x += w + 0.03
    p.box(x1 - 1.3, 0.9, z0, x1 - 0.2, 1.5, z0 + 1.05, "plastic_dark", bev=0.03)
    p.box(x1 - 1.35, 0.85, z0 + 1.05, x1 - 0.15, 1.55, z0 + 1.1, "metal_bare", bev=0.01)
    p.box(x1 - 1.0, 1.1, z0 + 1.1, x1 - 0.6, 1.3, z0 + 1.4, "screen", uvk_front=1)


def shopfront_frame(p, fascia=True):
    """Pilasters + fascia band that every ground-floor module shares."""
    for x0, x1 in ((-W / 2, -W / 2 + 0.25), (W / 2 - 0.25, W / 2)):
        p.box(x0, -0.05, 0.0, x1, T, G, "concrete", bev=0.025)
    p.box(-W / 2, -0.06, 3.55, W / 2, T, 3.75, "concrete_dark", bev=0.02)
    if fascia:
        p.box(-W / 2 + 0.25, -0.02, 3.75, W / 2 - 0.25, T, G - 0.1, "sign_body", bev=0.015)
        p.quad([(-W / 2 + 0.35, -0.03, 3.85), (W / 2 - 0.35, -0.03, 3.85), (W / 2 - 0.35, -0.03, G - 0.2), (-W / 2 + 0.35, -0.03, G - 0.2)],
               "sign_face", uvk=1)
    else:
        p.box(-W / 2 + 0.25, 0.0, 3.75, W / 2 - 0.25, T, G, "concrete", bev=0.02)
    p.box(-W / 2, -0.12, G - 0.12, W / 2, T, G, "concrete", bev=0.03)
    # kerb-level plinth
    p.box(-W / 2 + 0.25, 0.0, 0.0, W / 2 - 0.25, 0.4, 0.12, "concrete_dark", bev=0.01)


def shop_window_a():
    p = Piece("shop_window_a", 21)
    shopfront_frame(p)
    x0, x1, z0, z1 = -W / 2 + 0.25, W / 2 - 0.25, 0.12, 3.55
    shop_interior(p, x0, x1, z0, z1, depth=3.4)
    gy = 0.3
    # glass + frames + door
    xd = 0.55
    p.quad([(x0, gy, z0 + 0.35), (xd, gy, z0 + 0.35), (xd, gy, z1), (x0, gy, z1)], "glass_shop", uvk=1)
    p.box(x0, gy - 0.02, z0, xd, gy + 0.08, z0 + 0.35, "metal_dark", bev=0.01)
    p.quad([(xd, gy + 0.02, z0 + 2.4), (x1, gy + 0.02, z0 + 2.4), (x1, gy + 0.02, z1), (xd, gy + 0.02, z1)], "glass_shop", uvk=1)
    p.quad([(xd + 0.08, gy + 0.05, z0), (x1 - 0.08, gy + 0.05, z0), (x1 - 0.08, gy + 0.05, z0 + 2.32), (xd + 0.08, gy + 0.05, z0 + 2.32)], "glass_shop", uvk=1)
    for (a, b, c, d) in ((x0, x0 + 0.06, z0, z1), (xd - 0.04, xd + 0.08, z0, z1), (x1 - 0.08, x1, z0, z1),
                          (x0, x1, z1 - 0.06, z1), (xd, x1, z0 + 2.32, z0 + 2.42)):
        p.box(a, gy - 0.04, c, b, gy + 0.06, d, "metal_dark", bev=0.01)
    p.box(x1 - 0.3, gy - 0.07, z0 + 0.9, x1 - 0.25, gy - 0.01, z0 + 1.5, "chrome")
    # posters / menu panels in the window (lit)
    p.box(x0 + 0.15, gy + 0.05, z0 + 1.6, x0 + 0.85, gy + 0.08, z0 + 2.6, "sign_face", uvk_front=1)
    return p


def shutter_curtain(p, x0, x1, z0, z1, y):
    """Corrugated roller shutter from z0 up to z1 at depth y."""
    n = int((z1 - z0) / 0.09)
    for i in range(n):
        z = z0 + i * (z1 - z0) / n
        p.box(x0, y - 0.035, z + 0.005, x1, y, z + (z1 - z0) / n - 0.005, "metal_bare", bev=0.012)
    p.box(x0, y - 0.06, z0, x1, y + 0.01, z0 + 0.06, "metal_dark", bev=0.01)  # bottom bar
    p.box(x0 + 0.4, y - 0.08, z0 + 0.02, x0 + 0.55, y - 0.05, z0 + 0.05, "metal_dark")
    p.box(x1 - 0.55, y - 0.08, z0 + 0.02, x1 - 0.4, y - 0.05, z0 + 0.05, "metal_dark")


def shop_shutter(name, frac_open, seed):
    p = Piece(name, seed)
    shopfront_frame(p)
    x0, x1, z0, z1 = -W / 2 + 0.25, W / 2 - 0.25, 0.12, 3.55
    if frac_open > 0:
        shop_interior(p, x0, x1, z0, z1, depth=3.2)
        p.quad([(x0, 0.32, z0), (x1, 0.32, z0), (x1, 0.32, z1), (x0, 0.32, z1)], "glass_shop", uvk=1)
    else:
        p.box(x0, 0.4, z0, x1, 0.45, z1, "metal_dark")
    zb = z0 + (z1 - z0 - 0.4) * frac_open
    shutter_curtain(p, x0 + 0.04, x1 - 0.04, zb, z1 - 0.38, 0.1)
    # shutter housing box + side guides
    p.box(x0, -0.12, z1 - 0.4, x1, 0.15, z1, "metal_panel", bev=0.025)
    for x in (x0 + 0.02, x1 - 0.06):
        p.box(x, 0.0, z0, x + 0.04, 0.14, z1 - 0.4, "metal_dark")
    # padlock housing
    if frac_open == 0:
        p.box(-0.12, -0.05, z0 + 0.03, 0.12, 0.08, z0 + 0.22, "metal_dark", bev=0.01)
    return p


def shop_food_a():
    """Open-fronted noodle counter with stools, hanging lamps and menu panels."""
    p = Piece("shop_food_a", 24)
    shopfront_frame(p)
    x0, x1, z0, z1 = -W / 2 + 0.25, W / 2 - 0.25, 0.12, 3.55
    depth = 3.0
    p.box(x0, 0.3, z0 - 0.05, x1, depth, z0, "interior_dark")
    p.box(x0, depth, z0, x1, depth + 0.05, z1, "interior")
    p.box(x0 - 0.05, 0.3, z0, x0, depth, z1, "interior")
    p.box(x1, 0.3, z0, x1 + 0.05, depth, z1, "interior")
    p.box(x0, 0.3, z1, x1, depth, z1 + 0.05, "wood")
    # kitchen back counter with pots
    p.box(x0 + 0.1, depth - 0.7, z0, x1 - 0.1, depth, z0 + 0.95, "metal_bare", bev=0.02)
    for i in range(4):
        p.cyl(x0 + 0.5 + i * 0.75, depth - 0.35, z0 + 0.95, 0.17 + 0.03 * (i % 2), 0.3, "metal_bare", segs=12)
    p.box(x0 + 0.1, depth - 0.35, z0 + 1.6, x1 - 0.1, depth, z0 + 1.65, "metal_bare")
    for i in range(7):
        p.box(x0 + 0.2 + i * 0.47, depth - 0.3, z0 + 1.65, x0 + 0.5 + i * 0.47, depth - 0.05, z0 + 1.85, "goods")
    # menu panels (lit)
    for i in range(3):
        a = x0 + 0.25 + i * 1.12
        p.box(a, depth - 0.06, z0 + 2.15, a + 0.95, depth, z0 + 2.95, "sign_face", uvk_front=1)
    # street-facing counter
    p.box(x0, -0.35, z0, x1, 0.3, z0 + 1.0, "wood", bev=0.02)
    p.box(x0 - 0.05, -0.55, z0 + 1.0, x1 + 0.05, 0.35, z0 + 1.07, "wood", bev=0.02)
    p.box(x0, -0.36, z0 + 0.1, x1, -0.34, z0 + 0.9, "interior_dark")
    # stools
    for i in range(4):
        x = x0 + 0.45 + i * 0.85
        p.cyl(x, -0.95, 0.0, 0.03, 0.68, "metal_bare", segs=6)
        p.cyl(x, -0.95, 0.68, 0.17, 0.07, "fabric", segs=12, bev=0.015)
        p.cyl(x, -0.95, 0.0, 0.16, 0.03, "metal_dark", segs=10)
    # hanging lamps
    for i in range(3):
        x = x0 + 0.7 + i * 1.2
        p.tube([(x, -0.1, z1), (x, -0.1, z1 - 0.7)], 0.006, "cable", segs=4, caps=False)
        p.cyl(x, -0.1, z1 - 0.95, 0.16, 0.25, "lantern", segs=10, r2=0.12, bev=0.02)
    # noren-style cloth strips under the fascia
    for i in range(5):
        a = x0 + 0.05 + i * 0.7
        p.box(a, -0.06, z1 - 0.75, a + 0.66, -0.05, z1 - 0.02, "fabric")
    return p


def entry_a():
    p = Piece("entry_a", 25)
    shopfront_frame(p, fascia=False)
    x0, x1, z0, z1 = -W / 2 + 0.25, W / 2 - 0.25, 0.12, 3.55
    rec = 1.4
    p.box(x0, 0.0, z0 + 2.9, x1, rec, z1, "concrete", bev=0.02)
    p.box(x0, 0.0, z0, -0.95, rec, z0 + 2.9, "concrete", bev=0.02)
    p.box(0.95, 0.0, z0, x1, rec, z0 + 2.9, "concrete", bev=0.02)
    p.box(-0.95, 0.0, z0 - 0.04, 0.95, rec, z0, "paving")
    gy = rec
    p.quad([(-0.95, gy, z0), (0.95, gy, z0), (0.95, gy, z0 + 2.9), (-0.95, gy, z0 + 2.9)], "glass_shop", uvk=1)
    p.box(-0.95, gy - 0.04, z0, 0.95, gy + 0.5, z0 + 0.02, "interior_dark")
    p.box(-0.95, gy + 2.0, z0, 0.95, gy + 2.05, z0 + 2.9, "interior")
    p.box(-0.95, gy, z0 + 2.9, 0.95, gy + 2.0, z0 + 2.95, "interior")
    p.box(-0.5, gy + 0.6, z0 + 2.85, 0.5, gy + 1.6, z0 + 2.9, "shop_light")
    for (a, b, c, d) in ((-0.95, -0.89, z0, z0 + 2.9), (0.89, 0.95, z0, z0 + 2.9), (-0.03, 0.03, z0, z0 + 2.4),
                          (-0.95, 0.95, z0 + 2.38, z0 + 2.45)):
        p.box(a, gy - 0.05, c, b, gy + 0.04, d, "metal_dark", bev=0.01)
    p.box(-0.5, 0.15, z0 + 2.85, 0.5, 0.9, z0 + 2.9, "shop_light")
    # canopy
    p.box(-1.5, -1.1, z1 - 0.05, 1.5, 0.05, z1 + 0.12, "metal_dark", bev=0.02)
    p.box(-1.45, -1.08, z1 - 0.07, 1.45, -1.02, z1 - 0.04, "led_strip")
    p.box(1.2, -0.08, 1.2, 1.5, 0.0, 1.65, "metal_bare", bev=0.01)  # intercom
    p.box(1.25, -0.1, 1.45, 1.45, -0.07, 1.6, "screen", uvk_front=1)
    # steps
    p.box(-1.1, -0.35, 0.0, 1.1, 0.0, 0.12, "concrete", bev=0.01)
    return p


def wall_service_a():
    p = Piece("wall_service_a", 26)
    shopfront_frame(p, fascia=False)
    x0, x1, z0, z1 = -W / 2 + 0.25, W / 2 - 0.25, 0.12, 3.55
    p.box(x0, 0.05, z0, x1, T, z1, "concrete", bev=0.02)
    # electrical cabinets
    p.box(-1.55, -0.3, z0, -0.75, 0.05, z0 + 1.7, "metal_panel", bev=0.03)
    p.box(-1.5, -0.32, z0 + 0.1, -1.17, -0.29, z0 + 1.6, "metal_panel", bev=0.01)
    p.box(-1.13, -0.32, z0 + 0.1, -0.8, -0.29, z0 + 1.6, "metal_panel", bev=0.01)
    p.box(-1.2, -0.34, z0 + 0.8, -1.16, -0.3, z0 + 0.95, "metal_dark")
    # meters
    for i in range(3):
        p.box(-0.5 + i * 0.35, -0.16, 1.5, -0.22 + i * 0.35, 0.05, 1.9, "plastic_dark", bev=0.015)
        p.cyl(-0.36 + i * 0.35, -0.16, 1.75, 0.08, 0.02, "glass_shop", axis='Y', segs=10)
    # service door
    p.box(0.45, -0.03, z0, 1.6, 0.06, z0 + 2.3, "metal_panel", bev=0.02)
    p.box(0.47, -0.05, z0 + 1.6, 1.58, -0.02, z0 + 2.1, "grate")
    p.box(1.4, -0.08, z0 + 1.0, 1.48, -0.03, z0 + 1.1, "chrome")
    p.box(0.4, -0.08, z0 + 2.35, 1.65, 0.05, z0 + 2.45, "metal_dark")
    p.box(0.85, -0.2, z0 + 2.5, 1.2, 0.0, z0 + 2.65, "metal_dark", bev=0.01)
    p.box(0.88, -0.21, z0 + 2.52, 1.17, -0.19, z0 + 2.56, "lamp_lens")
    # pipes up the wall
    p.tube([(-0.2, -0.12, 0.0), (-0.2, -0.12, 2.9), (-0.2, 0.2, 3.3)], 0.06, "metal_rust", segs=8)
    p.tube([(0.1, -0.1, 0.0), (0.1, -0.1, 3.5)], 0.04, "plastic_dark", segs=8)
    return p


# ---------------------------------------------------------------- parapets and attachments
def cornice_a():
    p = Piece("cornice_a", 31)
    p.box(-W / 2, -0.05, 0.0, W / 2, T, 1.1, "concrete", bev=0.02)
    p.box(-W / 2, -0.18, 0.0, W / 2, 0.05, 0.12, "concrete", bev=0.025)
    p.box(-W / 2, -0.28, 0.12, W / 2, 0.05, 0.3, "concrete", bev=0.04, segs=2)
    p.box(-W / 2, -0.12, 1.1, W / 2, T + 0.08, 1.22, "concrete_dark", bev=0.025)
    for i in range(8):
        x = -W / 2 + 0.25 + i * 0.5
        p.box(x - 0.08, -0.32, 0.3, x + 0.08, -0.05, 0.42, "concrete", bev=0.015)
    return p


def cornice_b():
    p = Piece("cornice_b", 32)
    p.box(-W / 2, 0.0, 0.0, W / 2, T, 0.55, "metal_panel", bev=0.015)
    p.box(-W / 2, -0.1, 0.5, W / 2, T + 0.05, 0.6, "metal_dark", bev=0.02)
    railing(p, -W / 2, W / 2, 0.1, 0.6, h=1.0, posts=1.0, mat="metal_bare")
    p.box(-W / 2, -0.04, 0.12, W / 2, 0.0, 0.16, "led_strip")
    return p


def ac_unit_piece():
    p = Piece("ac_unit_a", 41)
    ac_unit(p, 0, 0)
    return p


def ac_unit_pair():
    p = Piece("ac_unit_b", 42)
    ac_unit(p, -0.48, 0, w=0.8, h=0.55)
    ac_unit(p, 0.48, 0.65, w=0.8, h=0.55)
    p.tube([(-0.2, -0.15, 0.58), (-0.2, -0.15, 1.6)], 0.018, "cable", segs=5, caps=False)
    return p


def pipe_v():
    p = Piece("pipe_v", 43)
    p.cyl(0, -0.16, 0, 0.075, H, "metal_rust", segs=10, caps=False)
    for z in (0.3, H - 0.4):
        p.cyl(0, -0.16, z, 0.095, 0.08, "metal_dark", segs=10)
        p.box(-0.03, -0.16, z + 0.01, 0.03, 0.0, z + 0.07, "metal_dark")
    p.cyl(0, -0.16, 1.7, 0.085, 0.05, "metal_dark", segs=10)
    return p


def pipe_cluster():
    p = Piece("pipe_cluster", 44)
    specs = [(-0.25, 0.06, "metal_rust"), (0.0, 0.1, "metal_bare"), (0.22, 0.045, "plastic_dark"), (0.36, 0.03, "metal_dark")]
    for x, r, m in specs:
        p.cyl(x, -0.08 - r, 0, r, H, m, segs=10, caps=False)
    for z in (0.4, 2.2):
        p.box(-0.35, -0.3, z, 0.42, -0.02, z + 0.05, "metal_dark", bev=0.008)
        for x, r, m in specs:
            p.cyl(x, -0.08 - r, z - 0.01, r + 0.015, 0.07, "metal_dark", segs=10)
    # a valve wheel
    p.cyl(0.0, -0.32, 1.3, 0.04, 0.12, "metal_dark", axis='Y', segs=8)
    ring = [(0.16 * math.cos(a * math.pi / 6), -0.33, 1.3 + 0.16 * math.sin(a * math.pi / 6)) for a in range(12)]
    p.tube(ring, 0.015, "paint_yellow", segs=5, closed=True)
    return p


def conduit_h():
    p = Piece("conduit_h", 45)
    zt = 0.0
    p.box(-W / 2, -0.4, zt, W / 2, -0.38, zt + 0.15, "metal_bare")
    p.box(-W / 2, -0.4, zt, W / 2, -0.06, zt + 0.015, "metal_bare")
    for k in range(5):
        y = -0.34 + k * 0.06
        r = 0.022 + 0.01 * ((k * 7) % 3)
        p.tube([(-W / 2, y, zt + 0.02 + r), (W / 2, y, zt + 0.02 + r)], r, "cable" if k % 2 else "plastic_dark", segs=6, caps=False)
    for x in (-1.6, 0.4):
        p.box(x - 0.02, -0.42, zt - 0.05, x + 0.02, 0.0, zt, "metal_dark")
        p.tube([(x, -0.38, zt - 0.03), (x, -0.01, zt - 0.3)], 0.012, "metal_dark", segs=4)
    # a junction box with a drooping cable
    p.box(0.9, -0.2, -0.45, 1.3, 0.0, -0.05, "metal_panel", bev=0.015)
    p.tube([(1.1, -0.15, -0.45), (1.15, -0.2, -0.9), (1.4, -0.22, -1.1), (1.8, -0.25, -0.6), (1.95, -0.3, 0.02)], 0.012, "cable", segs=5)
    return p


def fire_escape():
    """One storey of fire escape: platform, railings, stair to the next level."""
    p = Piece("fire_escape", 46)
    d = 1.25
    z = 0.0
    # platform frame + grating slats
    p.box(-W / 2 + 0.1, -d, z - 0.08, W / 2 - 0.1, 0.0, z - 0.02, "metal_dark", bev=0.008)
    for i in range(14):
        y = -d + 0.05 + i * (d - 0.1) / 13
        p.box(-W / 2 + 0.12, y - 0.015, z - 0.02, W / 2 - 0.12, y + 0.015, z, "grate")
    railing(p, -W / 2 + 0.1, W / 2 - 0.1, -d + 0.03, z, h=1.0, posts=0.95, mat="metal_dark")
    railing_y(p, -d + 0.03, 0.0, -W / 2 + 0.12, z, h=1.0, posts=0.6, mat="metal_dark")
    # brackets to the wall
    for x in (-1.6, 1.6):
        p.tube([(x, -d + 0.05, z - 0.08), (x, -0.02, z - 0.9)], 0.03, "metal_dark", segs=6)
    # stair from this platform up to the next
    sx0, sx1 = -1.5, 1.4
    ys0, ys1 = -d + 0.15, -0.25
    steps = 11
    for i in range(steps):
        t = (i + 0.5) / steps
        x = sx1 - (sx1 - sx0) * t
        zz = z + H * t
        p.box(x - 0.13, ys0 + 0.05, zz - 0.02, x + 0.13, ys1 - 0.05, zz + 0.02, "grate")
    for y in (ys0, ys1):
        p.tube([(sx1 + 0.15, y, z), (sx0 - 0.15, y, z + H)], 0.03, "metal_dark", segs=5)
        p.tube([(sx1 + 0.15, y, z + 0.9), (sx0 - 0.15, y, z + H + 0.9)], 0.018, "metal_dark", segs=5)
    p.tube([(sx1 + 0.15, ys0, z), (sx1 + 0.15, ys0, z + 0.9)], 0.02, "metal_dark", segs=5)
    return p


def awning_a():
    p = Piece("awning_a", 47)
    d, z, drop = 1.5, 3.55, 0.55
    # sloped fabric made of ribs (stripes alternate rnd value so shader can stripe)
    n = 8
    for i in range(n):
        a = -W / 2 + 0.1 + i * (W - 0.2) / n
        b = a + (W - 0.2) / n
        rr = 0.1 if i % 2 == 0 else 0.9
        p.quad([(a, 0.0, z + 0.6), (b, 0.0, z + 0.6), (b, -d, z + 0.6 - drop), (a, -d, z + 0.6 - drop)], "fabric", uvk=0, rnd=rr)
        p.quad([(a, 0.0, z + 0.6), (a, -d, z + 0.6 - drop), (b, -d, z + 0.6 - drop), (b, 0.0, z + 0.6)], "fabric", uvk=0, rnd=rr)
        # scalloped valance
        p.quad([(a, -d, z + 0.6 - drop), (b, -d, z + 0.6 - drop), (b, -d, z + 0.3 - drop), ((a + b) / 2, -d, z + 0.22 - drop), (a, -d, z + 0.3 - drop)], "fabric", uvk=0, rnd=rr)
    for x in (-W / 2 + 0.1, W / 2 - 0.1):
        p.tube([(x, 0.0, z + 0.62), (x, -d, z + 0.62 - drop)], 0.02, "metal_dark", segs=5)
        p.tube([(x, 0.0, z + 0.1), (x, -d + 0.1, z + 0.6 - drop)], 0.015, "metal_dark", segs=5)
    p.tube([(-W / 2 + 0.1, -d, z + 0.62 - drop), (W / 2 - 0.1, -d, z + 0.62 - drop)], 0.02, "metal_dark", segs=5)
    return p


def awning_b():
    p = Piece("awning_b", 48)
    d, z = 1.7, 3.6
    p.box(-W / 2, -d, z, W / 2, 0.05, z + 0.14, "metal_panel", bev=0.03, segs=2)
    p.box(-W / 2 + 0.05, -d + 0.02, z - 0.02, W / 2 - 0.05, -d + 0.08, z + 0.01, "led_strip")
    for i in range(3):
        x = -1.2 + i * 1.2
        p.cyl(x, -d / 2, z - 0.02, 0.09, 0.02, "shop_light", segs=10)
    for x in (-1.7, 1.7):
        p.tube([(x, 0.0, z + 1.3), (x, -d + 0.1, z + 0.15)], 0.02, "cable", segs=4)
    return p


def build_all(only=None):
    fns = [fac_concrete_a, fac_concrete_b, fac_brick_a, fac_brick_b, fac_panel_a, fac_balcony_a, fac_tile_a,
           fac_glass_a, fac_blank_a, shop_window_a, lambda: shop_shutter("shop_shutter_a", 0.0, 22),
           lambda: shop_shutter("shop_shutter_half", 0.45, 23), shop_food_a, entry_a, wall_service_a,
           cornice_a, cornice_b, ac_unit_piece, ac_unit_pair, pipe_v, pipe_cluster, conduit_h, fire_escape,
           awning_a, awning_b]
    for fn in fns:
        p = fn()
        if only and p.name not in only:
            continue
        build_and_export(p)
