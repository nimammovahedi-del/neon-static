# Regenerate the whole Neon Static model kit (one GLB per piece) into godot/assets/kit.
#   blender -b --factory-startup --python tools/blender/build_kit.py                 (everything)
#   blender -b --factory-startup --python tools/blender/build_kit.py -- facades      (one group)
#   blender -b --factory-startup --python tools/blender/build_kit.py -- piece=lamp_a (one piece)
# Groups: facades, street, signs, cars, roof, big (rail, train, towers), glyphs.
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kitlib
import kit_facades, kit_street, kit_signs, kit_cars, kit_roof, kit_big

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
groups = [a for a in argv if "=" not in a]
only = set()
for a in argv:
    if a.startswith("piece="):
        only.update(a[6:].split(","))
kitlib.reset()
mods = {"facades": kit_facades, "street": kit_street, "signs": kit_signs, "cars": kit_cars,
        "roof": kit_roof, "big": kit_big}
for name, mod in mods.items():
    if groups and name not in groups and not only:
        continue
    mod.build_all(only or None)
print("KIT DONE ->", kitlib.OUT)
