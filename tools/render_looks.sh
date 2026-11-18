#!/bin/sh
# Render look-test stills of the Neon Static street (1920x1080) through the shared Godot slots.
#   sh tools/render_looks.sh N            render one look (preset godot/looks/N.gd) -> docs/looks/neutral.png
#   sh tools/render_looks.sh A C F        render several looks                   -> docs/looks/look_A.png ...
#   sh tools/render_looks.sh all          every preset in godot/looks + docs/looks/contact_sheet.png
#   sh tools/render_looks.sh kit          the kit sheet                            -> docs/looks/kit_sheet.png
# Options (environment variables):
#   FRAMES=150   frames to let the scene settle before the capture (fog, particles, reflections)
#   SS=1.5       3D supersampling factor (1.0 is faster; 2.0 is sharper but heavy)
#   W=1920 H=1080  output size;  OUT_DIR=docs/looks
# Every Godot run goes through tools/gslot.sh (max two Godot copies on this Mac, shared with Umbara).
# An empty log usually means the slot wait timed out: just run again.
cd "$(dirname "$0")/.." || exit 1
ROOT=$(pwd)
FRAMES=${FRAMES:-150}
SS=${SS:-1.5}
W=${W:-1920}
H=${H:-1080}
OUT_DIR=${OUT_DIR:-$ROOT/docs/looks}
LOGS=$ROOT/build/logs
mkdir -p "$OUT_DIR" "$LOGS"
GODOT=${GODOT:-godot}

if [ $# -eq 0 ]; then
  echo "usage: sh tools/render_looks.sh <look id ...> | all | kit"; exit 1
fi

# (re)import assets: needed after any change to the kit GLBs, textures or new scripts
echo "== import"
sh tools/gslot.sh 300 $GODOT --headless --path godot --import > "$LOGS/import.log" 2>&1
grep -E "ERROR|SCRIPT ERROR" "$LOGS/import.log" | head -5

IDS="$*"
if [ "$1" = "all" ]; then
  IDS=$(ls godot/looks/*.gd | xargs -n1 basename | sed 's/\.gd$//' | tr '\n' ' ')
fi

for ID in $IDS; do
  if [ "$ID" = "kit" ]; then
    OUT="$OUT_DIR/kit_sheet.png"
    SHOTS="$ROOT/build/kit_shots"
    rm -rf "$SHOTS"; mkdir -p "$SHOTS"
    echo "== kit sheet"
    sh tools/gslot.sh 900 $GODOT --path godot --windowed --resolution 1280x720 -- mode=kit look=N out="$SHOTS" ss="$SS" > "$LOGS/kit.log" 2>&1
    grep -E "SAVED|SCRIPT ERROR|ERROR" "$LOGS/kit.log" | head -20
    python3 tools/kit_sheet.py "$SHOTS" "$OUT" && echo "-> $OUT"
    continue
  fi
  if [ "$ID" = "N" ]; then OUT="$OUT_DIR/neutral.png"; else OUT="$OUT_DIR/look_$ID.png"; fi
  echo "== look $ID -> $OUT"
  rm -f "$OUT.tmp.png"
  sh tools/gslot.sh 900 $GODOT --path godot --windowed --resolution 1280x720 -- look="$ID" out="$OUT.tmp.png" frames="$FRAMES" w="$W" h="$H" ss="$SS" > "$LOGS/look_$ID.log" 2>&1
  grep -E "BUILD|FPS|SAVED|SCRIPT ERROR|ERROR|Parse" "$LOGS/look_$ID.log" | grep -vE "leaked|never freed|still in use|Pages in use" | head -20
  if [ -f "$OUT.tmp.png" ]; then mv "$OUT.tmp.png" "$OUT"; echo "-> $OUT"; else echo "!! no image (see $LOGS/look_$ID.log; empty log = slot time-out, run again)"; fi
done

if [ "$1" = "all" ]; then
  python3 tools/contact_sheet.py "$OUT_DIR" "$OUT_DIR/contact_sheet.png" && echo "-> $OUT_DIR/contact_sheet.png"
fi
