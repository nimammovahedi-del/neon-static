# Quick geometry check: import kit GLBs and render them in a grid with Workbench (no Godot needed).
#   blender -b --factory-startup --python tools/blender/preview.py -- out=/path/preview.png fac_concrete_a fac_brick_a ...
import bpy, sys, os, math
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
out = "/tmp/kit_preview.png"
names = []
cols = 4
for a in argv:
    if a.startswith("out="):
        out = a[4:]
    elif a.startswith("cols="):
        cols = int(a[5:])
    else:
        names.append(a)
KIT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "godot", "assets", "kit"))
if not names:
    names = sorted(f[:-4] for f in os.listdir(KIT) if f.endswith(".glb"))
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
x = 0.0
row = 0
col = 0
cell = []
maxd = 0
groups = []
for n in names:
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(KIT, n + ".glb"))
    new = [o for o in bpy.data.objects if o not in before]
    mn = Vector((1e9,) * 3); mx = Vector((-1e9,) * 3)
    for o in new:
        if o.type == 'MESH':
            for c in o.bound_box:
                w = o.matrix_world @ Vector(c)
                mn = Vector(map(min, mn, w)); mx = Vector(map(max, mx, w))
    groups.append((new, mn, mx))
    maxd = max(maxd, (mx - mn).length)
sp = maxd * 1.05
for i, (objs, mn, mx) in enumerate(groups):
    c = (mn + mx) / 2
    off = Vector(((i % cols) * sp - c.x, 0 - c.y, -(i // cols) * sp - mn.z))
    for o in objs:
        if o.parent is None:
            o.location += off
rows = (len(groups) + cols - 1) // cols
cam = bpy.data.cameras.new("cam")
cam.type = 'ORTHO'
cam.ortho_scale = max(cols, rows * 1.6) * sp * 1.05
co = bpy.data.objects.new("cam", cam)
sc.collection.objects.link(co)
cx = (cols - 1) * sp / 2
cz = -(rows - 1) * sp / 2 + sp * 0.4
d = Vector((0.55, -1.0, 0.35)).normalized()
co.location = Vector((cx, 0, cz)) + d * 200
co.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
sc.camera = co
sc.render.engine = 'BLENDER_WORKBENCH'
sc.display.shading.light = 'STUDIO'
sc.display.shading.color_type = 'MATERIAL'
sc.display.shading.show_cavity = True
sc.display.shading.cavity_type = 'BOTH'
sc.display.shading.show_shadows = True
sc.render.resolution_x = 1800
sc.render.resolution_y = int(1800 * rows * 1.6 / cols * 0.62) if cols >= rows * 1.6 else 1800
sc.render.resolution_y = max(600, min(2400, sc.render.resolution_y))
sc.render.filepath = out
bpy.ops.render.render(write_still=True)
print("PREVIEW", out)
