"""End-to-end checks of the public string API, the input validators, safe_name and the
gamerule normalizer against plain-Python references.  usage: test_api.py <pack dir>"""
import os, sys, random, threading
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mcemu import *

PACK = sys.argv[1]
fails, total = [], 0
def check(name, got, want):
    global total
    total += 1
    if got != want: fails.append(f"{name}: got {got!r}, want {want!r}")
def fresh():
    mc = MC(PACK); mc.CHAIN_LIMIT = 10**9
    mc.call("macroengine:core/internal/text/load"); return mc
def put(mc, sid, **kw):
    for k, v in kw.items():
        if isinstance(v, bool): v = B(v)
        elif isinstance(v, int): v = I(v)
        mc.storage.setdefault(sid, {})[k] = v
IN, OUT = "macroengine:input", "macroengine:output"
def lib(fn, **kw):
    mc = fresh(); put(mc, IN, **kw); mc.call(f"macroengine:core/lib/string/{fn}")
    r = mc.get(OUT, "string.result")
    return r

def ints(l): return [x.v for x in l] if isinstance(l, list) else l
def main():
    cases = ["", "a", "Hello World", "a b  c", "x,y,,z", "ÄÖÜ äöü ß", "tab here"]
    for s in cases:
        check(f"lower({s!r})", lib("to_lowercase", string=s), "".join(c.lower() if c.isascii() else c for c in s))
        check(f"upper({s!r})", lib("to_uppercase", string=s), "".join(c.upper() if c.isascii() else c for c in s))
    check("concat", lib("concat", list=["ab", "", "c", "dé"]), "abcdé")
    check("find hit", ints(lib("find", string="a-b-c-", find="-", n=0)), [1, 3, 5])
    check("find first1", ints(lib("find", string="a-b-c-", find="-", n=1)), [1])
    check("find last1", ints(lib("find", string="a-b-c-", find="-", n=-1)), [5])
    check("find miss", ints(lib("find", string="abc", find="z", n=0)), [-1])
    check("find n unset", ints(lib("find", string="abab", find="ab")), [0, 2])
    check("replace", lib("replace", string="a b c", find=" ", replace="_", n=0), "a_b_c")
    check("replace first", lib("replace", string="a b c", find=" ", replace="_", n=1), "a_b c")
    check("replace n unset", lib("replace", string="aXbX", find="X", replace="--"), "a--b--")
    check("split default sep", lib("split", string="a b  c"), ["a", "b", "c"])
    check("split comma keep", lib("split", string="x,y,,z", separator=",", keep_empty=True), ["x", "y", "", "z"])
    check("split chars", lib("split", string="abc", separator=""), ["a", "b", "c"])
    check("insert", lib("insert", string="abcd", insertion="XY", index=2), "abXYcd")
    check("to_number int", lib("to_number", string="42").v if lib("to_number", string="42") is not None else None, 42)
    check("to_string", lib("to_string", value=I(7)), "7")
    check("quote -> unset", lib("to_lowercase", string='a"B'), None)
    check("backslash -> unset", lib("to_uppercase", string="a\\b"), None)

    # validators
    def validate(typ, val):
        mc = fresh(); put(mc, IN, v=val)
        mc.storage.setdefault(IN, {})["v"] = val
        mc.call("macroengine:input/validate/check", {"source": "v", "type": typ})
        r = mc.get("macroengine:input_validate", "result")
        v = r.get("valid"); v = getattr(v, "v", v)
        return int(v), r.get("error")
    import re
    def ref_int(s): return re.fullmatch(r"-?[0-9]+", s) is not None
    def ref_float(s): return re.fullmatch(r"-?[0-9]+(\.[0-9]+)?", s) is not None
    ref_tag_bad = set(" \"'{}[]:\\§|^<>")
    random.seed(7)
    alphabet = "0123456789-.. ax\"'\\{}:§"
    samples = ["", "0", "-", "-5", "12", "1.5", "-1.5", "1.", ".5", "-.5", "1.2.3", "abc", "12a", "--1", "1-1", "+3", "٣"]
    samples += ["".join(random.choice(alphabet) for _ in range(random.randint(1, 7))) for _ in range(120)]
    for s in samples:
        if any(c in s for c in '"\\'):
            continue  # quote/backslash cannot be stored in the emulator's macro path
        check(f"int({s!r})", validate("int", s)[0] == 1, ref_int(s))
        check(f"float({s!r})", validate("float", s)[0] == 1, ref_float(s))
    for s in ["ok_name", "a b", "x:y", "a{b", "", "plain.dot-dash", "§x", "a|b", "q'r", "a^b", "a<b", "a>b", "ünï"]:
        want = bool(s) and not any(c in ref_tag_bad for c in s)
        check(f"tag_safe({s!r})", validate("tag_safe", s)[0] == 1, want)
    for s in ['a"b', "a\\b"]:
        check(f"tag_safe({s!r}) rejects", validate("tag_safe", s)[0] == 1, False)

    # safe_name
    deny = set(" \"'\\{}[]()<>:;,=!@#$%&*+?/|^`~§\n\r\t")
    def safe_name(s):
        mc = fresh(); put(mc, "macroengine:validate"); mc.storage["macroengine:validate"] = {"in": {"value": s}}
        r = mc.call("macroengine:systems/validate/safe_name")
        return r[0]
    for s in ["shop.use", "a-b_c.d", "Ünï", "x y", "a;b", "a/b", "a\nb", "a\tb", "a\rb", 'a"b', "a\\b", "x" * 64, "x" * 65, "", "a`b", "a~b", "ok1"]:
        want = 1 if (0 < len(s) <= 64 and not any(c in deny for c in s)) else 0
        check(f"safe_name({s!r})", safe_name(s), want)

    # gamerule normalize
    def norm(rule):
        mc = fresh(); put(mc, IN, rule=rule); mc.call("macroengine:core/internal/api/gamerule/normalize")
        return mc.get(IN, "_gamerule_norm")
    for s in ["PvP Enabled", "already_ok", "Mixed Case Name", "a  b", ""]:
        check(f"gamerule({s!r})", norm(s), s.replace(" ", "_").lower())
    check("gamerule quote -> unset", norm('a"b'), None)

t = threading.Thread(target=main); sys.setrecursionlimit(200000); threading.stack_size(256*1024*1024)
t = threading.Thread(target=main); t.start(); t.join()
print(f"checks={total} failures={len(fails)}")
for f in fails[:25]: print("FAIL", f)
sys.exit(1 if fails else 0)
