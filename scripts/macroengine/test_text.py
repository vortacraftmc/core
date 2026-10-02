import os, sys, random, threading
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mcemu import *

PACK = sys.argv[1]
NS = "macroengine:core/internal/text"
TS = "macroengine:text"
fails, total = [], 0

def check(name, got, want):
    global total
    total += 1
    if got != want:
        fails.append(f"{name}: got {got!r}, want {want!r}")

def fresh():
    mc = MC(PACK)
    mc.call(f"{NS}/load")
    return mc

def S(mc, **kw):
    for k, v in kw.items():
        if isinstance(v, bool): v = B(v)
        elif isinstance(v, int): v = I(v)
        mc.storage.setdefault(TS, {})[k] = v

def out(mc): return mc.get(TS, "out")
def err(mc): return mc.get(TS, "err")
def ints(l): return [x.v for x in l]

def ref_matches(s, needle, n):
    if not needle: return []
    pos, i = [], 0
    cap = n if n > 0 else 0
    while i <= len(s) - len(needle):
        if s[i:i + len(needle)] == needle:
            pos.append(i); i += len(needle)
            if cap and len(pos) >= cap: break
        else: i += 1
    if n < 0: pos = pos[len(pos) - min(len(pos), -n):] if len(pos) > -n else pos
    return pos

def run():
    mc = fresh()
    # ---------- find / count / has
    samples = [("hello world", "o"), ("aaa", "aa"), ("abc", ""), ("ab", "abc"), ("a.b.c.d", "."),
               ('say "hi" now', '"'), ("back\\slash\\x", "\\"), ("çğşıöü çğ", "çğ"), ("xxxx", "x"),
               ("abcabcabc", "abc"), ("$(cmd) $(x)", "$("), ("tab\there", "\t"), ("line\nbreak", "\n")]
    for s, nd in samples:
        for n in (0, 1, 2, -1, -2, -5):
            mc = fresh(); S(mc, s=s, needle=nd, n=n)
            r, _ = mc.call(f"{NS}/find")
            want = ref_matches(s, nd, n)
            check(f"find({s!r},{nd!r},{n}) idx", ints(mc.get(TS, "idx")), want)
            check(f"find({s!r},{nd!r},{n}) ret", r[0] if isinstance(r, tuple) else r, len(want))
    for s, nd in samples:
        mc = fresh(); S(mc, s=s, needle=nd)
        r = mc.call(f"{NS}/count")[0]; check(f"count({s!r},{nd!r})", r, len(ref_matches(s, nd, 0)))
        mc = fresh(); S(mc, s=s, needle=nd)
        r = mc.call(f"{NS}/has")[0]; check(f"has({s!r},{nd!r})", 1 if ref_matches(s, nd, 1) else 0, 1 if r else 0)
    # ---------- safe
    for s, ok in (("plain", 1), ('with "q"', 0), ("with \\ b", 0), ("", 1), ("$(x) {}", 1)):
        mc = fresh(); S(mc, s=s); check(f"safe({s!r})", mc.call(f"{NS}/safe")[0], ok)
    # ---------- ctl
    for s_, want in (("plain", 0), ("", 0), ("a\nb", 1), ("a\rb", 1), ("a\tb", 1), ("\t", 1), ("x y", 0), ('q"', 0), ("end\n", 1)):
        mc = fresh(); S(mc, s=s_); check(f"ctl({s_!r})", mc.call(f"{NS}/ctl")[0], want)
    # ---------- replace
    rcases = [("a b c", " ", "_", 0), ("a b c", " ", "_", 1), ("a b c", " ", "_", -1), ("a b c d", " ", "_", -2),
              ("none", "x", "y", 0), ("aaaa", "aa", "b", 0), ("x.y.z", ".", "", 0), ("", "a", "b", 0),
              ("hello", "l", "LL", 0), ("1a2a3", "a", "--", 2), ("abc", "abc", "", 0), ("abc", "b", "$(x)", 0)]
    for s, nd, rp, n in rcases:
        mc = fresh(); S(mc, s=s, needle=nd, rep=rp, n=n)
        r = mc.call(f"{NS}/replace")[0]
        pos = ref_matches(s, nd, n); want = s; 
        for p in reversed(pos): want = want[:p] + rp + want[p + len(nd):]
        check(f"replace{(s,nd,rp,n)} out", out(mc), want)
        check(f"replace{(s,nd,rp,n)} ret", r, len(pos))
    for s, nd, rp in (('a"b', "a", "x"), ("ab", "a", 'x"y'), ("a\\b", "a", "x")):
        mc = fresh(); S(mc, s=s, needle=nd, rep=rp, n=0)
        mc.call(f"{NS}/replace")
        check(f"replace unsafe {(s,rp)}", (out(mc), err(mc) is not None), (None, True))
    # ---------- concat
    random.seed(7)
    for size in (0, 1, 2, 15, 16, 17, 40, 255, 256, 257, 700):
        parts = ["".join(random.choice("abcXYZ 09-_é") for _ in range(random.randint(0, 6))) for _ in range(size)]
        mc = fresh(); S(mc, list=list(parts))
        r = mc.call(f"{NS}/concat")[0]
        check(f"concat size={size}", (out(mc), r), ("".join(parts), 1))
    mc = fresh(); S(mc, list=["a", I(5), "b"]); mc.call(f"{NS}/concat"); check("concat numbers", out(mc), "a5b")
    mc = fresh(); S(mc, list=["a", 'b"c']); r = mc.call(f"{NS}/concat")[0]; check("concat unsafe", (r, out(mc), err(mc) is not None), (0, None, True))
    # ---------- insert
    for s, ins, at in (("hello", "XX", 0), ("hello", "XX", 3), ("hello", "XX", 5), ("", "a", 0), ("ab", "", 1)):
        mc = fresh(); S(mc, s=s, ins=ins, at=at); mc.call(f"{NS}/insert")
        check(f"insert{(s,ins,at)}", out(mc), s[:at] + ins + s[at:])
    for at in (-1, 6):
        mc = fresh(); S(mc, s="hello", ins="X", at=at); r = mc.call(f"{NS}/insert")[0]
        check(f"insert range {at}", (r, out(mc), err(mc) is not None), (0, None, True))
    # ---------- split
    def ref_split(s, sep, n, keep):
        if s == "": return [""]
        if sep == "": return list(s)
        pos = ref_matches(s, sep, n); segs, cur = [], 0
        for p in pos: segs.append(s[cur:p]); cur = p + len(sep)
        segs.append(s[cur:])
        return segs if keep else [x for x in segs if x != ""]
    scases = [("a,b,c", ",", 0, False), ("a,,b,", ",", 0, False), ("a,,b,", ",", 0, True), ("a,b,c,d", ",", 2, False),
              ("a,b,c,d", ",", -1, False), ("a,b,c,d", ",", -2, True), ("abc", "", 0, False), ("", ",", 0, False),
              ("a  b", " ", 0, False), ("a  b", " ", 0, True), (",,", ",", 0, False), ("x--y--z", "--", 0, False)]
    for s, sep, n, keep in scases:
        mc = fresh(); S(mc, s=s, sep=sep, n=n, keep_empty=keep)
        r = mc.call(f"{NS}/split")[0]
        want = ref_split(s, sep, n, keep)
        check(f"split{(s,sep,n,keep)}", (mc.get(TS, "out"), r), (want, len(want)))
    # ---------- case
    txt = "Hello WORLD 123 çğşıöü ÇĞŞİÖÜ ΑΒΓ αβγ Привет ПРИВЕТ ǅ"
    for fn, f_ascii, f_full in (("lower", str.lower, True), ("upper", str.upper, True)):
        mc = fresh(); S(mc, s=txt); mc.call(f"{NS}/{fn}")
        want = "".join((c.lower() if fn == "lower" else c.upper()) if c.isascii() else c for c in txt)
        check(f"{fn} fast", out(mc), want)
        mc = fresh(); S(mc, s=txt); mc.call(f"{NS}/{fn}_full")
        want = ""
        for c in txt:
            m = c.lower() if fn == "lower" else c.upper()
            want += m if len(m) == 1 else c
        check(f"{fn}_full", out(mc), want)
    mc = fresh(); S(mc, s=""); mc.call(f"{NS}/lower"); check("lower empty", out(mc), "")
    mc = fresh(); S(mc, s='a"B'); r = mc.call(f"{NS}/lower")[0]; check("lower unsafe", (r, out(mc)), (0, None))
    # ---------- numbers
    ncases = {"42": I(42), "-7": I(-7), "007": I(7), "3.14": Num(3.14, "d"), "-0.5": Num(-0.5, "d"),
              "123456789": I(123456789), "-123456789": I(-123456789), "0": I(0)}
    for s, want in ncases.items():
        mc = fresh(); S(mc, s=s); r = mc.call(f"{NS}/to_number")[0]
        check(f"to_number({s!r})", (r, out(mc)), (1, want))
    for s in ("", "-", "abc", "12a", "--1", "1.2.3", "1.", ".5", "-.5", "1234567890", "1e5", " 5", "5 ", "+5", "{a:1}", "1b"):
        mc = fresh(); S(mc, s=s); r = mc.call(f"{NS}/to_number")[0]
        check(f"to_number reject({s!r})", (r, out(mc), err(mc) is not None), (0, None, True))
    for v, want in ((I(5), "5"), ("x", "x"), (B(1), "1")):
        mc = fresh(); S(mc, **{"in": v}); r = mc.call(f"{NS}/to_string")[0]
        check(f"to_string({v!r})", (r, out(mc)), (1, want))
    # ---------- num_check messages
    msgs = {("", False): "empty input", ("-", False): "no digits after '-'", ("-", True): "no digits",
            ("12a", False): "contains a non-digit character", ("1.2", False): "contains a non-digit character",
            ("1.2.3", True): "more than one '.'", (".5", True): "malformed decimal point", ("5.", True): "malformed decimal point"}
    for (s, dot), want in msgs.items():
        mc = fresh(); S(mc, s=s, allow_dot=dot); r = mc.call(f"{NS}/num_check")[0]
        check(f"num_check{(s,dot)}", (r, err(mc)), (0, want))
    for s, dot in (("0", False), ("-12", False), ("12", True), ("-1.5", True), ("10.25", True)):
        mc = fresh(); S(mc, s=s, allow_dot=dot); r = mc.call(f"{NS}/num_check")[0]
        check(f"num_check ok{(s,dot)}", (r, err(mc)), (1, None))
    # ---------- scan_deny
    for tbl, s, want in (("deny_name", "shop.use-1_x", 0), ("deny_name", "bad name", 1), ("deny_name", "a/b", 1), ("deny_name", "x§", 1),
                         ("deny_name", "çğş", 0), ("deny_tag", "ok_tag", 0), ("deny_tag", "a:b", 1), ("deny_tag", "(x)", 0), ("deny_name", "(x)", 1),
                         ("deny_name", "a$b", 1), ("deny_name", "a'b", 1), ("deny_name", "", 0)):
        mc = fresh(); S(mc, s=s, tbl=tbl); r = mc.call(f"{NS}/scan_deny")[0]
        check(f"scan_deny({tbl},{s!r})", r, want)
    # ---------- budget
    mc = fresh(); S(mc, s="x" * 400, needle="x", rep="yy", n=0); mc.call(f"{NS}/replace")
    check("replace 400 chars output", out(mc), "yy" * 400)
    check("replace 400 chars command budget", mc.count < 65536, True)
    print("  command count for replace(400 chars):", mc.count)
    mc = fresh(); S(mc, s="Ab" * 100); mc.call(f"{NS}/lower"); print("  command count for lower(200 chars):", mc.count)
    mc2 = fresh(); S(mc2, s="Ab" * 100); mc2.call(f"{NS}/scan_deny") if False else None
    return mc

def main():
    mc = run()
    print(f"checks={total} failures={len(fails)}")
    for f in fails[:40]: print("FAIL", f)
    ws = sorted(set(mc.warnings))
    print("emulator warnings:", ws[:10] if ws else "none")
    sys.exit(1 if fails else 0)

sys.setrecursionlimit(200000)
threading.stack_size(512 * 1024 * 1024)
t = threading.Thread(target=main); t.start(); t.join()
