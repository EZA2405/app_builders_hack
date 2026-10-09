#!/bin/bash
# Train + benchmark a Laya variant on any CUDA box (RunPod / Vast.ai / Lambda).
# Usage (in the pod's Jupyter terminal):
#   curl -sL https://raw.githubusercontent.com/EZA2405/app_builders_hack/main/ml/runpod_train.sh | bash -s -- v4e5 data/v4/train.jsonl 5
# Args: VERSION DATA EPOCHS. Output: $W/laya-guide-$VERSION.zip (download it from Jupyter's file browser)
# and $W/results-$VERSION.txt (val + held-out + web scores).
set -euo pipefail
VERSION=${1:-v4e5}; DATA=${2:-data/v4/train.jsonl}; EPOCHS=${3:-5}
W=${WORKDIR:-/workspace}; mkdir -p "$W"
cd "$W"
[ -d app_builders_hack ] || git clone -q https://github.com/EZA2405/app_builders_hack
cd app_builders_hack && git pull -q && cd ml
pip -q install "laya[serve]"
python -c "import torch; print('cuda', torch.cuda.is_available(), torch.cuda.get_device_name(0))"

OUT=$W/models; mkdir -p $OUT
start=$(date +%s)
laya-train --data "$DATA" --eval data/v4/val.jsonl --base convaiinnovations/laya --out $OUT/laya-guide-$VERSION \
  --device cuda --epochs "$EPOCHS" --micro-batch 8 --grad-accum 8 --shuffle-options --label-smoothing 0.05 --seed 7 \
  2>&1 | tee $W/train-$VERSION.log
echo "training took $(( ($(date +%s) - start) / 60 )) min" | tee -a $W/train-$VERSION.log

# Serve the checkpoint locally on the pod and run all three benchmarks (val chooses; held-out reported once).
LAYA_HOST=127.0.0.1 LAYA_PORT=8766 LAYA_DEVICE=cuda LAYA_MODELS=english \
LAYA_EXTRA_MODELS="{\"guide\": \"$OUT/laya-guide-$VERSION\"}" nohup laya-serve > $W/serve.log 2>&1 &
for i in $(seq 1 120); do curl -s -m 2 http://127.0.0.1:8766/health >/dev/null && break; sleep 2; done
R=$W/results-$VERSION.txt; : > $R
for set in "VAL fixtures/val/*.json" "HELD-OUT fixtures/*_real.json" "WEB fixtures/web_test/*.json"; do
  name=${set%% *}; glob=${set#* }; h=0; t=0
  for f in $glob; do
    line=$(python3 bench_localjev.py --url http://127.0.0.1:8766 --model guide --group 16 --fixture "$f" | tail -1)
    echo "$name $line" | tee -a $R
    a=$(echo "$line" | sed -E 's/.*accuracy ([0-9]+)\/([0-9]+).*/\1 \2/'); h=$((h + ${a% *})); t=$((t + ${a#* }))
  done
  echo "===== $VERSION $name: $h/$t =====" | tee -a $R
done
echo "baselines: v1 VAL 79/127, HELD-OUT 25/35, WEB 25/45 | v3 VAL 95/127, HELD-OUT 26/35, WEB 29/45" | tee -a $R

rm -rf $OUT/laya-guide-$VERSION/checkpoint_latest
cd $OUT && zip -qr $W/laya-guide-$VERSION.zip laya-guide-$VERSION
ls -lh $W/laya-guide-$VERSION.zip
echo "DONE. Download $W/laya-guide-$VERSION.zip from Jupyter's file browser, then STOP the pod."
