"""Voice-over lines with Kokoro-82M, on this Mac (kokoro-onnx; model from `npx hyperframes tts` cache).
Usage: <venv-python> make-vo.py  →  shared-assets/vo/<id>.wav, loudness-matched, plus durations on stdout.
"Gabay" is Tagalog (ga-BAI); the English phonemizer says "GAB-ay", so its phonemes are swapped in
(see GABAY). Other Filipino words are said in English (Lola → Grandma); only the project name stays Tagalog."""
import json, os, subprocess, sys
import kokoro_onnx, soundfile as sf

HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.expanduser('~/.cache/hyperframes/tts')
VOICE, SPEED = 'af_heart', 0.95
# Tagalog gabáy: short open 'a', stress on the second syllable ("ga-BUY"). Takes to compare: vo-tests/gabay-takes-1-to-4.wav
GABAY = os.environ.get('GABAY', 'ɡabˈaɪ')
OUT = os.path.join(HERE, 'shared-assets', 'vo')
os.makedirs(OUT, exist_ok=True)

k = kokoro_onnx.Kokoro(os.path.join(CACHE, 'models/kokoro-v1.0.onnx'), os.path.join(CACHE, 'voices/voices-v1.0.bin'))
lines = json.load(open(os.path.join(HERE, 'vo-lines.json')))
for i, ln in enumerate(lines):
    ph = k.tokenizer.phonemize(ln['text'], 'en-us').replace('ɡˈæbeɪ', GABAY)
    samples, rate = k.create(ph, voice=VOICE, speed=SPEED, is_phonemes=True)
    raw = os.path.join(OUT, ln['id'] + '.raw.wav')
    sf.write(raw, samples, rate)
    dst = os.path.join(OUT, ln['id'] + '.wav')
    # same loudness for every line; 48 kHz to match the mix
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', raw, '-af', 'loudnorm=I=-17:TP=-2:LRA=7', '-ar', '48000', dst], check=True)
    os.remove(raw)
    d = len(samples) / rate
    nxt = lines[i + 1]['t'] if i + 1 < len(lines) else 60
    flag = '  <-- overlaps next' if ln['t'] + d > nxt - 0.08 else ''
    print(f"{ln['id']} {ln['t']:6.2f} +{d:4.2f} → {ln['t'] + d:6.2f}  {ph}{flag}")
