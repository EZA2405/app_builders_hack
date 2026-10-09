"""Train + benchmark a Laya variant on Modal (free $30/month credits), reusing ml/runpod_train.sh.

Setup once:   pip install modal && modal setup        (browser login)
Run:          modal run ml/modal_train.py --version v4e5 --data data/v4/train.jsonl --epochs 5
Download:     modal volume get gabay-models laya-guide-v4e5.zip .   (and results-v4e5.txt)
"""
import os
import subprocess

import modal

app = modal.App("gabay-train")
image = (modal.Image.debian_slim(python_version="3.12")
         .apt_install("git", "zip", "curl")
         .pip_install("laya[serve]"))
models = modal.Volume.from_name("gabay-models", create_if_missing=True)


@app.function(gpu=os.environ.get("GABAY_GPU", "H100"), image=image, volumes={"/out": models}, timeout=3 * 60 * 60)
def train(version: str, data: str, epochs: int) -> str:
    script = ("set -e; cd /root && git clone -q https://github.com/EZA2405/app_builders_hack && "
              f"WORKDIR=/out bash app_builders_hack/ml/runpod_train.sh {version} {data} {epochs}")
    subprocess.run(["bash", "-c", script], check=True)
    models.commit()
    return open(f"/out/results-{version}.txt").read()


@app.local_entrypoint()
def main(version: str = "v4e5", data: str = "data/v4/train.jsonl", epochs: int = 5):
    print(train.remote(version, data, epochs))
    print(f"\nDownload: modal volume get gabay-models laya-guide-{version}.zip .")
