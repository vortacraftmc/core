#!/usr/bin/env python3
"""
audit_repo.py bulgularinin GUVENLI ve mekanik olanlarini toplu duzeltir.

Uygulanan duzeltmeler (hepsi geri alinabilir, git ile izlenir):
  F1  tags/ icine kacmis .mcfunction watermark dosyalarini sil
  F2  legacy paketlerde (pack_format < 48) watermark'i function/ -> functions/ tasir
      ve bosalan function/ dizinini kaldirir
  F3  guikit-demo: clear_in -> clear/in, clear_w -> clear/w (78 kirik cagri)
  F4  merge-manifest output min/max_format'i en talepkar pakete esitler
  F5  LeftClickDetection pack.mcmeta format alanlarindaki dortlu tekrari temizler
  F6  .github/workflows/lint.sh -> scripts/lint_datapacks.sh + build.yml guncelle
  F7  build.gradle checkOriginWatermarks: konumu da dogrula (sozlesme ile uyumlu)
  F8  var olmayan workflow'lara referans veren dokumanlari isaretle

Kullanim: python3 scripts/apply_audit_fixes.py [--dry-run]
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys

REPO = subprocess.run(
    ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, cwd=os.path.dirname(__file__)
).stdout.strip() or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

DRY = "--dry-run" in sys.argv
LOG: list[str] = []


def log(msg):
    LOG.append(msg)
    print(("  [dry] " if DRY else "  ") + msg)


def norm_fmt(f):
    if isinstance(f, list):
        return f[0]
    return f


def declared_format(pack_dir):
    p = os.path.join(pack_dir, "pack.mcmeta")
    if not os.path.exists(p):
        return None
    try:
        pk = json.load(open(p, encoding="utf-8")).get("pack", {})
    except (json.JSONDecodeError, OSError):
        return None
    for k in ("min_format", "pack_format"):
        if k in pk:
            return norm_fmt(pk[k])
    return None


def rm(path):
    log(f"SIL  {os.path.relpath(path, REPO)}")
    if not DRY:
        os.remove(path)


def mv(src, dst):
    log(f"TASI {os.path.relpath(src, REPO)} -> {os.path.relpath(dst, REPO)}")
    if not DRY:
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.move(src, dst)


def rmdir_if_empty(d):
    try:
        if os.path.isdir(d) and not os.listdir(d):
            log(f"DIZIN SIL (bos) {os.path.relpath(d, REPO)}")
            if not DRY:
                os.rmdir(d)
    except OSError:
        pass


def rewrite(path, pairs, label):
    txt = open(path, encoding="utf-8").read()
    new = txt
    n = 0
    for a, b in pairs:
        c = new.count(a)
        if c:
            new = new.replace(a, b)
            n += c
    if n:
        log(f"YAZ  {os.path.relpath(path, REPO)}  ({n} degisiklik: {label})")
        if not DRY:
            open(path, "w", encoding="utf-8").write(new)
    return n


# --------------------------------------------------------------------------- #
def f1_tags_stray():
    print("\nF1 - tags/ icine kacmis .mcfunction watermark dosyalari")
    packs = os.path.join(REPO, "packs")
    n = 0
    for root, dirs, files in os.walk(packs):
        dirs[:] = [d for d in dirs if d != "build"]
        if os.path.basename(root) not in ("function", "functions"):
            continue
        if f"{os.sep}tags{os.sep}" not in root + os.sep:
            continue
        for f in files:
            if f.endswith(".mcfunction"):
                fp = os.path.join(root, f)
                # on-kosul: ayni pakette dogru konumda watermark kalmali
                pack_root = fp.split(f"{os.sep}data{os.sep}")[0]
                keep = [
                    x
                    for x in _walk_files(pack_root)
                    if os.path.basename(x) == "_vc_origin.mcfunction"
                    and f"{os.sep}tags{os.sep}" not in x
                ]
                if not keep:
                    log(f"ATLA {os.path.relpath(fp, REPO)} - pakette baska dogru konumlu watermark yok")
                    continue
                rm(fp)
                n += 1
    print(f"  -> {n} dosya")
    return n


def _walk_files(top):
    for root, dirs, files in os.walk(top):
        dirs[:] = [d for d in dirs if d != "build"]
        for f in files:
            yield os.path.join(root, f)


def f2_legacy_fn_dir():
    print("\nF2 - legacy paketlerde function/ -> functions/ watermark tasima")
    packs = os.path.join(REPO, "packs")
    moved = 0
    for pack in sorted(os.listdir(packs)):
        pdir = os.path.join(packs, pack)
        if not os.path.isdir(pdir):
            continue
        fmt = declared_format(pdir)
        if fmt is None:
            # ic ice paketler
            for root, dirs, files in os.walk(pdir):
                if "pack.mcmeta" in files:
                    fmt = declared_format(root)
                    if fmt is not None:
                        break
        if fmt is None or fmt >= 48:
            continue
        data = os.path.join(pdir, "data")
        if not os.path.isdir(data):
            continue
        for ns in sorted(os.listdir(data)):
            nsd = os.path.join(data, ns)
            sing = os.path.join(nsd, "function")
            plur = os.path.join(nsd, "functions")
            if not (os.path.isdir(sing) and os.path.isdir(plur)):
                continue
            for f in sorted(os.listdir(sing)):
                src = os.path.join(sing, f)
                if not os.path.isfile(src):
                    continue
                dst = os.path.join(plur, f)
                if os.path.exists(dst):
                    log(f"CAKISMA {os.path.relpath(dst, REPO)} zaten var - kaynak siliniyor")
                    rm(src)
                else:
                    mv(src, dst)
                moved += 1
            rmdir_if_empty(sing)
    print(f"  -> {moved} dosya tasindi")
    return moved


def f3_guikit_refs():
    print("\nF3 - guikit-demo kirik fonksiyon referanslari")
    demo = os.path.join(REPO, "packs", "guikit-demo")
    pairs = [("guikit:internal/clear_in", "guikit:internal/clear/in"),
             ("guikit:internal/clear_w", "guikit:internal/clear/w")]
    total = 0
    for fp in _walk_files(demo):
        if fp.endswith(".mcfunction"):
            total += rewrite(fp, pairs, "clear_in->clear/in, clear_w->clear/w")
    print(f"  -> {total} cagri duzeltildi")
    return total


def f4_manifest():
    print("\nF4 - merge-manifest output format")
    mp = os.path.join(REPO, "packs", "merge-manifest.json")
    mm = json.load(open(mp, encoding="utf-8"))
    packs = os.path.join(REPO, "packs")
    need = None
    for inc in mm.get("include", []):
        p = os.path.join(packs, inc, "pack.mcmeta")
        if not os.path.exists(p):
            continue
        pk = json.load(open(p, encoding="utf-8")).get("pack", {})
        raw = pk.get("min_format", pk.get("pack_format"))
        if isinstance(raw, list) and (need is None or raw > need):
            need = raw
    out = mm.get("output", {})
    if need and out.get("min_format") != need:
        log(f"YAZ  packs/merge-manifest.json  output.min/max_format {out.get('min_format')} -> {need}")
        if not DRY:
            out["min_format"] = list(need)
            out["max_format"] = list(need)
            mm["output"] = out
            with open(mp, "w", encoding="utf-8") as fh:
                json.dump(mm, fh, indent=2, ensure_ascii=False)
                fh.write("\n")
        return 1
    print("  -> degisiklik gerekmedi")
    return 0


def f5_leftclick_meta():
    print("\nF5 - LeftClickDetection pack.mcmeta format tekrari")
    p = os.path.join(REPO, "packs", "LeftClickDetection", "pack.mcmeta")
    m = json.load(open(p, encoding="utf-8"))
    pk = m.get("pack", {})
    if "pack_format" in pk and ("min_format" in pk or "supported_formats" in pk):
        kept = {"description": pk.get("description")}
        for k in ("pack_format", "supported_formats"):
            if k in pk:
                kept[k] = pk[k]
        log(f"YAZ  packs/LeftClickDetection/pack.mcmeta  min/max_format kaldirildi "
            f"(pack_format + supported_formats korunuyor, ayni bilgiyi tekrar ediyorlardi)")
        if not DRY:
            m["pack"] = {k: v for k, v in kept.items() if v is not None}
            with open(p, "w", encoding="utf-8") as fh:
                json.dump(m, fh, indent=2, ensure_ascii=False)
                fh.write("\n")
        return 1
    print("  -> degisiklik gerekmedi")
    return 0


def f6_move_lint():
    print("\nF6 - lint.sh konumu")
    src = os.path.join(REPO, ".github", "workflows", "lint.sh")
    dst = os.path.join(REPO, "scripts", "lint_datapacks.sh")
    if not os.path.exists(src):
        print("  -> zaten tasindi")
        return 0
    if DRY:
        log(f"TASI .github/workflows/lint.sh -> scripts/lint_datapacks.sh")
    else:
        subprocess.run(["git", "mv", src, dst], cwd=REPO, check=True)
        log("TASI .github/workflows/lint.sh -> scripts/lint_datapacks.sh")
    n = 0
    for wf in ("build.yml",):
        p = os.path.join(REPO, ".github", "workflows", wf)
        if os.path.exists(p):
            n += rewrite(p, [(".github/workflows/lint.sh", "scripts/lint_datapacks.sh")], "lint.sh yolu")
    # dokumanlardaki referanslar
    for fp in _walk_files(REPO):
        if fp.endswith(".md") and f"{os.sep}.git{os.sep}" not in fp:
            rewrite(fp, [(".github/workflows/lint.sh", "scripts/lint_datapacks.sh")], "lint.sh yolu")
    print(f"  -> {n} workflow referansi")
    return 1


def f7_watermark_check():
    print("\nF7 - checkOriginWatermarks konum dogrulamasi")
    bg = os.path.join(REPO, "build.gradle")
    txt = open(bg, encoding="utf-8").read()
    old = """        def hasWatermark = false
        dir.eachFileRecurse { f ->
            if (f.name == '_vc_origin.mcfunction') {
                hasWatermark = true
            }
        }
        !hasWatermark"""
    new = """        // Konum da dogrulanir: hata mesaji "data/<namespace>/function/ altinda"
        // der, ama onceki kod dosyayi paketin HERHANGI bir yerinde kabul
        // ediyordu (tags/function/ icine kacmis bir kopya bile yeterli
        // sayiliyordu). Artik yalnizca dogru agac altindakiler sayilir.
        def hasWatermark = false
        def dataDir = new File(dir, 'data')
        if (dataDir.exists()) {
            dataDir.eachFileRecurse { f ->
                if (f.name != '_vc_origin.mcfunction') return
                def rel = dataDir.toPath().relativize(f.toPath()).toString()
                def parts = rel.split(java.util.regex.Pattern.quote(File.separator))
                // <namespace>/function(s)/...  (pack_format < 48 'functions' kullanir)
                if (parts.length >= 3 && (parts[1] == 'function' || parts[1] == 'functions')) {
                    hasWatermark = true
                }
            }
        }
        !hasWatermark"""
    if old in txt:
        log("YAZ  build.gradle  findMissingWatermarks artik konumu dogruluyor")
        if not DRY:
            open(bg, "w", encoding="utf-8").write(txt.replace(old, new))
        return 1
    if "parts[1] == 'function'" in txt:
        print("  -> zaten uygulandi")
        return 0
    print("  !! beklenen kod blogu bulunamadi, atlandi")
    return 0


def f8_workflow_refs():
    print("\nF8 - var olmayan workflow referanslari")
    notes = {
        os.path.join(REPO, "scripts", "dp-depman", "README.md"):
            ("datapack-build.yml", "dep-update.yml"),
        os.path.join(REPO, "scripts", "dp-depman", "docs", "README.md"):
            ("datapack-build.yml", "dep-update.yml"),
        os.path.join(REPO, "scripts", "gui_generator", "README.md"):
            ("publish.yml",),
    }
    n = 0
    for p, names in notes.items():
        if not os.path.exists(p):
            continue
        txt = open(p, encoding="utf-8").read()
        if "Historical note (audit 2026-10-07)" in txt:
            print(f"  -> {os.path.relpath(p, REPO)} zaten isaretli")
            continue
        note = (
            "\n> **Historical note (audit 2026-10-07):** the workflow file(s) named below "
            "(" + ", ".join(f"`{x}`" for x in names) + ") belonged to the pre-monorepo "
            "`runtoolkit` repositories. They do **not** exist in `vortacraftmc/core`; "
            "`.github/workflows/` here contains only `build.yml`, `codeowners-sync.yml` "
            "and the datapack lint script. The references below are kept for provenance.\n"
        )
        first = None
        for i, line in enumerate(txt.splitlines(), 1):
            if any(x in line for x in names):
                first = i
                break
        if first:
            lines = txt.splitlines(keepends=True)
            lines.insert(first - 1, note)
            log(f"YAZ  {os.path.relpath(p, REPO)}  (satir {first} onune tarihsel not)")
            if not DRY:
                open(p, "w", encoding="utf-8").write("".join(lines))
            n += 1
    print(f"  -> {n} dokuman")
    return n


# --------------------------------------------------------------------------- #
def main():
    print("=" * 70)
    print("TOPLU DUZELTME" + ("  [DRY-RUN]" if DRY else ""))
    print("=" * 70)
    totals = {}
    for fn in (f1_tags_stray, f2_legacy_fn_dir, f3_guikit_refs, f4_manifest,
               f5_leftclick_meta, f6_move_lint, f7_watermark_check, f8_workflow_refs):
        totals[fn.__name__] = fn()
    print("\n" + "=" * 70)
    print("OZET: " + ", ".join(f"{k}={v}" for k, v in totals.items()))
    print(f"toplam {len(LOG)} islem")


if __name__ == "__main__":
    main()
