#!/bin/zsh
# Run a Jev-compatible model over every training-app fixture (teacher goals). Usage: run_teacher_bench.sh <url> <model> [group]
cd "${0:A:h}"
URL=$1; MODEL=$2; GROUP=${3:-200}
for f in fixtures/train/*.json; do
  python3 bench_localjev.py --url "$URL" --model "$MODEL" --group "$GROUP" --fixture "$f" &
  while (( $(jobs -r | wc -l) >= 6 )); do sleep 0.5; done
done
wait
