#!/usr/bin/env python3
"""Static checks for a datapack. Not a Minecraft parser: it catches broken references,
invalid JSON and undeclared scoreboard objectives. Usage: verify_pack.py <pack_dir>"""
import json, os, re, sys

pack = sys.argv[1]
data = os.path.join(pack, "data")
errors, warns = [], []

functions, tags_fn, advs, preds = set(), set(), set(), set()
files_json = []
for root, _, names in os.walk(data):
    rel = os.path.relpath(root, data).split(os.sep)
    ns = rel[0] if rel[0] != "." else None
    for n in names:
        p = os.path.join(root, n)
        sub = rel[1:]
        stem = os.path.join(*sub[1:], n) if len(sub) > 1 else n
        base, ext = os.path.splitext(stem)
        base = base.replace(os.sep, "/")
        if not sub:
            continue
        kind = sub[0]
        if kind == "function" and ext == ".mcfunction":
            functions.add(f"{ns}:{base}")
        elif kind == "tags" and len(sub) > 1 and sub[1] == "function" and ext == ".json":
            b = os.path.join(*sub[2:], n) if len(sub) > 2 else n
            tags_fn.add(f"{ns}:{os.path.splitext(b)[0].replace(os.sep, '/')}")
        elif kind == "advancement" and ext == ".json":
            advs.add(f"{ns}:{base}")
        elif kind == "predicate" and ext == ".json":
            preds.add(f"{ns}:{base}")
        if ext == ".json" or n.endswith(".mcmeta"):
            files_json.append(p)

for p in files_json:
    try:
        json.load(open(p, encoding="utf-8"))
    except Exception as e:
        errors.append(f"invalid JSON {os.path.relpath(p, pack)}: {e}")

declared = {}
used_obj = {}
fn_ref = re.compile(r"(?<![\w.])function\s+(#?)([a-z0-9_.-]+:[a-z0-9_./-]+)")
adv_ref = re.compile(r"advancement\s+(?:grant|revoke)\s+\S+\s+only\s+([a-z0-9_.-]+:[a-z0-9_./-]+)")
pred_ref = re.compile(r"predicate\s+([a-z0-9_.-]+:[a-z0-9_./-]+)")
obj_add = re.compile(r"scoreboard\s+objectives\s+add\s+(\S+)\s+(\S+)")
score_use = re.compile(r"(?:scoreboard\s+players\s+\w+\s+\S+\s+(\S+))|(?:score\s+\S+\s+(\S+)\s+(?:matches|=|<|>|<=|>=))|(?:scores=\{([^}]*)\})")

for root, _, names in os.walk(data):
    for n in names:
        if not n.endswith(".mcfunction"):
            continue
        p = os.path.join(root, n)
        rp = os.path.relpath(p, pack)
        if "/tags/function/" in p.replace(os.sep, "/"):
            continue  # inert files; reported separately
        for ln, line in enumerate(open(p, encoding="utf-8"), 1):
            s = line.strip()
            if not s or s.startswith("#"):
                continue
            body = s[1:] if s.startswith("$") else s
            for m in fn_ref.finditer(body):
                hashed, tgt = m.groups()
                if "$(" in tgt or body[m.end():m.end()+2] == "$(":
                    continue
                if hashed:
                    if tgt not in tags_fn:
                        errors.append(f"{rp}:{ln} missing function tag #{tgt}")
                elif tgt not in functions:
                    errors.append(f"{rp}:{ln} missing function {tgt}")
            for m in adv_ref.finditer(body):
                if "$(" not in m.group(1) and body[m.end():m.end()+2] != "$(" and m.group(1) not in advs:
                    errors.append(f"{rp}:{ln} missing advancement {m.group(1)}")
            for m in pred_ref.finditer(body):
                if "$(" not in m.group(1) and m.group(1) not in preds:
                    errors.append(f"{rp}:{ln} missing predicate {m.group(1)}")
            for m in obj_add.finditer(body):
                if "$(" in m.group(1):
                    continue
                prev = declared.get(m.group(1))
                if prev and prev != m.group(2):
                    errors.append(f"{rp}:{ln} objective {m.group(1)} redeclared {prev} vs {m.group(2)}")
                declared[m.group(1)] = m.group(2)
            for m in score_use.finditer(body):
                for g in m.groups():
                    if not g:
                        continue
                    if g.startswith("macroengine") or g.startswith("player_action") or g in ("StringLib",):
                        used_obj.setdefault(re.split(r"[=\s]", g)[0], f"{rp}:{ln}")
                    elif "=" in g:
                        for part in g.split(","):
                            k = part.split("=")[0].strip()
                            if k.startswith("macroengine"):
                                used_obj.setdefault(k, f"{rp}:{ln}")

for root, _, names in os.walk(data):
    for n in names:
        if not n.endswith(".json"):
            continue
        p = os.path.join(root, n)
        rp = os.path.relpath(p, pack).replace(os.sep, "/")
        if "/tags/function/" in rp:
            try:
                vals = json.load(open(p, encoding="utf-8")).get("values", [])
            except Exception:
                continue
            for v in vals:
                v = v["id"] if isinstance(v, dict) else v
                if v.startswith("#"):
                    if v[1:] not in tags_fn:
                        errors.append(f"{rp} references missing tag {v}")
                elif v not in functions:
                    errors.append(f"{rp} references missing function {v}")
        if "/advancement/" in rp:
            try:
                j = json.load(open(p, encoding="utf-8"))
            except Exception:
                continue
            fnr = j.get("rewards", {}).get("function")
            if fnr and fnr not in functions:
                errors.append(f"{rp} reward function missing {fnr}")

for o, where in sorted(used_obj.items()):
    if o not in declared and "$(" not in o:
        warns.append(f"objective used but never declared by a literal add: {o} (first use {where})")

inert = []
for root, _, names in os.walk(data):
    for n in names:
        if n.endswith(".mcfunction") and "/tags/function" in root.replace(os.sep, "/"):
            inert.append(os.path.relpath(os.path.join(root, n), pack))

print(f"functions={len(functions)} fn_tags={len(tags_fn)} advancements={len(advs)} predicates={len(preds)} objectives_declared={len(declared)}")
print(f"ERRORS={len(errors)} WARNINGS={len(warns)} INERT_FILES={len(inert)}")
for e in errors[:80]:
    print("ERR ", e)
for w in warns[:60]:
    print("WARN", w)
for i in inert:
    print("INERT", i)
sys.exit(1 if errors else 0)
