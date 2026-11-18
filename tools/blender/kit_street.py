# Street furniture: lamps, traffic lights, bollards, bins, hydrant, vending machines, kiosk,
# manhole, street vent, kerbs, utility boxes, barriers, clutter, cable span.
# Origin at the base centre; "front" (the side people use) faces -Y.
from kitlib import Piece, build_and_export, rot_z, rot_x, tr
import math


def lamp_a():
    """Tall street lamp: plinth, tapered octagonal pole, curved arm, flat LED head over the road (+X)."""
    p = Piece("lamp_a", 101)
    p.cyl(0, 0, 0, 0.26, 0.5, "concrete", segs=8, bev=0.03)
    p.cyl(0, 0, 0.5, 0.2, 0.08, "metal_dark", segs=8, bev=0.015)
    p.cyl(0, 0, 0.58, 0.13, 7.4, "metal_dark", segs=8, r2=0.075)
    for z in (2.4, 5.2):
        p.cyl(0, 0, z, 0.135 - z * 0.008, 0.06, "metal_bare", segs=8)
    p.box(-0.06, -0.14, 1.0, 0.06, -0.1, 1.45, "metal_bare", bev=0.008)
    p.cyl(0, 0, 3.0, 0.118, 0.05, "led_strip", segs=8)
    pts = []
    for i in range(13):
        t = i / 12
        a = t * math.pi / 2
        pts.append((1.0 - math.cos(a) * 1.0 + t * 1.6, 0, 7.6 + math.sin(a) * 0.9 - t * 0.2))
    p.tube([(0, 0, 7.2)] + pts, 0.06, "metal_dark", segs=8)
    hx, hz = pts[-1][0], pts[-1][2]
    p.box(hx - 0.35, -0.2, hz - 0.12, hx + 0.65, 0.2, hz + 0.02, "metal_dark", bev=0.03, segs=2)
    p.box(hx - 0.28, -0.14, hz - 0.135, hx + 0.58, 0.14, hz - 0.11, "lamp_lens")
    for i in range(5):
        p.box(hx - 0.2 + i * 0.17, -0.17, hz + 0.02, hx - 0.17 + i * 0.17, 0.17, hz + 0.07, "metal_dark")
    p.box(0.0, -0.03, 4.1, 0.65, 0.03, 4.14, "metal_dark")
    p.box(0.0, -0.03, 5.5, 0.65, 0.03, 5.54, "metal_dark")
    p.box(0.08, -0.012, 4.16, 0.6, 0.012, 5.48, "fabric")
    return p


def lamp_b():
    """Shorter pedestrian lamp with two box heads."""
    p = Piece("lamp_b", 102)
    p.cyl(0, 0, 0, 0.18, 0.35, "metal_dark", segs=10, bev=0.02)
    p.box(-0.07, -0.07, 0.35, 0.07, 0.07, 4.6, "metal_dark", bev=0.02)
    p.box(-0.075, -0.075, 1.5, 0.075, 0.075, 3.2, "metal_bare", bev=0.01)
    for s in (-1, 1):
        p.box(min(0, s * 0.7), -0.04, 4.45, max(0, s * 0.7), 0.04, 4.52, "metal_dark")
        p.box(s * 0.7 - 0.18, -0.18, 4.15, s * 0.7 + 0.18, 0.18, 4.45, "metal_dark", bev=0.025)
        p.box(s * 0.7 - 0.15, -0.15, 4.13, s * 0.7 + 0.15, 0.15, 4.16, "lamp_lens")
    p.box(-0.08, -0.08, 4.6, 0.08, 0.08, 4.68, "metal_dark", bev=0.02)
    return p


def signal_head(p, x, y, z, rot=0, ped=False):
    p.push(tr(x, y, z) @ rot_z(rot))
    if ped:
        p.box(-0.18, -0.12, 0, 0.18, 0.12, 0.62, "metal_dark", bev=0.02)
        p.box(-0.14, -0.13, 0.33, 0.14, -0.12, 0.58, "signal_red")
        p.box(-0.14, -0.13, 0.04, 0.14, -0.12, 0.29, "plastic_dark")
        p.box(-0.18, -0.25, 0.58, 0.18, -0.12, 0.6, "metal_dark")
    else:
        p.box(-0.18, -0.13, 0, 0.18, 0.13, 1.0, "paint_yellow", bev=0.025)
        p.box(-0.24, 0.12, -0.04, 0.24, 0.15, 1.04, "metal_dark", bev=0.01)
        for i, m in enumerate(("signal_green", "signal_amber", "signal_red")):
            zz = 0.18 + i * 0.32
            p.cyl(0, -0.13, zz, 0.11, 0.012, m, axis='Y', segs=14, r2=0.11)
            p.box(-0.13, -0.34, zz + 0.115, 0.13, -0.13, zz + 0.135, "metal_dark")
            p.box(-0.135, -0.34, zz - 0.05, -0.115, -0.13, zz + 0.135, "metal_dark")
            p.box(0.115, -0.34, zz - 0.05, 0.135, -0.13, zz + 0.135, "metal_dark")
    p.pop()


def traffic_light():
    """Pole on the kerb with a mast arm reaching over the road along +X, signals face -Y."""
    p = Piece("traffic_light", 103)
    p.cyl(0, 0, 0, 0.22, 0.35, "concrete", segs=10, bev=0.02)
    p.cyl(0, 0, 0.35, 0.12, 6.3, "metal_dark", segs=10, r2=0.1)
    p.box(-0.12, -0.12, 6.4, 0.12, 0.12, 6.75, "metal_dark", bev=0.02)
    p.tube([(0.0, 0, 6.55), (6.5, 0, 6.65)], 0.08, "metal_dark", segs=8)
    p.tube([(0.0, 0, 5.6), (2.2, 0, 6.5)], 0.035, "metal_dark", segs=6)
    signal_head(p, 3.4, 0, 5.35)
    signal_head(p, 6.2, 0, 5.4)
    signal_head(p, 0.0, -0.25, 2.6, ped=True)
    signal_head(p, 0.0, 0.25, 2.6, rot=180, ped=True)
    p.box(-0.1, -0.2, 1.0, 0.1, -0.1, 1.25, "paint_yellow", bev=0.015)
    p.cyl(0, -0.2, 1.12, 0.035, 0.02, "chrome", axis='Y', segs=8)
    p.box(0.1, -0.02, 4.4, 1.5, 0.02, 4.7, "sign_face", uvk_front=1)
    return p


def bollard():
    p = Piece("bollard", 104)
    p.cyl(0, 0, 0, 0.11, 0.9, "metal_dark", segs=10, bev=0.02)
    p.cyl(0, 0, 0.72, 0.115, 0.06, "led_strip", segs=10)
    p.cyl(0, 0, 0.9, 0.1, 0.04, "metal_bare", segs=10, r2=0.06)
    return p


def bin_a():
    p = Piece("bin_a", 105)
    p.box(-0.32, -0.28, 0.06, 0.32, 0.28, 1.0, "metal_panel", bev=0.04, segs=2)
    p.box(-0.34, -0.3, 1.0, 0.34, 0.3, 1.08, "metal_dark", bev=0.03)
    p.box(-0.18, -0.31, 0.75, 0.18, -0.28, 0.9, "plastic_dark")
    for x in (-0.26, 0.26):
        for y in (-0.22, 0.22):
            p.cyl(x, y, 0, 0.05, 0.06, "rubber", segs=8)
    p.box(-0.22, -0.18, 1.06, 0.2, 0.2, 1.3, "plastic_dark", bev=0.08, segs=2)
    return p


def hydrant():
    p = Piece("hydrant", 106)
    p.cyl(0, 0, 0, 0.16, 0.08, "paint_yellow", segs=12, bev=0.01)
    p.cyl(0, 0, 0.08, 0.12, 0.55, "paint_yellow", segs=12)
    p.cyl(0, 0, 0.63, 0.15, 0.06, "paint_yellow", segs=12, bev=0.01)
    p.cyl(0, 0, 0.69, 0.11, 0.12, "paint_yellow", segs=12, r2=0.05)
    p.cyl(0, 0, 0.81, 0.03, 0.05, "metal_dark", segs=6)
    for a in (0, 180):
        p.push(rot_z(a))
        p.cyl(0, -0.1, 0.42, 0.06, 0.12, "paint_yellow", axis='Y', segs=10)
        p.cyl(0, -0.22, 0.42, 0.07, 0.03, "metal_dark", axis='Y', segs=6)
        p.pop()
    p.cyl(0, -0.1, 0.38, 0.08, 0.16, "paint_yellow", axis='X', segs=10)
    return p


def vending(name, seed, accent="screen"):
    """Glowing vending machine: lit product window, side panel art, buttons, pickup slot."""
    p = Piece(name, seed)
    w, d, h = 1.0, 0.8, 1.95
    x0, x1, z0, z1 = -0.44, 0.2, 0.62, 1.82
    rec = 0.1  # depth of the product-window recess
    p.box(-w / 2, -d / 2 + rec, 0.0, w / 2, d / 2, h, "metal_panel", bev=0.03, segs=2)
    # front shell around the recess (left, right, below, above)
    p.box(-w / 2, -d / 2, 0.0, x0, -d / 2 + rec + 0.01, h, "metal_panel", bev=0.02)
    p.box(x1, -d / 2, 0.0, w / 2, -d / 2 + rec + 0.01, h, "metal_panel", bev=0.02)
    p.box(x0, -d / 2, 0.0, x1, -d / 2 + rec + 0.01, z0, "metal_panel", bev=0.01)
    p.box(x0, -d / 2, z1, x1, -d / 2 + rec + 0.01, h, "metal_panel", bev=0.01)
    p.box(-w / 2 + 0.02, -d / 2 + 0.02, 0, w / 2 - 0.02, d / 2 - 0.02, 0.08, "rubber")
    p.box(x0, -d / 2 + 0.085, z0, x1, -d / 2 + 0.1, z1, "vend_panel")
    for i in range(5):
        z = z0 + 0.06 + i * 0.235
        p.box(x0 + 0.01, -d / 2 - 0.01, z, x1 - 0.01, -d / 2 + 0.06, z + 0.015, "metal_bare")
        for k in range(5):
            xx = x0 + 0.05 + k * 0.125
            if (i + k) % 3 == 0:
                p.cyl(xx + 0.03, -d / 2 + 0.03, z + 0.015, 0.03, 0.14, "goods", segs=8)
            else:
                p.box(xx, -d / 2 + 0.01, z + 0.015, xx + 0.07, -d / 2 + 0.05, z + 0.15, "goods", bev=0.006)
    p.quad([(x0, -d / 2 - 0.02, z0), (x1, -d / 2 - 0.02, z0), (x1, -d / 2 - 0.02, z1), (x0, -d / 2 - 0.02, z1)], "glass_shop", uvk=1)
    for (a, b, c, e) in ((x0 - 0.03, x0, z0, z1), (x1, x1 + 0.03, z0, z1), (x0, x1, z0 - 0.03, z0), (x0, x1, z1, z1 + 0.03)):
        p.box(a, -d / 2 - 0.035, c, b, -d / 2 + 0.01, e, "metal_dark")
    p.box(0.25, -d / 2 - 0.02, 1.3, 0.45, -d / 2 + 0.01, 1.62, accent, uvk_front=1)
    for i in range(6):
        p.box(0.28 + (i % 2) * 0.09, -d / 2 - 0.03, 0.95 + (i // 2) * 0.1, 0.34 + (i % 2) * 0.09, -d / 2, 1.0 + (i // 2) * 0.1, "light_amber")
    p.box(0.3, -d / 2 - 0.03, 0.7, 0.4, -d / 2, 0.85, "plastic_dark")
    p.box(-0.4, -d / 2 - 0.03, 0.22, 0.15, -d / 2 + 0.02, 0.45, "plastic_dark", bev=0.015)
    p.box(-0.38, -d / 2 - 0.035, 0.24, 0.13, -d / 2 - 0.02, 0.42, "glass_car")
    p.box(-w / 2, -d / 2 - 0.03, 1.86, w / 2, -d / 2 + 0.05, h - 0.02, "sign_body", bev=0.01)
    p.quad([(-w / 2 + 0.03, -d / 2 - 0.035, 1.87), (w / 2 - 0.03, -d / 2 - 0.035, 1.87), (w / 2 - 0.03, -d / 2 - 0.035, h - 0.03), (-w / 2 + 0.03, -d / 2 - 0.035, h - 0.03)], "sign_face", uvk=1)
    p.quad([(w / 2 + 0.005, -d / 2 + 0.06, 0.3), (w / 2 + 0.005, d / 2 - 0.06, 0.3), (w / 2 + 0.005, d / 2 - 0.06, 1.8), (w / 2 + 0.005, -d / 2 + 0.06, 1.8)], "sign_face", uvk=1)
    return p


def kiosk_a():
    """Glowing street kiosk with lit glass upper body, goods and a canopy sign band."""
    p = Piece("kiosk_a", 109)
    p.box(-1.1, -0.8, 0, 1.1, 0.8, 0.15, "concrete_dark", bev=0.02)
    p.box(-1.0, -0.7, 0.15, 1.0, 0.7, 1.1, "metal_panel", bev=0.03)
    p.box(-1.05, -0.78, 1.1, 1.05, 0.78, 1.16, "metal_bare", bev=0.015)
    p.box(-0.9, -0.6, 1.16, 0.9, 0.6, 2.3, "interior")
    p.quad([(-0.95, 0.65, 1.16), (-0.95, -0.65, 1.16), (-0.95, -0.65, 2.3), (-0.95, 0.65, 2.3)], "glass_shop", uvk=1)
    p.quad([(0.95, -0.65, 1.16), (0.95, 0.65, 1.16), (0.95, 0.65, 2.3), (0.95, -0.65, 2.3)], "glass_shop", uvk=1)
    p.quad([(-0.95, -0.65, 1.16), (0.95, -0.65, 1.16), (0.95, -0.65, 2.3), (-0.95, -0.65, 2.3)], "glass_shop", uvk=1)
    for x in (-0.95, 0.0, 0.95):
        for y in (-0.65, 0.65):
            p.box(x - 0.03, y - 0.03, 1.16, x + 0.03, y + 0.03, 2.3, "metal_dark")
    for i in range(6):
        p.box(-0.85 + i * 0.28, -0.62, 1.2, -0.62 + i * 0.28, -0.6, 1.45 + 0.1 * (i % 2), "sign_face", uvk_front=1)
    p.box(-1.4, -1.1, 2.3, 1.4, 1.1, 2.45, "metal_dark", bev=0.03, segs=2)
    p.box(-1.2, -0.95, 2.45, 1.2, 0.95, 2.95, "sign_body", bev=0.02)
    p.quad([(-1.15, -0.96, 2.5), (1.15, -0.96, 2.5), (1.15, -0.96, 2.9), (-1.15, -0.96, 2.9)], "sign_face", uvk=1)
    p.quad([(1.15, 0.96, 2.5), (-1.15, 0.96, 2.5), (-1.15, 0.96, 2.9), (1.15, 0.96, 2.9)], "sign_face", uvk=1)
    p.box(-1.38, -1.1, 2.28, 1.38, -1.05, 2.31, "led_strip")
    p.box(-0.5, -0.72, 0.4, 0.5, -0.69, 1.0, "screen", uvk_front=1)
    return p


def manhole():
    p = Piece("manhole", 110)
    p.cyl(0, 0, -0.02, 0.38, 0.03, "metal_dark", segs=24)
    for r in (0.12, 0.2, 0.28):
        ring = [(r * math.cos(a * math.pi / 12), r * math.sin(a * math.pi / 12), 0.012) for a in range(24)]
        p.tube(ring, 0.012, "metal_bare", segs=4, closed=True)
    for a in range(8):
        ang = a * math.pi / 4
        p.tube([(0.05 * math.cos(ang), 0.05 * math.sin(ang), 0.012), (0.33 * math.cos(ang), 0.33 * math.sin(ang), 0.012)], 0.01, "metal_bare", segs=4)
    ring = [(0.37 * math.cos(a * math.pi / 12), 0.37 * math.sin(a * math.pi / 12), 0.01) for a in range(24)]
    p.tube(ring, 0.02, "metal_bare", segs=4, closed=True)
    return p


def vent_street():
    """Rectangular street steam vent with bars."""
    p = Piece("vent_street", 111)
    p.box(-0.7, -0.45, -0.03, 0.7, 0.45, 0.015, "metal_dark", bev=0.01)
    for i in range(13):
        x = -0.6 + i * 0.1
        p.box(x - 0.018, -0.38, 0.0, x + 0.018, 0.38, 0.025, "metal_bare", bev=0.004)
    p.box(-0.66, -0.41, -0.6, 0.66, 0.41, -0.55, "interior_dark")
    return p


def curb():
    """2 m kerb, road side at -Y, top at z = 0.15 (sidewalk level)."""
    p = Piece("curb", 112)
    for i in range(2):
        x0 = -1.0 + i * 1.0
        p.box(x0 + 0.004, -0.15, -0.1, x0 + 0.996, 0.12, 0.15, "concrete", bev=0.03, segs=2)
    p.box(-1.0, -0.45, -0.02, 1.0, -0.15, 0.01, "concrete_dark", bev=0.01)
    return p


def utility_box():
    p = Piece("utility_box", 113)
    p.box(-0.45, -0.3, 0, 0.45, 0.3, 0.12, "concrete_dark", bev=0.015)
    p.box(-0.4, -0.25, 0.12, 0.4, 0.25, 1.35, "metal_panel", bev=0.03, segs=2)
    p.box(-0.42, -0.27, 1.35, 0.42, 0.27, 1.42, "metal_panel", bev=0.03)
    p.box(-0.36, -0.27, 0.2, -0.01, -0.25, 1.28, "metal_panel", bev=0.01)
    p.box(0.01, -0.27, 0.2, 0.36, -0.25, 1.28, "metal_panel", bev=0.01)
    p.box(-0.06, -0.29, 0.7, -0.03, -0.26, 0.85, "metal_dark")
    p.box(0.25, -0.28, 1.1, 0.33, -0.26, 1.16, "light_amber")
    for i in range(6):
        p.box(0.4, -0.18 + i * 0.06, 0.4, 0.41, -0.15 + i * 0.06, 0.9, "grate")
    return p


def barrier():
    p = Piece("barrier", 114)
    prof = [(-0.3, 0.0), (0.3, 0.0), (0.3, 0.08), (0.1, 0.25), (0.08, 0.8), (-0.08, 0.8), (-0.1, 0.25), (-0.3, 0.08)]
    p.prism_x(prof, -1.0, 1.0, "concrete", bev=0.02)
    for i in range(4):
        p.box(-0.995 + i * 0.5, -0.11, 0.5, -0.79 + i * 0.5, -0.08, 0.65, "paint_yellow")
    return p


def clutter_boxes():
    p = Piece("clutter_boxes", 115)
    p.box(-0.45, -0.35, 0, 0.15, 0.25, 0.45, "wood", bev=0.02)
    p.box(-0.4, -0.3, 0.45, 0.1, 0.2, 0.75, "wood", bev=0.015)
    p.box(0.2, -0.3, 0, 0.6, 0.15, 0.32, "plastic_dark", bev=0.02)
    p.box(0.25, -0.25, 0.32, 0.55, 0.1, 0.55, "fabric", bev=0.02)
    for (x, y, s) in ((-0.65, 0.1, 0.32), (0.75, 0.25, 0.28), (-0.2, 0.45, 0.3)):
        p.box(x - s, y - s * 0.9, 0, x + s, y + s * 0.9, s * 1.5, "plastic_dark", bev=s * 0.42, segs=2)
        p.cyl(x, y, s * 1.5 - 0.02, 0.04, 0.12, "plastic_dark", segs=6, r2=0.07)
    for i in range(5):
        p.box(-1.4 + i * 0.22, -0.5, 0.1, -1.28 + i * 0.22, 0.5, 0.13, "wood")
    for y in (-0.45, 0.0, 0.45):
        p.box(-1.42, y - 0.04, 0, -0.5, y + 0.04, 0.1, "wood")
    return p


def parking_meter():
    p = Piece("parking_meter", 116)
    p.cyl(0, 0, 0, 0.04, 1.1, "metal_dark", segs=8)
    p.box(-0.13, -0.09, 1.1, 0.13, 0.09, 1.5, "metal_panel", bev=0.03, segs=2)
    p.box(-0.09, -0.1, 1.32, 0.09, -0.08, 1.44, "screen", uvk_front=1)
    p.box(-0.04, -0.1, 1.18, 0.04, -0.085, 1.26, "light_amber")
    return p


def street_sign():
    p = Piece("street_sign", 117)
    p.cyl(0, 0, 0, 0.035, 3.2, "metal_bare", segs=8)
    p.box(-0.32, -0.03, 2.4, 0.32, 0.0, 3.0, "sign_face", uvk_front=1)
    p.box(-0.35, 0.0, 2.38, 0.35, 0.02, 3.02, "metal_bare")
    p.box(-0.04, -0.05, 2.7, 0.75, 0.0, 2.92, "sign_face", uvk_front=1)
    return p


def cable_span():
    """A sagging bundle of three cables (20 m) with a junction box; Godot also builds spans procedurally."""
    p = Piece("cable_span", 118)
    for k, (dy, dz, sag) in enumerate(((0, 0, 1.4), (0.15, -0.1, 1.7), (-0.12, 0.08, 1.2))):
        p.catenary((-10, dy, dz), (10, dy, dz), sag, 0.018 + 0.006 * k, "cable", n=24, segs=5)
    p.box(-0.15, -0.1, -1.6, 0.15, 0.1, -1.3, "metal_panel", bev=0.02)
    return p


def build_all(only=None):
    fns = [lamp_a, lamp_b, traffic_light, bollard, bin_a, hydrant, lambda: vending("vending_a", 107),
           lambda: vending("vending_b", 108, accent="sign_face"), kiosk_a, manhole, vent_street, curb,
           utility_box, barrier, clutter_boxes, parking_meter, street_sign, cable_span]
    for fn in fns:
        p = fn()
        if only and p.name not in only:
            continue
        build_and_export(p)
