#!/bin/sh
# Copied from ~/Projects/umbara/tools/gslot.sh (2026-11-17). Keeps the SAME lock folder ($TMPDIR/umbara-gslots)
# so Neon Static and Umbara share the machine-wide limit of two Godot copies at once.
#   sh tools/gslot.sh <max seconds> <command ...>
# Waits for a free slot, runs the command, kills it after <max seconds>, frees the slot.
MAX=$1; shift
LOCKS=${TMPDIR:-/tmp}/umbara-gslots
mkdir -p "$LOCKS"
# GSLOT_SOLO=1: wait until both slots are free and hold both, for frame-rate measurements that need the game alone.
if [ "$GSLOT_SOLO" = 1 ]; then
  while :; do
    if mkdir "$LOCKS/slot1" 2>/dev/null; then
      if mkdir "$LOCKS/slot2" 2>/dev/null; then break; fi
      rmdir "$LOCKS/slot1"
    fi
    for n in 1 2; do
      pid=$(cat "$LOCKS/slot$n/pid" 2>/dev/null)
      if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then rm -rf "$LOCKS/slot$n"; fi
    done
    sleep 3
  done
  echo $$ > "$LOCKS/slot1/pid"; echo $$ > "$LOCKS/slot2/pid"
  trap 'rm -rf "$LOCKS/slot1" "$LOCKS/slot2"' EXIT INT TERM
  perl -e 'alarm shift; exec @ARGV' "$MAX" "$@"
  exit $?
fi
while :; do
  for n in 1 2; do
    if mkdir "$LOCKS/slot$n" 2>/dev/null; then SLOT="$LOCKS/slot$n"; break 2; fi
    # a slot whose owner died is stale: free it
    pid=$(cat "$LOCKS/slot$n/pid" 2>/dev/null)
    if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then rm -rf "$LOCKS/slot$n"; fi
  done
  sleep 2
done
echo $$ > "$SLOT/pid"
trap 'rm -rf "$SLOT"' EXIT INT TERM
perl -e 'alarm shift; exec @ARGV' "$MAX" "$@"
