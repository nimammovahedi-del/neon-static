# Three stylised near-future cars with bevelled lofted bodies, wheel arches, glass cabins,
# light bars and separate wheel objects. Car front faces -Y (Godot +Z), origin on the ground.
from kitlib import Piece, build_and_export, tr, rot_z
import bmesh, math


def loft(p, prof, hw_fn, mat, bev=0.0, rnd=None):
    """Loft a side profile (y,z list, closed) across the car; half-width depends on z (tumblehome)."""
    n = len(prof)
    a = [p.bm.verts.new(p.M @ __import__("mathutils").Vector((-hw_fn(z, y), y, z))) for (y, z) in prof]
    b = [p.bm.verts.new(p.M @ __import__("mathutils").Vector((hw_fn(z, y), y, z))) for (y, z) in prof]
    faces = [p.bm.faces.new(a), p.bm.faces.new(list(reversed(b)))]
    for i in range(n):
        j = (i + 1) % n
        faces.append(p.bm.faces.new([a[j], a[i], b[i], b[j]]))
    rr = p.rng.random() if rnd is None else rnd
    p._tag(faces, mat, 0, rr)
    bmesh.ops.recalc_face_normals(p.bm, faces=faces)
    if bev > 0:
        edges = [e for e in {e for f in faces for e in f.edges} if e.calc_face_angle(0) > math.radians(25)]
        nf = p._bevel(list({v for e in edges for v in e.verts}), edges, bev, 2)
        for f in nf:
            if f.is_valid:
                f.material_index = p.mi(mat)
                f[p.rnd] = rr
    return faces


def arch_pts(cy, cz, r, y_from, y_to, n=8):
    """Points along a wheel arch from the y_from side over the top to the y_to side."""
    a0 = 0 if y_from > cy else 180
    a1 = 180 if a0 == 0 else 0
    return [(cy + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)), cz + r * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]


def wheel(name, r=0.34, w=0.24, seed=5):
    p = Piece(name, seed)
    p.cyl(-w / 2, 0, 0, r, w, "rubber", axis='X', segs=18, bev=0.04)
    p.cyl(-w / 2 - 0.005, 0, 0, r * 0.66, 0.01, "metal_dark", axis='X', segs=18)
    p.cyl(w / 2 - 0.005, 0, 0, r * 0.66, 0.01, "metal_dark", axis='X', segs=18)
    for s in (-1, 1):
        x = s * (w / 2 + 0.006)
        for k in range(5):
            ang = k * 2 * math.pi / 5
            p.tube([(x, 0.05 * math.cos(ang), 0.05 * math.sin(ang)), (x, r * 0.6 * math.cos(ang + 0.25), r * 0.6 * math.sin(ang + 0.25))], 0.022, "chrome", segs=4)
        p.cyl(x - 0.01 * s, 0, 0, 0.06, 0.02, "chrome", axis='X', segs=10)
    return p


def add_wheels(p, positions, r=0.34, w=0.24):
    # wheel meshes are baked at their hub position (separate objects named wheel_0..3)
    out = []
    for i, (x, y, z) in enumerate(positions):
        wp = Piece("wheel_%d" % i, 50 + i)
        wp.push(tr(x, y, z))
        wp.cyl(-w / 2, 0, 0, r, w, "rubber", axis='X', segs=18, bev=0.04)
        side = 1 if x > 0 else -1
        xo = side * (w / 2 + 0.006)
        wp.cyl(xo - 0.005 * side - 0.005, 0, 0, r * 0.68, 0.012, "metal_dark", axis='X', segs=18)
        for k in range(6):
            ang = k * 2 * math.pi / 6
            wp.tube([(xo, 0.06 * math.cos(ang), 0.06 * math.sin(ang)), (xo, r * 0.62 * math.cos(ang + 0.3), r * 0.62 * math.sin(ang + 0.3))], 0.02, "chrome", segs=4)
        wp.cyl(xo - 0.01, 0, 0, 0.065, 0.025, "chrome", axis='X', segs=10)
        # brake disc glimpse
        wp.cyl(-side * 0.02 + xo * 0.5 - 0.01, 0, 0, r * 0.5, 0.02, "metal_bare", axis='X', segs=14)
        out.append(wp)
    return out


def car_sedan():
    p = Piece("car_sedan", 401)
    L = 2.35
    fa, ra = (-1.42, 0.34), (1.45, 0.34)
    R = 0.41
    prof = [(-2.3, 0.28), (-2.42, 0.5), (-2.36, 0.72), (-2.1, 0.82), (-1.15, 0.93), (1.65, 0.97), (2.25, 0.93), (2.4, 0.7),
            (2.36, 0.42), (2.25, 0.27)]
    prof += arch_pts(ra[0], ra[1], R, 2.0, 0.9, 9)[1:]
    prof += [(0.95, 0.22), (-0.92, 0.22)]
    prof += arch_pts(fa[0], fa[1], R, -0.9, -2.0, 9)[1:]
    hw = lambda z, y: 0.93 - max(0, z - 0.75) * 0.25 - max(0, 0.4 - z) * 0.18 - max(0, abs(y) - 2.0) * 0.25
    loft(p, prof, hw, "car_paint", bev=0.045)
    # wheel wells (dark liners so the arches never show daylight)
    for (cy, cz) in (fa, ra):
        p.cyl(-0.8, cy, cz, R - 0.01, 1.6, "plastic_dark", axis='X', segs=14)
    # cabin
    cab = [(-1.12, 0.92), (-0.32, 1.39), (0.78, 1.41), (1.68, 0.96)]
    cab_hw = lambda z, y: 0.86 - (z - 0.92) * 0.32
    loft(p, cab, cab_hw, "glass_car", bev=0.02)
    roof = [(-0.3, 1.39), (0.78, 1.41), (0.72, 1.425), (-0.26, 1.405)]
    loft(p, roof, lambda z, y: 0.72, "car_paint", bev=0.008)
    # pillars
    for s in (-1, 1):
        p.tube([(s * 0.85, -1.1, 0.93), (s * 0.71, -0.32, 1.39)], 0.035, "car_paint", segs=5)
        p.tube([(s * 0.86, 1.66, 0.97), (s * 0.71, 0.78, 1.41)], 0.05, "car_paint", segs=5)
        p.box(s * 0.84 - 0.03, 0.12, 0.93, s * 0.84 + 0.03, 0.26, 1.33, "car_paint")
        p.box(s * 0.84 - 0.025, -0.3, 0.92, s * 0.84 + 0.025, 1.6, 0.95, "chrome")
        # mirrors
        p.box(s * 0.95 - 0.08, -0.95, 0.9, s * 0.95 + 0.08, -0.8, 1.0, "car_paint", bev=0.02)
        # door seams + handles
        for y in (-0.88, 0.2, 1.05):
            p.box(s * 0.935 - 0.004, y - 0.006, 0.3, s * 0.935 + 0.004, y + 0.006, 0.9, "plastic_dark")
        for y in (-0.2, 0.8):
            p.box(s * 0.94 - 0.01, y - 0.09, 0.78, s * 0.94 + 0.01, y + 0.09, 0.81, "chrome")
        # side skirt
        p.box(s * 0.9 - 0.04, -0.92, 0.2, s * 0.9 + 0.04, 0.95, 0.3, "plastic_dark", bev=0.015)
    # light bars + bumpers
    p.box(-0.82, -2.43, 0.66, 0.82, -2.33, 0.72, "light_head", bev=0.012)
    p.box(-0.9, -2.44, 0.4, 0.9, -2.3, 0.55, "plastic_dark", bev=0.02)
    p.box(-0.5, -2.45, 0.43, 0.5, -2.42, 0.52, "grate")
    p.box(-0.85, 2.33, 0.78, 0.85, 2.43, 0.84, "light_tail", bev=0.012)
    p.box(-0.88, 2.34, 0.4, 0.88, 2.42, 0.55, "plastic_dark", bev=0.02)
    p.box(-0.25, 2.42, 0.58, 0.25, 2.44, 0.72, "metal_bare")
    for s in (-1, 1):
        p.box(s * 0.86 - 0.06, -2.38, 0.6, s * 0.86 + 0.06, -2.3, 0.66, "light_amber")
    p.box(-0.85, -2.0, 0.12, 0.85, 2.0, 0.24, "plastic_dark")
    wheels = add_wheels(p, [(-0.8, fa[0], fa[1]), (0.8, fa[0], fa[1]), (-0.8, ra[0], ra[1]), (0.8, ra[0], ra[1])])
    return p, wheels


def car_van():
    p = Piece("car_van", 402)
    fa, ra = (-1.55, 0.37), (1.5, 0.37)
    R = 0.44
    prof = [(-2.45, 0.3), (-2.55, 0.55), (-2.5, 0.95), (-2.1, 1.25), (-1.45, 1.95), (2.35, 2.0), (2.45, 1.9), (2.5, 0.4), (2.4, 0.3)]
    prof += arch_pts(ra[0], ra[1], R, 2.0, 1.0, 9)[1:]
    prof += [(1.0, 0.25), (-1.05, 0.25)]
    prof += arch_pts(fa[0], fa[1], R, -1.05, -2.1, 9)[1:]
    hw = lambda z, y: 0.98 - max(0, z - 1.3) * 0.12 - max(0, 0.4 - z) * 0.15
    loft(p, prof, hw, "car_paint", bev=0.06)
    for (cy, cz) in (fa, ra):
        p.cyl(-0.85, cy, cz, R - 0.01, 1.7, "plastic_dark", axis='X', segs=14)
    # windshield + side windows as glass panels slightly proud of the body
    p.quad([(-0.86, -2.08, 1.3), (0.86, -2.08, 1.3), (0.8, -1.5, 1.88), (-0.8, -1.5, 1.88)], "glass_car", uvk=1)
    p.quad([(-0.86, -2.085, 1.3), (-0.8, -1.505, 1.88), (0.8, -1.505, 1.88), (0.86, -2.085, 1.3)], "glass_car", uvk=1)
    for s in (-1, 1):
        x = s * (hw(1.5, 0) + 0.004)
        ys = [(-1.95, -1.0), (-0.85, 0.3)]
        for (ya, yb) in ys:
            q = [(x, ya, 1.25), (x, yb, 1.25), (x, yb, 1.8), (x, ya, 1.8)]
            if s < 0:
                q = list(reversed(q))
            p.quad(q, "glass_car", uvk=1)
        p.box(s * 0.99 - 0.004, 0.45, 0.35, s * 0.99 + 0.004, 0.46, 1.85, "plastic_dark")
        p.box(s * 0.99 - 0.004, 1.95, 0.35, s * 0.99 + 0.004, 1.96, 1.85, "plastic_dark")
        p.box(s * 0.99 - 0.006, 0.3, 1.15, s * 0.99 + 0.006, 2.2, 1.19, "plastic_dark")
        p.box(s * 1.04 - 0.07, -1.9, 1.15, s * 1.04 + 0.07, -1.72, 1.4, "plastic_dark", bev=0.02)
        # graphic stripe panel (sign face for invented livery)
        q = [(s * 1.0, 0.55, 0.55), (s * 1.0, 2.25, 0.55), (s * 1.0, 2.25, 1.1), (s * 1.0, 0.55, 1.1)]
        if s < 0:
            q = list(reversed(q))
        p.quad(q, "sign_face", uvk=1)
    p.box(-0.85, -2.58, 0.75, 0.85, -2.48, 0.82, "light_head", bev=0.012)
    p.box(-0.95, -2.6, 0.35, 0.95, -2.42, 0.6, "plastic_dark", bev=0.03)
    p.box(-0.6, -2.59, 0.88, 0.6, -2.5, 1.12, "grate")
    for s in (-1, 1):
        p.box(s * 0.97 - 0.05, 2.46, 0.6, s * 0.97 + 0.05, 2.52, 1.85, "light_tail", bev=0.01)
    p.box(-0.95, 2.45, 0.3, 0.95, 2.55, 0.5, "plastic_dark", bev=0.02)
    p.box(-0.004, 2.5, 0.55, 0.004, 2.52, 1.9, "plastic_dark")
    # roof rack
    for y in (-1.2, 0.0, 1.2, 2.1):
        p.box(-0.85, y - 0.03, 2.0, 0.85, y + 0.03, 2.08, "metal_dark")
    for s in (-1, 1):
        p.box(s * 0.85 - 0.03, -1.3, 2.08, s * 0.85 + 0.03, 2.2, 2.12, "metal_dark")
    p.box(-0.55, -1.0, 2.08, 0.4, 0.4, 2.35, "plastic_dark", bev=0.03)
    p.box(-0.88, -2.0, 0.15, 0.88, 2.0, 0.27, "plastic_dark")
    wheels = add_wheels(p, [(-0.83, fa[0], fa[1]), (0.83, fa[0], fa[1]), (-0.83, ra[0], ra[1]), (0.83, ra[0], ra[1])], r=0.37, w=0.26)
    return p, wheels


def car_wedge():
    """Low wedge cab with a lit roof box."""
    p = Piece("car_wedge", 403)
    fa, ra = (-1.38, 0.33), (1.38, 0.33)
    R = 0.4
    prof = [(-2.2, 0.25), (-2.32, 0.42), (-2.25, 0.58), (-1.0, 0.86), (1.9, 0.98), (2.28, 0.95), (2.32, 0.5), (2.2, 0.26)]
    prof += arch_pts(ra[0], ra[1], R, 2.0, 0.9, 9)[1:]
    prof += [(0.92, 0.2), (-0.92, 0.2)]
    prof += arch_pts(fa[0], fa[1], R, -0.92, -1.95, 9)[1:]
    hw = lambda z, y: 0.95 - max(0, z - 0.7) * 0.3 - max(0, 0.35 - z) * 0.2 - max(0, -y - 1.6) * 0.15
    loft(p, prof, hw, "car_paint", bev=0.04)
    for (cy, cz) in (fa, ra):
        p.cyl(-0.8, cy, cz, R - 0.01, 1.6, "plastic_dark", axis='X', segs=14)
    cab = [(-1.0, 0.86), (0.0, 1.3), (1.1, 1.3), (1.9, 0.98)]
    loft(p, cab, lambda z, y: 0.86 - (z - 0.86) * 0.35, "glass_car", bev=0.02)
    loft(p, [(0.02, 1.3), (1.08, 1.3), (1.04, 1.32), (0.06, 1.32)], lambda z, y: 0.7, "car_paint", bev=0.006)
    for s in (-1, 1):
        p.tube([(s * 0.86, -0.98, 0.87), (s * 0.71, 0.02, 1.3)], 0.035, "car_paint", segs=5)
        p.tube([(s * 0.87, 1.88, 0.98), (s * 0.71, 1.08, 1.3)], 0.06, "car_paint", segs=5)
        p.box(s * 0.94 - 0.004, 0.45, 0.28, s * 0.94 + 0.004, 0.462, 0.9, "plastic_dark")
        p.box(s * 0.97 - 0.07, -0.85, 0.86, s * 0.97 + 0.07, -0.7, 0.95, "car_paint", bev=0.02)
        p.box(s * 0.93 - 0.02, -1.6, 0.52, s * 0.93 + 0.02, 1.7, 0.56, "led_strip")
    # roof box sign
    p.box(-0.32, 0.3, 1.32, 0.32, 0.8, 1.36, "metal_dark")
    p.box(-0.3, 0.38, 1.36, 0.3, 0.72, 1.62, "sign_body", bev=0.02)
    for s in (-1, 1):
        q = [(s * 0.305, 0.4, 1.38), (s * 0.305, 0.7, 1.38), (s * 0.305, 0.7, 1.6), (s * 0.305, 0.4, 1.6)]
        if s < 0:
            q = list(reversed(q))
        p.quad(q, "sign_face", uvk=1)
    p.quad([(-0.28, 0.375, 1.38), (0.28, 0.375, 1.38), (0.28, 0.375, 1.6), (-0.28, 0.375, 1.6)], "sign_face", uvk=1)
    p.box(-0.86, -2.3, 0.47, 0.86, -2.22, 0.52, "light_head", bev=0.01)
    p.box(-0.88, 2.26, 0.82, 0.88, 2.33, 0.9, "light_tail", bev=0.01)
    p.box(-0.88, 2.27, 0.3, 0.88, 2.34, 0.45, "plastic_dark", bev=0.02)
    p.box(-0.9, -2.33, 0.26, 0.9, -2.15, 0.4, "plastic_dark", bev=0.02)
    p.box(-0.82, -1.9, 0.1, 0.82, 1.9, 0.22, "plastic_dark")
    wheels = add_wheels(p, [(-0.81, fa[0], fa[1]), (0.81, fa[0], fa[1]), (-0.81, ra[0], ra[1]), (0.81, ra[0], ra[1])], r=0.33, w=0.25)
    return p, wheels


def build_all(only=None):
    for fn in (car_sedan, car_van, car_wedge):
        p, wheels = fn()
        if only and p.name not in only:
            continue
        build_and_export(p, extra=wheels)
