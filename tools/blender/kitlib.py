# Neon Static kit library: small helpers for building bevelled low-poly pieces with bmesh
# and exporting each piece as its own GLB into godot/assets/kit.
#
# Conventions (Blender space, metres):
#   * Z is up. The "front" of a piece faces -Y (this becomes +Z in Godot after glTF export).
#   * Facade modules: x in [-W/2, W/2], z in [0, H], wall plane at y = 0, protrusions go to -Y.
#   * Material NAMES are roles ("concrete", "glass_window", "neon", ...). Godot swaps every
#     material by name for its own shader (godot/scripts/kit.gd), so colours here are only
#     a preview.
#   * Faces made with uvk=1 get UV 0..1 across the face (for windows, sign faces, screens)
#     and UV2 = face size in metres. Every face gets a random value in vertex colour R
#     (one value per primitive), used by shaders for per-window / per-part variation.
import bpy, bmesh, math, random, os
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "..", "godot", "assets", "kit"))

PREVIEW = {
    "concrete": (0.45, 0.44, 0.42), "concrete_dark": (0.25, 0.25, 0.25), "brick": (0.42, 0.2, 0.14),
    "tile": (0.55, 0.6, 0.58), "metal_panel": (0.35, 0.38, 0.4), "metal_dark": (0.08, 0.08, 0.09),
    "metal_bare": (0.5, 0.5, 0.5), "metal_rust": (0.35, 0.2, 0.12), "glass_window": (0.05, 0.08, 0.1),
    "glass_shop": (0.3, 0.4, 0.45), "glass_car": (0.03, 0.04, 0.05), "interior": (0.8, 0.75, 0.6),
    "interior_dark": (0.15, 0.13, 0.12), "shop_light": (1, 0.95, 0.85), "sign_face": (0.9, 0.2, 0.6),
    "sign_body": (0.06, 0.06, 0.07), "neon": (1, 0.2, 0.8), "lamp_lens": (1, 0.85, 0.6),
    "light_head": (1, 1, 0.95), "light_tail": (1, 0.05, 0.05), "light_amber": (1, 0.5, 0.0),
    "car_paint": (0.2, 0.22, 0.25), "rubber": (0.03, 0.03, 0.03), "chrome": (0.8, 0.8, 0.8),
    "plastic_dark": (0.05, 0.05, 0.05), "screen": (0.1, 0.4, 0.9), "holo": (0.2, 0.9, 1.0),
    "led_strip": (0.3, 0.9, 1.0), "blinker": (1, 0, 0), "fabric": (0.5, 0.1, 0.1),
    "grate": (0.1, 0.1, 0.1), "asphalt": (0.05, 0.05, 0.05), "paving": (0.3, 0.3, 0.3),
    "tower_glass": (0.1, 0.12, 0.15), "signal_red": (1, 0, 0), "signal_green": (0, 1, 0.4),
    "signal_amber": (1, 0.6, 0), "vend_panel": (0.9, 0.9, 1.0), "paint_yellow": (0.9, 0.7, 0.1),
    "lantern": (1, 0.2, 0.1), "goods": (0.9, 0.5, 0.2), "cable": (0.02, 0.02, 0.02), "wood": (0.3, 0.2, 0.12),
}


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def get_mat(name):
    m = bpy.data.materials.get(name)
    if m is None:
        m = bpy.data.materials.new(name)
        c = PREVIEW.get(name, (0.6, 0.6, 0.6))
        m.diffuse_color = (c[0], c[1], c[2], 1.0)
    return m


def rot_z(deg):
    return Matrix.Rotation(math.radians(deg), 4, 'Z')


def rot_x(deg):
    return Matrix.Rotation(math.radians(deg), 4, 'X')


def rot_y(deg):
    return Matrix.Rotation(math.radians(deg), 4, 'Y')


def tr(x, y, z):
    return Matrix.Translation((x, y, z))


class Piece:
    """One exported model. Primitives are added into a single bmesh with material slots."""

    def __init__(self, name, seed=1):
        self.name = name
        self.bm = bmesh.new()
        self.mats = []
        self.uvk = self.bm.faces.layers.int.new("uvk")
        self.rnd = self.bm.faces.layers.float.new("rnd")
        self.M = Matrix.Identity(4)
        self.stack = []
        self.rng = random.Random(seed)
        self.children = []  # extra separate objects (e.g. car wheels): (name, Piece)

    # ---- transform stack -------------------------------------------------
    def push(self, m):
        self.stack.append(self.M.copy())
        self.M = self.M @ m

    def pop(self):
        self.M = self.stack.pop()

    # ---- helpers ---------------------------------------------------------
    def mi(self, name):
        if name not in self.mats:
            self.mats.append(name)
        return self.mats.index(name)

    def _tag(self, faces, mat, uvk=0, rnd=None):
        idx = self.mi(mat)
        r = self.rng.random() if rnd is None else rnd
        for f in faces:
            f.material_index = idx
            f[self.uvk] = uvk
            f[self.rnd] = r

    def _bevel(self, verts, edges, w, segs=1):
        if w <= 0:
            return []
        res = bmesh.ops.bevel(self.bm, geom=list(verts) + list(edges), offset=w, offset_type='OFFSET',
                              segments=segs, profile=0.5, affect='EDGES', clamp_overlap=True,
                              harden_normals=False)
        return res.get("faces", [])

    def box(self, x0, y0, z0, x1, y1, z1, mat, bev=0.0, segs=1, uvk=0, rnd=None, uvk_front=None):
        """Axis-aligned box (in the current transform). uvk_front: give the -Y face its own uv kind."""
        if x0 > x1: x0, x1 = x1, x0
        if y0 > y1: y0, y1 = y1, y0
        if z0 > z1: z0, z1 = z1, z0
        bev = min(bev, (x1 - x0) * 0.45, (y1 - y0) * 0.45, (z1 - z0) * 0.45)
        P = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
             (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]
        v = [self.bm.verts.new(self.M @ Vector(p)) for p in P]
        F = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
        faces = [self.bm.faces.new([v[i] for i in f]) for f in F]
        r = self.rng.random() if rnd is None else rnd
        self._tag(faces, mat, uvk, r)
        if uvk_front is not None:
            faces[2][self.uvk] = uvk_front
        edges = set()
        for f in faces:
            for e in f.edges:
                edges.add(e)
        nf = self._bevel(v, list(edges), bev, segs)
        for f in nf:
            if f.is_valid:
                f.material_index = self.mi(mat)
                f[self.uvk] = 0
                f[self.rnd] = r
        return faces

    def boxc(self, cx, cy, cz, sx, sy, sz, mat, **kw):
        """Box from centre + size."""
        return self.box(cx - sx / 2, cy - sy / 2, cz - sz / 2, cx + sx / 2, cy + sy / 2, cz + sz / 2, mat, **kw)

    def quad(self, pts, mat, uvk=1, rnd=None):
        v = [self.bm.verts.new(self.M @ Vector(p)) for p in pts]
        f = self.bm.faces.new(v)
        self._tag([f], mat, uvk, rnd)
        return f

    def cyl(self, x, y, z, r, h, mat, axis='Z', segs=12, r2=None, caps=True, bev=0.0, rnd=None, uvk=0):
        """Cylinder whose base centre is at (x,y,z) and which extends h along +axis."""
        m = self.M @ tr(x, y, z)
        if axis == 'X':
            m = m @ rot_y(90)
        elif axis == 'Y':
            m = m @ rot_x(-90)
        m = m @ tr(0, 0, h / 2)
        res = bmesh.ops.create_cone(self.bm, cap_ends=caps, cap_tris=False, segments=segs,
                                    radius1=r, radius2=(r if r2 is None else r2), depth=h, matrix=m)
        verts = res["verts"]
        faces = list({f for vv in verts for f in vv.link_faces})
        rr = self.rng.random() if rnd is None else rnd
        self._tag(faces, mat, uvk, rr)
        if bev > 0 and caps:
            edges = [e for e in {e for vv in verts for e in vv.link_edges}
                     if len(e.link_faces) == 2 and e.calc_face_angle(0) > math.radians(60)]
            nf = self._bevel(list({vv for e in edges for vv in e.verts}), edges, bev, 1)
            for f in nf:
                if f.is_valid:
                    f.material_index = self.mi(mat)
                    f[self.rnd] = rr
        return faces

    def tube(self, pts, r, mat, segs=8, caps=True, closed=False, rnd=None, uvk=0, flat_up=None):
        """Sweep a circle of radius r along a polyline (pipes, rails, neon tubes, cables)."""
        pts = [Vector(p) for p in pts]
        n = len(pts)
        if n < 2:
            return []
        rings = []
        prev_side = None
        for i, p in enumerate(pts):
            if closed:
                a = pts[(i - 1) % n]; b = pts[(i + 1) % n]
                t = ((p - a).normalized() + (b - p).normalized())
            else:
                if i == 0:
                    t = pts[1] - p
                elif i == n - 1:
                    t = p - pts[i - 1]
                else:
                    t = (p - pts[i - 1]).normalized() + (pts[i + 1] - p).normalized()
            if t.length < 1e-6:
                t = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)])
            t.normalize()
            # parallel transport of the side vector
            if prev_side is None:
                up = Vector((0, 0, 1)) if abs(t.z) < 0.9 else Vector((1, 0, 0))
                side = t.cross(up).normalized()
            else:
                side = (prev_side - t * prev_side.dot(t))
                if side.length < 1e-6:
                    up = Vector((0, 0, 1)) if abs(t.z) < 0.9 else Vector((1, 0, 0))
                    side = t.cross(up)
                side.normalize()
            prev_side = side
            up2 = side.cross(t).normalized()
            # miter at joints: stretch the ring along the bend direction by 1/cos(half angle)
            scale = 1.0
            bend = None
            if 0 < i < n - 1 or closed:
                a = pts[(i - 1) % n]; b = pts[(i + 1) % n]
                d1 = (p - a).normalized(); d2 = (b - p).normalized()
                c = max(0.35, d1.dot(t))
                scale = 1.0 / c
                bend = (d2 - d1)
                bend = bend - t * bend.dot(t)
                if bend.length < 1e-6:
                    bend = None
                else:
                    bend.normalize()
            ring = []
            for k in range(segs):
                ang = 2 * math.pi * k / segs
                off = side * math.cos(ang) * r + up2 * math.sin(ang) * r
                if bend is not None and scale != 1.0:
                    off = off + bend * (off.dot(bend) * (scale - 1.0))
                ring.append(self.bm.verts.new(self.M @ (p + off)))
            rings.append(ring)
        faces = []
        rng = range(n) if closed else range(n - 1)
        for i in rng:
            A = rings[i]; B = rings[(i + 1) % n]
            for k in range(segs):
                k2 = (k + 1) % segs
                faces.append(self.bm.faces.new([A[k], B[k], B[k2], A[k2]]))
        if caps and not closed:
            faces.append(self.bm.faces.new(rings[0]))
            faces.append(self.bm.faces.new(list(reversed(rings[-1]))))
        self._tag(faces, mat, uvk, rnd)
        return faces

    def prism(self, poly, z0, z1, mat, bev=0.0, rnd=None, uvk=0):
        """Extrude a convex-or-concave 2D polygon (x,y list, CCW from above) from z0 to z1."""
        n = len(poly)
        bot = [self.bm.verts.new(self.M @ Vector((p[0], p[1], z0))) for p in poly]
        top = [self.bm.verts.new(self.M @ Vector((p[0], p[1], z1))) for p in poly]
        faces = [self.bm.faces.new(list(reversed(bot))), self.bm.faces.new(top)]
        for i in range(n):
            j = (i + 1) % n
            faces.append(self.bm.faces.new([bot[i], bot[j], top[j], top[i]]))
        rr = self.rng.random() if rnd is None else rnd
        self._tag(faces, mat, uvk, rr)
        if bev > 0:
            edges = list({e for f in faces for e in f.edges})
            nf = self._bevel(bot + top, edges, bev, 1)
            for f in nf:
                if f.is_valid:
                    f.material_index = self.mi(mat)
                    f[self.rnd] = rr
        return faces

    def prism_x(self, poly_yz, x0, x1, mat, bev=0.0, rnd=None):
        """Extrude a 2D profile given in (y,z) along X from x0 to x1 (car bodies, girders)."""
        n = len(poly_yz)
        a = [self.bm.verts.new(self.M @ Vector((x0, p[0], p[1]))) for p in poly_yz]
        b = [self.bm.verts.new(self.M @ Vector((x1, p[0], p[1]))) for p in poly_yz]
        faces = [self.bm.faces.new(a), self.bm.faces.new(list(reversed(b)))]
        for i in range(n):
            j = (i + 1) % n
            faces.append(self.bm.faces.new([a[j], a[i], b[i], b[j]]))
        rr = self.rng.random() if rnd is None else rnd
        self._tag(faces, mat, 0, rr)
        bmesh.ops.recalc_face_normals(self.bm, faces=faces)
        if bev > 0:
            edges = list({e for f in faces for e in f.edges})
            nf = self._bevel(a + b, edges, bev, 1)
            for f in nf:
                if f.is_valid:
                    f.material_index = self.mi(mat)
                    f[self.rnd] = rr
        return faces

    def catenary(self, p0, p1, sag, r, mat, n=16, segs=5):
        p0 = Vector(p0); p1 = Vector(p1)
        pts = []
        for i in range(n + 1):
            t = i / n
            p = p0.lerp(p1, t)
            p.z -= sag * 4 * t * (1 - t)
            pts.append(p)
        return self.tube(pts, r, mat, segs=segs, caps=False)

    # ---- finishing ---------------------------------------------------------
    def to_object(self, name=None):
        bm = self.bm
        bm.normal_update()  # faces added after the last bevel have stale normals
        # sharp edges above ~50 degrees, smooth (hardened by weighted normals) below
        for e in bm.edges:
            if len(e.link_faces) != 2:
                e.smooth = False
            else:
                e.smooth = e.calc_face_angle(0) < math.radians(50)
        for f in bm.faces:
            f.smooth = True
        uv = bm.loops.layers.uv.new("UVMap")
        uv2 = bm.loops.layers.uv.new("UV2")
        col = bm.loops.layers.float_color.new("Col")
        for f in bm.faces:
            n = f.normal
            k = f[self.uvk]
            r = f[self.rnd]
            an = (abs(n.x), abs(n.y), abs(n.z))
            if k == 1:
                # face-local 0..1 UV: u = horizontal tangent, v = up (or Y for flat faces)
                if an[2] > 0.9:
                    U = Vector((1, 0, 0)); V = Vector((0, 1 if n.z > 0 else -1, 0))
                else:
                    U = Vector((0, 0, 1)).cross(n).normalized(); V = n.cross(U).normalized()
                us = [l.vert.co.dot(U) for l in f.loops]; vs = [l.vert.co.dot(V) for l in f.loops]
                u0, u1, v0, v1 = min(us), max(us), min(vs), max(vs)
                du = max(u1 - u0, 1e-5); dv = max(v1 - v0, 1e-5)
                for l in f.loops:
                    l[uv].uv = ((l.vert.co.dot(U) - u0) / du, (l.vert.co.dot(V) - v0) / dv)
                    l[uv2].uv = (du, dv)
            elif k == 2:
                # metric per-face UV (towers): u along the face's horizontal tangent, v up, in metres
                if an[2] > 0.9:
                    U = Vector((1, 0, 0)); V = Vector((0, 1, 0))
                else:
                    U = Vector((0, 0, 1)).cross(n).normalized(); V = n.cross(U).normalized()
                for l in f.loops:
                    l[uv].uv = (l.vert.co.dot(U), l.vert.co.dot(V))
                    l[uv2].uv = (0.0, 0.0)
            else:
                for l in f.loops:
                    c = l.vert.co
                    if an[2] >= an[0] and an[2] >= an[1]:
                        l[uv].uv = (c.x, c.y)
                    elif an[0] >= an[1]:
                        l[uv].uv = (c.y, c.z)
                    else:
                        l[uv].uv = (c.x, c.z)
                    l[uv2].uv = (0.0, 0.0)
            for l in f.loops:
                l[col] = (r, float(k), 0.0, 1.0)
        me = bpy.data.meshes.new(name or self.name)
        bm.to_mesh(me)
        bm.free()
        for m in self.mats:
            me.materials.append(get_mat(m))
        ob = bpy.data.objects.new(name or self.name, me)
        bpy.context.scene.collection.objects.link(ob)
        mod = ob.modifiers.new("wn", 'WEIGHTED_NORMAL')
        mod.keep_sharp = True
        mod.mode = 'FACE_AREA'
        mod.weight = 50
        try:
            me.color_attributes.active_color = me.color_attributes["Col"]
            me.color_attributes.render_color_index = 0
        except Exception:
            pass
        return ob


def export(objs, name):
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    path = os.path.join(OUT, name + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True, export_apply=True,
                              export_yup=True, export_normals=True, export_texcoords=True,
                              export_vertex_color='ACTIVE', export_all_vertex_colors=False,
                              export_materials='EXPORT', export_tangents=False, export_attributes=False)
    return path


def build_and_export(piece, extra=()):
    """Turn a Piece (plus optional extra Pieces as child objects) into objects and export one GLB."""
    for o in list(bpy.context.scene.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    objs = [piece.to_object()]
    for p in extra:
        ob = p.to_object()
        ob.parent = objs[0]
        objs.append(ob)
    path = export(objs, piece.name)
    tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objs)
    print("KIT %-28s tris=%6d  %s" % (piece.name, tris, os.path.basename(path)))
    for o in objs:
        me = o.data
        bpy.data.objects.remove(o, do_unlink=True)
        bpy.data.meshes.remove(me)
    return path
