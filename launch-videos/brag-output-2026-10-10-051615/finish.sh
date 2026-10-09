#!/usr/bin/env bash
# Render a composition, bake the poster, then normalize loudness to -14 LUFS (two-pass, linear).
set -euo pipefail
comp="$1"; out="$2"; poster="${3:-9.3}"
bash ~/.claude/skills/launch-video/scripts/render.sh "$comp" "$out" "$poster"
m=$(ffmpeg -hide_banner -i "$out" -af loudnorm=I=-14:TP=-1.0:LRA=11:print_format=json -f null - 2>&1 | sed -n '/^{/,/^}/p')
g(){ echo "$m" | python3 -c "import json,sys;print(json.load(sys.stdin)['$1'])"; }
ffmpeg -v error -y -i "$out" -c:v copy -af "loudnorm=I=-14:TP=-1.0:LRA=11:measured_I=$(g input_i):measured_TP=$(g input_tp):measured_LRA=$(g input_lra):measured_thresh=$(g input_thresh):offset=$(g target_offset):linear=true" -ar 48000 -c:a aac -b:a 192k -movflags +faststart "${out%.mp4}.norm.mp4"
mv "${out%.mp4}.norm.mp4" "$out"
ffmpeg -hide_banner -i "$out" -af ebur128=framelog=quiet -f null - 2>&1 | grep -E "^\s+(I|Peak):" | tr -s ' ' | tr '\n' ' '; echo
