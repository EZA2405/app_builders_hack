"""Hard-negative mining on Modal: serve a checkpoint from the gabay-models volume on an H100 and run
mine_hard_negatives.py against it. Uploads only sanitized menu dumps (/tmp/sg/clean_train*: is_personal +
redact_names already applied), never the raw ones.

Run: modal run ml/modal_mine.py --model-dir laya-guide-v4e5 --sources goals,goals_traps --out mined_v4e5.jsonl
"""
import os
import subprocess

import modal

app = modal.App("gabay-mine")
image = (modal.Image.debian_slim(python_version="3.12")
         .apt_install("git", "curl")
         .pip_install("laya[serve]")
         .add_local_dir("/tmp/sg/clean_train", "/dumps/train")
         .add_local_dir("/tmp/sg/clean_train2", "/dumps/train2"))
models = modal.Volume.from_name("gabay-models")


@app.function(gpu=os.environ.get("GABAY_GPU", "H100"), image=image, volumes={"/out": models}, timeout=2 * 60 * 60)
def mine(model_dir: str, sources: str, out: str, threads: int = 12) -> str:
    script = f"""set -e
cd /root && git clone -q https://github.com/EZA2405/app_builders_hack && cd app_builders_hack/ml
LAYA_HOST=127.0.0.1 LAYA_PORT=8766 LAYA_DEVICE=cuda LAYA_MODELS=english \\
LAYA_EXTRA_MODELS='{{"guide": "/out/models/{model_dir}"}}' nohup laya-serve > /root/serve.log 2>&1 &
for i in $(seq 1 120); do curl -s -m 2 http://127.0.0.1:8766/health >/dev/null && break; sleep 2; done
python3 mine_hard_negatives.py mine --model guide --sources {sources} --out /root/{out} --threads {threads} /dumps/train /dumps/train2
"""
    subprocess.run(["bash", "-c", script], check=True)
    return open(f"/root/{out}").read()


@app.local_entrypoint()
def main(model_dir: str = "laya-guide-v4e5", sources: str = "goals,goals_traps", out: str = "mined_v4e5.jsonl"):
    rows = mine.remote(model_dir, sources, out)
    path = os.path.join(os.path.dirname(__file__), "data", "v6", out)
    open(path, "w").write(rows)
    print(f"wrote {rows.count(chr(10))} rows -> {path}")
