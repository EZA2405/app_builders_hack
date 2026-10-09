#!/bin/zsh
# Build the v3 training set: v2 app rows + mined hard negatives + web journey rows, then
# Jev soft labels (hosted, sanitized menus/public pages only). Usage: ml/assemble_v3.sh [web_pages_dir]
set -euo pipefail
cd "${0:A:h}"
PAGES=${1:-/tmp/sg/web}
mkdir -p data/v3
python3 web_data.py rows "$PAGES" data/v3/web.jsonl
cat data/v2/train.jsonl data/mined.jsonl data/v3/web.jsonl | python3 -c "
import sys, random, json
rows = [l for l in sys.stdin if l.strip()]
random.Random(17).shuffle(rows)
sys.stdout.writelines(rows)" > data/v3/train_hard.jsonl
cp data/v2/val.jsonl data/v3/val.jsonl
echo "rows: v2 $(wc -l < data/v2/train.jsonl) + mined $(wc -l < data/mined.jsonl) + web $(wc -l < data/v3/web.jsonl) = $(wc -l < data/v3/train_hard.jsonl)"
python3 jev_soft_labels.py data/v3/train_hard.jsonl data/v3/train.jsonl
