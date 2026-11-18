# Signs: blade signs, box signs, round signs, wall screen, holo emitter, rooftop letter frame,
# and neon tube glyphs (A-Z, 0-9 and a few invented shapes) built from a stroke font.
# Wall-mounted signs: wall plane y = 0, sign hangs out toward -Y.
from kitlib import Piece, build_and_export, rot_z, tr, export, reset
import bpy, math


def neon_outline(p, x, y0, y1, z0, z1, r=0.022, inset=0.06):
    """Rectangle of neon tube on the plane x = const."""
    pts = [(x, y0 + inset, z0 + inset), (x, y1 - inset, z0 + inset), (x, y1 - inset, z1 - inset), (x, y0 + inset, z1 - inset)]
    p.tube(pts, r, "neon", segs=6, closed=True)


def sign_blade_a():
    p = Piece("sign_blade_a", 201)
    t, y0, y1, h = 0.14, -1.05, -0.25, 4.0
    p.box(-t, y0, 0, t, y1, h, "sign_body", bev=0.03, segs=2)
    p.quad([(t + 0.004, y0 + 0.04, 0.06), (t + 0.004, y1 - 0.04, 0.06), (t + 0.004, y1 - 0.04, h - 0.06), (t + 0.004, y0 + 0.04, h - 0.06)], "sign_face", uvk=1)
    p.quad([(-t - 0.004, y1 - 0.04, 0.06), (-t - 0.004, y0 + 0.04, 0.06), (-t - 0.004, y0 + 0.04, h - 0.06), (-t - 0.004, y1 - 0.04, h - 0.06)], "sign_face", uvk=1)
    neon_outline(p, t + 0.03, y0, y1, 0, h, inset=0.0)
    neon_outline(p, -t - 0.03, y0, y1, 0, h, inset=0.0)
    for z in (0.35, h - 0.35):
        p.box(-0.03, y1, z - 0.04, 0.03, 0.0, z + 0.04, "metal_dark", bev=0.01)
        p.box(-0.08, -0.03, z - 0.12, 0.08, 0.0, z + 0.12, "metal_dark", bev=0.01)
    p.tube([(0, 0, 1.4), (0, y1 + 0.05, 0.4)], 0.02, "metal_dark", segs=5)
    # top cap light bar
    p.box(-t - 0.02, y0 - 0.02, h, t + 0.02, y1 + 0.02, h + 0.06, "metal_bare", bev=0.015)
    return p


def sign_blade_b():
    """Stack of lit cubes, one glyph per cube on three faces."""
    p = Piece("sign_blade_b", 202)
    s, n, gap = 0.78, 4, 0.08
    yc = -0.3 - s / 2
    for i in range(n):
        z = i * (s + gap)
        p.box(-s / 2, yc - s / 2, z, s / 2, yc + s / 2, z + s, "sign_body", bev=0.025)
        e = 0.004
        p.quad([(s / 2 + e, yc - s / 2 + 0.05, z + 0.05), (s / 2 + e, yc + s / 2 - 0.05, z + 0.05), (s / 2 + e, yc + s / 2 - 0.05, z + s - 0.05), (s / 2 + e, yc - s / 2 + 0.05, z + s - 0.05)], "sign_face", uvk=1, rnd=i / n)
        p.quad([(-s / 2 - e, yc + s / 2 - 0.05, z + 0.05), (-s / 2 - e, yc - s / 2 + 0.05, z + 0.05), (-s / 2 - e, yc - s / 2 + 0.05, z + s - 0.05), (-s / 2 - e, yc + s / 2 - 0.05, z + s - 0.05)], "sign_face", uvk=1, rnd=i / n)
        p.quad([(-s / 2 + 0.05, yc - s / 2 - e, z + 0.05), (s / 2 - 0.05, yc - s / 2 - e, z + 0.05), (s / 2 - 0.05, yc - s / 2 - e, z + s - 0.05), (-s / 2 + 0.05, yc - s / 2 - e, z + s - 0.05)], "sign_face", uvk=1, rnd=i / n)
    top = n * (s + gap)
    p.box(-0.05, -0.3, -0.1, 0.05, 0.0, top, "metal_dark", bev=0.01)
    p.box(-0.04, yc - 0.04, -0.1, 0.04, yc + 0.04, top + 0.3, "metal_bare")
    p.cyl(0, yc, top + 0.3, 0.06, 0.08, "blinker", segs=8)
    return p


def sign_box_a():
    p = Piece("sign_box_a", 203)
    w, h, d = 3.4, 0.9, 0.28
    p.box(-w / 2, -d - 0.05, 0, w / 2, -0.05, h, "sign_body", bev=0.03, segs=2)
    p.quad([(-w / 2 + 0.06, -d - 0.054, 0.06), (w / 2 - 0.06, -d - 0.054, 0.06), (w / 2 - 0.06, -d - 0.054, h - 0.06), (-w / 2 + 0.06, -d - 0.054, h - 0.06)], "sign_face", uvk=1)
    for x in (-w / 2 + 0.3, w / 2 - 0.3):
        p.box(x - 0.04, -0.06, 0.2, x + 0.04, 0.0, h - 0.2, "metal_dark")
    p.box(-w / 2 - 0.02, -d - 0.07, h - 0.02, w / 2 + 0.02, -0.04, h + 0.04, "metal_bare", bev=0.01)
    return p


def sign_box_b():
    """Projecting double-sided rounded box sign on a bracket arm."""
    p = Piece("sign_box_b", 204)
    L, h, t = 1.7, 0.75, 0.12
    y0, y1 = -0.35 - L, -0.35
    prof = [(y0 + 0.15, 0), (y1 - 0.15, 0), (y1, 0.15), (y1, h - 0.15), (y1 - 0.15, h), (y0 + 0.15, h), (y0, h - 0.15), (y0, 0.15)]
    # body as an X-extruded profile (profile in y,z)
    p.prism_x([(a, b) for a, b in prof], -t, t, "sign_body", bev=0.02)
    e = 0.005
    p.quad([(t + e, y0 + 0.08, 0.08), (t + e, y1 - 0.08, 0.08), (t + e, y1 - 0.08, h - 0.08), (t + e, y0 + 0.08, h - 0.08)], "sign_face", uvk=1)
    p.quad([(-t - e, y1 - 0.08, 0.08), (-t - e, y0 + 0.08, 0.08), (-t - e, y0 + 0.08, h - 0.08), (-t - e, y1 - 0.08, h - 0.08)], "sign_face", uvk=1)
    p.tube([(0, 0, h + 0.25), (0, y0 + 0.2, h + 0.25)], 0.03, "metal_dark", segs=6)
    p.tube([(0, 0, h - 0.4), (0, -0.9, h + 0.22)], 0.02, "metal_dark", segs=5)
    for y in (y0 + 0.25, y1 - 0.15):
        p.tube([(0, y, h + 0.25), (0, y, h)], 0.01, "metal_dark", segs=4)
    p.box(-0.08, -0.04, h - 0.5, 0.08, 0.0, h + 0.35, "metal_dark", bev=0.01)
    return p


def sign_round_a():
    p = Piece("sign_round_a", 205)
    r, t = 0.55, 0.12
    yc = -0.35 - r
    p.cyl(-t, yc, 0.8, r, 2 * t, "sign_body", axis='X', segs=24, bev=0.02)
    p.cyl(t, yc, 0.8, r - 0.05, 0.006, "sign_face", axis='X', segs=24, uvk=1)
    p.cyl(-t - 0.006, yc, 0.8, r - 0.05, 0.006, "sign_face", axis='X', segs=24, uvk=1)
    ring = [(t + 0.03, yc + (r - 0.02) * math.cos(a * math.pi / 12), 0.8 + (r - 0.02) * math.sin(a * math.pi / 12)) for a in range(24)]
    p.tube(ring, 0.018, "neon", segs=5, closed=True)
    ring = [(-t - 0.03, yc + (r - 0.02) * math.cos(a * math.pi / 12), 0.8 + (r - 0.02) * math.sin(a * math.pi / 12)) for a in range(24)]
    p.tube(ring, 0.018, "neon", segs=5, closed=True)
    p.tube([(0, 0, 0.8 + r + 0.1), (0, yc, 0.8 + r + 0.1)], 0.03, "metal_dark", segs=6)
    p.tube([(0, yc, 0.8 + r + 0.1), (0, yc, 0.8 + r)], 0.02, "metal_dark", segs=6)
    p.box(-0.07, -0.04, 0.8 + r - 0.2, 0.07, 0.0, 0.8 + r + 0.3, "metal_dark", bev=0.01)
    return p


def screen_wall():
    """Big wall-mounted LED screen 12 x 6.75 m with service frame and lamps."""
    p = Piece("screen_wall", 206)
    w, h = 12.0, 6.75
    p.box(-w / 2 - 0.25, -0.6, -0.25, w / 2 + 0.25, -0.1, h + 0.25, "metal_dark", bev=0.06, segs=2)
    p.quad([(-w / 2, -0.61, 0), (w / 2, -0.61, 0), (w / 2, -0.61, h), (-w / 2, -0.61, h)], "screen", uvk=1)
    for i in range(7):
        x = -w / 2 + i * w / 6
        p.box(x - 0.06, -0.1, -0.2, x + 0.06, 0.0, h + 0.2, "metal_bare")
    # catwalk underneath
    p.box(-w / 2, -1.5, -0.45, w / 2, -0.4, -0.38, "grate")
    railing_x(p, -w / 2, w / 2, -1.5, -0.38)
    for x in (-w / 2 + 1, 0, w / 2 - 1):
        p.box(x - 0.1, -1.6, -0.6, x + 0.1, -1.4, -0.42, "metal_dark")
        p.box(x - 0.15, -1.8, -0.45, x + 0.15, -1.55, -0.3, "lamp_lens")
    return p


def railing_x(p, x0, x1, y, z, h=0.9):
    n = int((x1 - x0) / 1.0)
    for i in range(n + 1):
        x = x0 + (x1 - x0) * i / n
        p.box(x - 0.02, y - 0.02, z, x + 0.02, y + 0.02, z + h, "metal_dark")
    p.box(x0, y - 0.025, z + h - 0.03, x1, y + 0.025, z + h + 0.02, "metal_dark")
    p.box(x0, y - 0.01, z + h * 0.5 - 0.01, x1, y + 0.01, z + h * 0.5 + 0.01, "metal_dark")


def holo_emitter():
    """Projector bar for a hologram panel; the light plane itself is made in Godot."""
    p = Piece("holo_emitter", 207)
    w = 6.0
    p.box(-w / 2, -0.35, -0.25, w / 2, 0.0, 0.0, "metal_dark", bev=0.04, segs=2)
    p.box(-w / 2 + 0.1, -0.36, -0.05, w / 2 - 0.1, -0.3, 0.0, "holo")
    for i in range(7):
        x = -w / 2 + 0.5 + i * (w - 1) / 6
        p.cyl(x, -0.2, 0.0, 0.08, 0.06, "holo", segs=10)
        p.cyl(x, -0.2, -0.1, 0.11, 0.1, "metal_bare", segs=10)
    for x in (-w / 2 + 0.3, w / 2 - 0.3):
        p.box(x - 0.05, -0.1, -0.25, x + 0.05, 0.0, 0.0, "metal_bare")
    return p


def sign_frame_roof():
    """Rooftop lattice frame for big neon letters (letters are placed by Godot)."""
    p = Piece("sign_frame_roof", 208)
    w, h = 12.0, 3.6
    for x in (-w / 2, -w / 4, 0, w / 4, w / 2):
        p.box(x - 0.08, 0.3, 0, x + 0.08, 0.46, h, "metal_dark", bev=0.02)
        p.tube([(x, 0.38, 0), (x, 2.2, 0)], 0.05, "metal_dark", segs=6)
        p.tube([(x, 2.2, 0.05), (x, 0.38, h * 0.8)], 0.05, "metal_dark", segs=6)
    for z in (0.3, h / 2, h - 0.15):
        p.box(-w / 2, 0.3, z - 0.06, w / 2, 0.46, z + 0.06, "metal_dark", bev=0.015)
    for i in range(8):
        a = -w / 2 + i * w / 8
        p.tube([(a, 0.38, 0.3), (a + w / 8, 0.38, h - 0.15)], 0.025, "metal_dark", segs=4)
    p.box(-w / 2, -0.3, -0.1, w / 2, 0.6, 0.0, "grate")
    for x in (-4.5, -1.5, 1.5, 4.5):
        p.box(x - 0.15, -0.6, 0.0, x + 0.15, -0.3, 0.2, "metal_dark", bev=0.02)
        p.box(x - 0.12, -0.62, 0.05, x + 0.12, -0.6, 0.18, "lamp_lens")
    return p


from glyphs import GLYPHS, arc


def build_glyphs():
    """All glyphs in one GLB; objects named g_<glyph>, 1 m tall, origin bottom-left, facing -Y."""
    for o in list(bpy.context.scene.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    objs = []
    for name, (w, strokes) in GLYPHS.items():
        p = Piece("g_" + name, 300)
        for s in strokes:
            closed = len(s) > 3 and abs(s[0][0] - s[-1][0]) < 1e-3 and abs(s[0][1] - s[-1][1]) < 1e-3
            pts = [(x, 0.0, y) for x, y in (s[:-1] if closed else s)]
            p.tube(pts, 0.034, "neon", segs=8, closed=closed, caps=not closed)
        ob = p.to_object()
        ob["glyph_width"] = w
        objs.append(ob)
    path = export(objs, "neon_glyphs")
    print("KIT %-28s glyphs=%d  %s" % ("neon_glyphs", len(objs), path))
    for o in objs:
        me = o.data
        bpy.data.objects.remove(o, do_unlink=True)
        bpy.data.meshes.remove(me)


def glyph_widths():
    return {k: v[0] for k, v in GLYPHS.items()}


def build_all(only=None):
    fns = [sign_blade_a, sign_blade_b, sign_box_a, sign_box_b, sign_round_a, screen_wall, holo_emitter, sign_frame_roof]
    for fn in fns:
        p = fn()
        if only and p.name not in only:
            continue
        build_and_export(p)
    if not only or "neon_glyphs" in only:
        build_glyphs()
        # also write the glyph widths for Godot
        import os, json
        from kitlib import OUT
        with open(os.path.join(OUT, "neon_glyphs.json"), "w") as f:
            json.dump(glyph_widths(), f, indent=0)
