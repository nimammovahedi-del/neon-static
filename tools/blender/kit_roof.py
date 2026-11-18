# Rooftop pieces (water tanks, HVAC, antenna masts, dishes, stair houses, billboards on frames,
# industrial stacks and ducts) plus hanging paper lanterns. Origin at the base centre.
from kitlib import Piece, build_and_export, rot_z, tr
import math


def water_tank():
    p = Piece("water_tank", 501)
    h0 = 2.2
    for x in (-1.2, 1.2):
        for y in (-1.2, 1.2):
            p.box(x - 0.08, y - 0.08, 0, x + 0.08, y + 0.08, h0, "metal_dark", bev=0.015)
    for z in (0.8, h0 - 0.1):
        for (a, b) in (((-1.2, -1.2), (1.2, -1.2)), ((1.2, -1.2), (1.2, 1.2)), ((1.2, 1.2), (-1.2, 1.2)), ((-1.2, 1.2), (-1.2, -1.2))):
            p.tube([(a[0], a[1], z), (b[0], b[1], z)], 0.04, "metal_dark", segs=5)
    for (a, b) in (((-1.2, -1.2), (1.2, -1.2)), ((1.2, 1.2), (-1.2, 1.2))):
        p.tube([(a[0], a[1], 0.1), (b[0], b[1], h0 - 0.1)], 0.03, "metal_dark", segs=4)
    p.box(-1.5, -1.5, h0, 1.5, 1.5, h0 + 0.18, "metal_dark", bev=0.02)
    p.cyl(0, 0, h0 + 0.18, 1.45, 3.6, "wood", segs=20)
    for z in (0.5, 1.4, 2.4, 3.3):
        p.cyl(0, 0, h0 + 0.18 + z, 1.48, 0.06, "metal_dark", segs=20)
    p.cyl(0, 0, h0 + 3.78, 1.55, 0.9, "metal_rust", segs=20, r2=0.15)
    p.cyl(0, 0, h0 + 4.65, 0.18, 0.2, "metal_dark", segs=8)
    # ladder
    for x in (-0.25, 0.25):
        p.box(x - 0.02, -1.55, 0, x + 0.02, -1.5, h0 + 3.8, "metal_dark")
    for i in range(18):
        z = 0.3 + i * 0.32
        p.box(-0.25, -1.54, z - 0.012, 0.25, -1.51, z + 0.012, "metal_dark")
    p.tube([(0.9, 0.9, h0), (0.9, 0.9, 0.3), (1.8, 0.9, 0.3)], 0.08, "metal_rust", segs=8)
    return p


def roof_hvac():
    p = Piece("roof_hvac", 502)
    p.box(-1.8, -1.0, 0, 1.8, 1.0, 0.15, "concrete_dark", bev=0.02)
    p.box(-1.7, -0.9, 0.15, 1.7, 0.9, 1.5, "metal_bare", bev=0.04, segs=2)
    for i in range(14):
        y = -0.85 + i * 0.12
        p.box(-1.72, y, 0.3, -1.69, y + 0.07, 1.3, "metal_dark")
        p.box(1.69, y, 0.3, 1.72, y + 0.07, 1.3, "metal_dark")
    for x in (-0.85, 0.85):
        p.cyl(x, 0, 1.5, 0.7, 0.25, "metal_dark", segs=20)
        ring = [(x + 0.66 * math.cos(a * math.pi / 10), 0.66 * math.sin(a * math.pi / 10), 1.76) for a in range(20)]
        p.tube(ring, 0.025, "metal_bare", segs=4, closed=True)
        for k in range(4):
            ang = k * math.pi / 4
            p.box(x - 0.6 * math.cos(ang) - 0.02, -0.6 * math.sin(ang) - 0.02, 1.74, x + 0.6 * math.cos(ang) + 0.02, 0.6 * math.sin(ang) + 0.02, 1.77, "metal_bare")
        p.cyl(x, 0, 1.6, 0.12, 0.2, "metal_bare", segs=8)
    # duct leaving the unit
    p.box(-1.5, 0.9, 0.4, -0.6, 2.6, 1.2, "metal_bare", bev=0.03)
    p.box(-1.55, 2.6, 0.35, -0.55, 2.7, 1.25, "metal_dark", bev=0.01)
    return p


def antenna_mast():
    p = Piece("antenna_mast", 503)
    h = 14.0
    p.box(-0.7, -0.7, 0, 0.7, 0.7, 0.3, "concrete", bev=0.03)
    r = 0.35
    pts = [(r * math.cos(a), r * math.sin(a)) for a in (0, 2.094, 4.189)]
    for (x, y) in pts:
        p.tube([(x, y, 0.3), (x * 0.4, y * 0.4, h)], 0.035, "metal_bare", segs=5)
    n = 14
    for i in range(n):
        z0 = 0.3 + (h - 0.3) * i / n
        z1 = 0.3 + (h - 0.3) * (i + 1) / n
        k0 = 1 - 0.6 * i / n; k1 = 1 - 0.6 * (i + 1) / n
        for j in range(3):
            a = pts[j]; b = pts[(j + 1) % 3]
            p.tube([(a[0] * k0, a[1] * k0, z0), (b[0] * k1, b[1] * k1, z1)], 0.012, "metal_bare", segs=4)
    for z, L in ((5.0, 1.6), (8.5, 1.2), (11.5, 0.9)):
        p.tube([(-L, 0, z), (L, 0, z)], 0.025, "metal_bare", segs=5)
        for s in (-1, 1):
            p.box(s * L - 0.06, -0.06, z - 0.6, s * L + 0.06, 0.06, z + 0.1, "plastic_dark", bev=0.02)
    p.cyl(0, 0, h, 0.03, 3.0, "metal_bare", segs=6)
    p.cyl(0, 0, h + 3.0, 0.09, 0.16, "blinker", segs=10)
    p.cyl(0, 0, 8.5, 0.08, 0.12, "blinker", segs=10)
    # small dishes on the mast
    for z, a in ((6.5, 30), (9.8, 200)):
        p.push(tr(0, 0, z) @ rot_z(a))
        p.cyl(0, -0.35, 0, 0.32, 0.12, "metal_bare", axis='Y', segs=14, r2=0.06)
        p.tube([(0, 0, 0), (0, -0.3, 0)], 0.02, "metal_dark", segs=4)
        p.pop()
    return p


def dish_a():
    p = Piece("dish_a", 504)
    p.box(-0.5, -0.5, 0, 0.5, 0.5, 0.12, "concrete_dark", bev=0.02)
    p.cyl(0, 0, 0.12, 0.08, 1.2, "metal_dark", segs=8)
    p.push(tr(0, 0, 1.35) @ rot_z(25))
    p.push(__import__("kitlib").rot_x(-25))
    p.cyl(0, 0.1, 0, 1.1, 0.35, "metal_bare", axis='Y', segs=20, r2=0.25, caps=True)
    p.cyl(0, 0.45, 0, 0.26, 0.06, "metal_dark", axis='Y', segs=12)
    for a in (0, 120, 240):
        ang = math.radians(a)
        p.tube([(1.0 * math.cos(ang), 0.1, 1.0 * math.sin(ang)), (0, -1.0, 0)], 0.018, "metal_dark", segs=4)
    p.box(-0.1, -1.15, -0.1, 0.1, -0.95, 0.1, "plastic_dark", bev=0.02)
    p.pop(); p.pop()
    return p


def roof_stairhouse():
    p = Piece("roof_stairhouse", 505)
    p.box(-1.6, -1.4, 0, 1.6, 1.4, 3.0, "concrete", bev=0.03)
    p.box(-1.7, -1.5, 3.0, 1.7, 1.5, 3.2, "concrete_dark", bev=0.03)
    p.box(-0.5, -1.45, 0.1, 0.5, -1.38, 2.2, "metal_panel", bev=0.015)
    p.box(-0.6, -1.7, 2.3, 0.6, -1.4, 2.4, "metal_dark")
    p.box(-0.15, -1.62, 2.4, 0.15, -1.45, 2.52, "metal_dark", bev=0.01)
    p.box(-0.12, -1.63, 2.38, 0.12, -1.6, 2.41, "lamp_lens")
    p.box(0.8, -1.42, 1.6, 1.3, -1.38, 2.0, "grate")
    p.cyl(1.0, 0.6, 3.2, 0.15, 1.2, "metal_bare", segs=8)
    p.cyl(1.0, 0.6, 4.4, 0.25, 0.15, "metal_bare", segs=8, r2=0.1)
    return p


def billboard_roof():
    """Rooftop billboard on a steel truss frame, 14 x 7 m screen facing -Y."""
    p = Piece("billboard_roof", 506)
    w, h, z0 = 14.0, 7.0, 3.0
    p.box(-w / 2 - 0.3, -0.5, z0 - 0.3, w / 2 + 0.3, 0.1, z0 + h + 0.3, "metal_dark", bev=0.08, segs=2)
    p.quad([(-w / 2, -0.51, z0), (w / 2, -0.51, z0), (w / 2, -0.51, z0 + h), (-w / 2, -0.51, z0 + h)], "screen", uvk=1)
    for x in (-w / 2 + 0.5, -w / 4, 0, w / 4, w / 2 - 0.5):
        p.box(x - 0.15, 0.1, 0, x + 0.15, 0.4, z0 + h, "metal_dark", bev=0.03)
        p.tube([(x, 0.3, 0.0), (x, 3.5, 0.0)], 0.1, "metal_dark", segs=6)
        p.tube([(x, 3.5, 0.0), (x, 0.3, z0 + h * 0.7)], 0.09, "metal_dark", segs=6)
        p.tube([(x, 3.5, 0.0), (x, 0.3, z0 * 0.6)], 0.06, "metal_dark", segs=6)
    for z in (z0 * 0.5, z0 + h * 0.5):
        p.tube([(-w / 2, 0.35, z), (w / 2, 0.35, z)], 0.07, "metal_dark", segs=6)
    p.box(-w / 2, -1.6, z0 - 0.45, w / 2, -0.45, z0 - 0.38, "grate")
    for i in range(15):
        x = -w / 2 + i * w / 14
        p.box(x - 0.02, -1.6, z0 - 0.38, x + 0.02, -1.56, z0 + 0.6, "metal_dark")
    p.box(-w / 2, -1.62, z0 + 0.55, w / 2, -1.55, z0 + 0.6, "metal_dark")
    for x in (-5.5, -2, 2, 5.5):
        p.tube([(x, -1.55, z0 - 0.4), (x, -2.4, z0 - 0.1)], 0.04, "metal_dark", segs=5)
        p.box(x - 0.2, -2.6, z0 - 0.25, x + 0.2, -2.25, z0 + 0.05, "metal_dark", bev=0.03)
        p.box(x - 0.17, -2.62, z0 - 0.2, x + 0.17, -2.59, z0 + 0.0, "lamp_lens")
    p.cyl(w / 2 + 0.3, 0, z0 + h + 0.3, 0.08, 0.15, "blinker", segs=8)
    p.cyl(-w / 2 - 0.3, 0, z0 + h + 0.3, 0.08, 0.15, "blinker", segs=8)
    return p


def stack_industrial():
    """Industrial exhaust stack with platforms, pipes and a cap."""
    p = Piece("stack_industrial", 507)
    p.box(-1.4, -1.4, 0, 1.4, 1.4, 0.6, "concrete", bev=0.04)
    p.cyl(0, 0, 0.6, 0.85, 11.0, "metal_rust", segs=16, r2=0.7)
    for z in (2.0, 5.0, 8.0, 10.5):
        p.cyl(0, 0, z, 0.9 - z * 0.012, 0.18, "metal_dark", segs=16)
    p.cyl(0, 0, 11.6, 0.8, 0.5, "metal_dark", segs=16, r2=0.85)
    p.cyl(0, 0, 6.0, 1.5, 0.08, "grate", segs=16)
    ring = [(1.5 * math.cos(a * math.pi / 8), 1.5 * math.sin(a * math.pi / 8), 7.0) for a in range(16)]
    p.tube(ring, 0.03, "paint_yellow", segs=4, closed=True)
    for a in range(0, 16, 2):
        ang = a * math.pi / 8
        p.tube([(1.5 * math.cos(ang), 1.5 * math.sin(ang), 6.05), (1.5 * math.cos(ang), 1.5 * math.sin(ang), 7.0)], 0.02, "paint_yellow", segs=4)
    for x in (-0.25, 0.25):
        p.box(x - 0.02, -0.95, 0.6, x + 0.02, -0.9, 11.2, "metal_dark")
    for i in range(30):
        p.box(-0.25, -0.94, 0.9 + i * 0.35, 0.25, -0.91, 0.92 + i * 0.35, "metal_dark")
    p.cyl(0, 0, 12.1, 0.06, 0.12, "blinker", segs=8)
    p.tube([(1.2, 0, 1.5), (2.8, 0, 1.5), (2.8, 0, 0.2)], 0.25, "metal_bare", segs=10)
    p.tube([(-0.6, 0.6, 3.5), (-2.4, 2.4, 3.5), (-2.4, 2.4, 0.2)], 0.14, "metal_rust", segs=8)
    return p


def duct_run():
    """8 m of rooftop ductwork on stands with an elbow and a vent hood."""
    p = Piece("duct_run", 508)
    p.box(-4.0, -0.45, 0.6, 3.2, 0.45, 1.4, "metal_bare", bev=0.03)
    for x in (-3.8, 3.2 - 0.2):
        p.box(x, -0.47, 0.58, x + 0.2, 0.47, 1.42, "metal_dark", bev=0.01)
    for x in (-3.0, -0.5, 2.0):
        p.box(x - 0.05, -0.5, 0, x + 0.05, -0.4, 0.6, "metal_dark")
        p.box(x - 0.05, 0.4, 0, x + 0.05, 0.5, 0.6, "metal_dark")
        p.box(x - 0.08, -0.55, 0.55, x + 0.08, 0.55, 0.62, "metal_dark")
    p.box(3.2, -0.45, 0.6, 4.0, 0.45, 3.0, "metal_bare", bev=0.03)
    p.box(3.0, -0.75, 3.0, 4.2, 0.75, 3.15, "metal_dark", bev=0.02)
    p.box(3.1, -0.65, 3.15, 4.1, 0.65, 3.6, "grate")
    p.box(3.0, -0.8, 3.6, 4.2, 0.8, 3.75, "metal_dark", bev=0.02)
    return p


def cooling_unit():
    """Boxy industrial chiller with big fan rings (acid / industrial rooftops)."""
    p = Piece("cooling_unit", 509)
    p.box(-2.4, -1.3, 0, 2.4, 1.3, 2.2, "metal_panel", bev=0.04, segs=2)
    for i in range(3):
        x = -1.6 + i * 1.6
        p.cyl(x, 0, 2.2, 0.72, 0.45, "metal_dark", segs=20)
        ring = [(x + 0.7 * math.cos(a * math.pi / 10), 0.7 * math.sin(a * math.pi / 10), 2.66) for a in range(20)]
        p.tube(ring, 0.03, "metal_bare", segs=4, closed=True)
        p.box(x - 0.7, -0.02, 2.62, x + 0.7, 0.02, 2.66, "metal_bare")
        p.box(x - 0.02, -0.7, 2.62, x + 0.02, 0.7, 2.66, "metal_bare")
    for i in range(18):
        x = -2.2 + i * 0.25
        p.box(x, -1.32, 0.3, x + 0.12, -1.3, 1.9, "grate")
    p.box(-2.0, 1.3, 0.3, -1.2, 1.6, 1.0, "metal_dark", bev=0.02)
    p.tube([(2.4, 0.5, 0.8), (3.2, 0.5, 0.8), (3.2, 0.5, 0.0)], 0.15, "paint_yellow", segs=8)
    p.tube([(2.4, -0.5, 1.2), (3.6, -0.5, 1.2), (3.6, -0.5, 0.0)], 0.12, "metal_rust", segs=8)
    return p


def lantern():
    """Paper lantern (0.45 m) with ribs and caps; hangs from its top (origin)."""
    p = Piece("lantern", 510)
    p.tube([(0, 0, 0), (0, 0, -0.12)], 0.006, "cable", segs=4, caps=False)
    p.cyl(0, 0, -0.17, 0.09, 0.05, "metal_dark", segs=10)
    prof = [(0.12, -0.17), (0.2, -0.22), (0.24, -0.3), (0.25, -0.4), (0.24, -0.5), (0.2, -0.58), (0.12, -0.63)]
    segs = 14
    import bmesh
    from mathutils import Vector
    rings = []
    for (r, z) in prof:
        rings.append([p.bm.verts.new(p.M @ Vector((r * math.cos(a * 2 * math.pi / segs), r * math.sin(a * 2 * math.pi / segs), z))) for a in range(segs)])
    faces = []
    for i in range(len(rings) - 1):
        A, B = rings[i], rings[i + 1]
        for k in range(segs):
            k2 = (k + 1) % segs
            faces.append(p.bm.faces.new([A[k], B[k], B[k2], A[k2]]))
    p._tag(faces, "lantern")
    for a in range(0, segs, 2):
        ang = a * 2 * math.pi / segs
        p.tube([(r * 1.02 * math.cos(ang), r * 1.02 * math.sin(ang), z) for (r, z) in prof], 0.006, "metal_dark", segs=3, caps=False)
    p.cyl(0, 0, -0.68, 0.09, 0.05, "metal_dark", segs=10)
    for k in range(5):
        ang = k * 2 * math.pi / 5
        p.tube([(0.04 * math.cos(ang), 0.04 * math.sin(ang), -0.68), (0.05 * math.cos(ang), 0.05 * math.sin(ang), -0.9)], 0.008, "fabric", segs=3)
    return p


def build_all(only=None):
    fns = [water_tank, roof_hvac, antenna_mast, dish_a, roof_stairhouse, billboard_roof, stack_industrial, duct_run,
           cooling_unit, lantern]
    for fn in fns:
        p = fn()
        if only and p.name not in only:
            continue
        build_and_export(p)
