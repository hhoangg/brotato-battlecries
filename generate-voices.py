#!/usr/bin/env python3
"""Generate the per-category Battle Cries voice clips via Voicebox (Qwen CustomVoice).

Reads voice-content.json and, for each character x category x line, asks Voicebox to
render an emotion-directed clip, then transcodes it to mono 48k mp3 at
    mods-unpacked/tato-BattleCries/voices/<slug>/<cat>/<cat>_NN.mp3
which is exactly where the mod's voice_player.gd looks for per-category clips
(falling back to the flat <slug>/<slug>_NN.mp3 Kokoro clips when a category folder
is absent).

Emotion comes from Qwen's `instruct` field = "<character delivery>, <category emotion>".
Variety across the two available English voices (Ryan/Aiden) comes from per-character
pitch + an effects chain (deep/menace/ghostly/robotic/loud), mirroring vb_qwen_spectrum.

Resumable: any clip whose mp3 already exists is skipped, so a killed run just
re-runs the remainder. Qwen is slow on MLX/MPS, so run this in the BACKGROUND.

Usage:
    no_proxy='*' python3 generate-voices.py            # generate everything missing
    no_proxy='*' python3 generate-voices.py --limit 1  # smoke-test one clip
    no_proxy='*' python3 generate-voices.py --only crazy   # one character only
"""
import json, subprocess, os, time, sys

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = "http://127.0.0.1:17493"
ENV = {**os.environ, "no_proxy": "*", "NO_PROXY": "*"}
CONTENT = os.path.join(HERE, "voice-content.json")
VOICES = os.path.join(HERE, "mods-unpacked/tato-BattleCries/voices")

# Qwen sometimes rambles/loops on a line, yielding a clip far longer than the few-word
# text warrants (wave-start must be snappy; emotes tolerate a touch more). --fixlong
# regenerates any clip over its category ceiling, keeping the shortest take.
MAX_DUR = {"ready": 2.8, "laugh": 4.5, "cheer": 4.0, "taunt": 4.0, "nooo": 5.0, "hurt": 4.5, "quip": 4.0}


def curl(method, path, body=None, raw=False, timeout=240):
    args = ["curl", "-s", "-m", str(timeout), "-X", method, BASE + path]
    if body is not None:
        args += ["-H", "Content-Type: application/json", "-d", json.dumps(body)]
    r = subprocess.run(args, capture_output=True, env=ENV, timeout=timeout + 10)
    if raw:
        return r.stdout
    try:
        return json.loads(r.stdout.decode("utf-8", "replace"))
    except Exception:
        return {"_raw": r.stdout.decode("utf-8", "replace")[:300]}


def fx(semi, style):
    """Per-character effect chain: pitch shift + a style colour (see vb_qwen_spectrum)."""
    c = []
    if semi:
        c.append({"type": "pitch_shift", "enabled": True, "params": {"semitones": float(semi)}})
    if style == "deep":
        c += [{"type": "lowpass", "enabled": True, "params": {"cutoff_frequency_hz": 7000.0}},
              {"type": "gain", "enabled": True, "params": {"gain_db": 1.5}}]
    elif style == "menace":
        c += [{"type": "reverb", "enabled": True, "params": {"room_size": 0.5, "damping": 0.5, "wet_level": 0.3, "dry_level": 0.6}}]
    elif style == "ghostly":
        c += [{"type": "reverb", "enabled": True, "params": {"room_size": 0.75, "damping": 0.4, "wet_level": 0.45, "dry_level": 0.4}}]
    elif style == "robotic":
        c += [{"type": "chorus", "enabled": True, "params": {"rate_hz": 0.6, "depth": 0.4, "feedback": 0.0, "centre_delay_ms": 3.0, "mix": 0.5}}]
    elif style == "loud":
        c += [{"type": "gain", "enabled": True, "params": {"gain_db": 6.0}}]
    return c


_profs = curl("GET", "/profiles")
_by_name = {p["name"]: p for p in _profs} if isinstance(_profs, list) else {}


def qwen_profile(voice):
    """id of the qv-<voice> preset profile, creating it on the fly if missing."""
    name = "qv-" + voice.lower()
    if name in _by_name:
        return _by_name[name]["id"]
    r = curl("POST", "/profiles", {"name": name, "language": "en", "voice_type": "preset",
                                   "preset_engine": "qwen_custom_voice", "preset_voice_id": voice})
    if isinstance(r, dict) and r.get("id"):
        _by_name[name] = r
        return r["id"]
    for p in curl("GET", "/profiles"):
        if p.get("name") == name:
            return p["id"]
    return None


def generate_one(pid, text, instruct, effects, out_path):
    """Render one line and transcode to mono 48k mp3. Returns (ok, err)."""
    gen = curl("POST", "/generate", {"profile_id": pid, "text": text, "language": "en",
                                     "engine": "qwen_custom_voice", "instruct": instruct,
                                     "effects_chain": effects})
    gid = gen.get("id") or gen.get("generation_id") if isinstance(gen, dict) else None
    if not gid:
        return False, "no id: " + json.dumps(gen)[:200]
    # First call also blocks on the model load; give it a generous window.
    audio = b""
    for _ in range(300):
        audio = curl("GET", "/audio/" + gid, raw=True, timeout=60)
        if len(audio) > 2000:
            break
        time.sleep(1)
    if len(audio) <= 2000:
        return False, "audio empty after wait"
    tmp = out_path + ".src"
    with open(tmp, "wb") as f:
        f.write(audio)
    r = subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp,
                        "-ac", "1", "-ar", "48000", "-codec:a", "libmp3lame", "-q:a", "4", out_path],
                       capture_output=True)
    try:
        os.remove(tmp)
    except OSError:
        pass
    if r.returncode != 0 or not os.path.exists(out_path):
        return False, "ffmpeg: " + r.stderr.decode("utf-8", "replace")[:160]
    return True, None


def duration(path):
    r = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                        "-of", "default=nw=1:nk=1", path], capture_output=True, text=True)
    try:
        return float(r.stdout.strip())
    except ValueError:
        return 0.0


def fixlong(d, rounds):
    """Regenerate any clip longer than its category ceiling, keeping the shortest take."""
    cat_emotion = d["category_emotion"]
    chars = d["characters"]
    pid_cache = {}
    targets = []
    for slug, c in chars.items():
        for cat in d["categories"]:
            for i, line in enumerate(c["lines"].get(cat, [])):
                out = os.path.join(VOICES, slug, cat, "%s_%02d.mp3" % (cat, i + 1))
                if os.path.exists(out) and duration(out) > MAX_DUR[cat]:
                    targets.append((slug, cat, i, line, out, c))
    print("[fixlong] %d clips over ceiling" % len(targets), flush=True)
    fixed = stubborn = 0
    for n, (slug, cat, i, line, out, c) in enumerate(targets, 1):
        voice = c["voice"]
        if voice not in pid_cache:
            pid_cache[voice] = qwen_profile(voice)
        pid = pid_cache[voice]
        instruct = c["delivery"] + ", " + cat_emotion[cat]
        effects = fx(c["pitch"], c["style"])
        best = duration(out)
        for _ in range(rounds):
            tmp = out + ".cand.mp3"
            ok, err = generate_one(pid, line, instruct, effects, tmp)
            if not ok:
                continue
            cand = duration(tmp)
            if cand < best:
                os.replace(tmp, out)
                best = cand
            else:
                try:
                    os.remove(tmp)
                except OSError:
                    pass
            if best <= MAX_DUR[cat]:
                break
        ok_now = best <= MAX_DUR[cat]
        fixed += ok_now
        stubborn += (not ok_now)
        print("[%s %d/%d] %s/%s_%02d -> %.2fs" % ("ok" if ok_now else "STILL", n, len(targets), slug, cat, i + 1, best), flush=True)
    print("DONE fixlong: under_ceiling=%d still_over=%d" % (fixed, stubborn), flush=True)


def main():
    limit = None
    only = None
    mode = "gen"
    rounds = 4
    a = sys.argv[1:]
    while a:
        if a[0] == "--limit":
            limit = int(a[1]); a = a[2:]
        elif a[0] == "--only":
            only = a[1]; a = a[2:]
        elif a[0] == "--fixlong":
            mode = "fixlong"; a = a[1:]
        elif a[0] == "--rounds":
            rounds = int(a[1]); a = a[2:]
        else:
            a = a[1:]

    d = json.load(open(CONTENT))
    if mode == "fixlong":
        fixlong(d, rounds)
        return
    cat_emotion = d["category_emotion"]
    categories = d["categories"]
    chars = d["characters"]

    work = []
    for slug, c in chars.items():
        if only and slug != only:
            continue
        for cat in categories:
            for i, line in enumerate(c["lines"].get(cat, [])):
                out = os.path.join(VOICES, slug, cat, "%s_%02d.mp3" % (cat, i + 1))
                work.append((slug, cat, i, line, out, c))

    todo = [w for w in work if not os.path.exists(w[4])]
    if limit is not None:
        todo = todo[:limit]
    print("[plan] total=%d already_done=%d todo=%d" % (len(work), len(work) - len([w for w in work if not os.path.exists(w[4])]), len(todo)), flush=True)

    pid_cache = {}
    ok = fail = 0
    t0 = time.time()
    for n, (slug, cat, i, line, out, c) in enumerate(todo, 1):
        voice = c["voice"]
        if voice not in pid_cache:
            pid_cache[voice] = qwen_profile(voice)
        pid = pid_cache[voice]
        if not pid:
            print("[ERR] no profile for voice %s" % voice, flush=True); fail += 1; continue
        instruct = c["delivery"] + ", " + cat_emotion[cat]
        os.makedirs(os.path.dirname(out), exist_ok=True)
        success, err = generate_one(pid, line, instruct, fx(c["pitch"], c["style"]), out)
        if success:
            ok += 1
            el = time.time() - t0
            print("[ok %d/%d %ds] %s/%s_%02d %s | \"%s\"" % (n, len(todo), int(el), slug, cat, i + 1, voice, line), flush=True)
        else:
            fail += 1
            print("[ERR %d/%d] %s/%s_%02d: %s" % (n, len(todo), slug, cat, i + 1, err), flush=True)
    print("DONE ok=%d fail=%d elapsed=%ds" % (ok, fail, int(time.time() - t0)), flush=True)


if __name__ == "__main__":
    main()
