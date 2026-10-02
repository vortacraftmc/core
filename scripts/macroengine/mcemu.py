"""A deliberately small Minecraft function interpreter.

Models only what pure-data code needs: storages (NBT), scoreboards, macros, execute
if/unless/store, function/return. Unknown commands are logged and treated as successful no-ops.
It is used to *test* algorithms, it is not a Minecraft implementation: anything it cannot
model is reported through `warnings` so a green run never hides an unsupported construct.
"""
import os, re, math

class Fail(Exception): pass
class Ret(Exception):
    def __init__(self, val, ok=True): self.val, self.ok = val, ok
class EmuError(Exception): pass

class Num:
    __slots__ = ("v", "t")
    def __init__(self, v, t): self.v, self.t = v, t
    def __eq__(self, o): return isinstance(o, Num) and self.t == o.t and self.v == o.v
    def __hash__(self): return hash((self.v, self.t))
    def __repr__(self): return f"{self.v}{'' if self.t in 'id' else self.t}"

def B(x): return Num(int(x), "b")
def I(x): return Num(int(x), "i")

# ------------------------------------------------------------------ SNBT
class Snbt:
    def __init__(self, s, i=0): self.s, self.i = s, i
    def ws(self):
        while self.i < len(self.s) and self.s[self.i] in " \t": self.i += 1
    def value(self):
        self.ws(); c = self.s[self.i]
        if c == "{": return self.compound()
        if c == "[": return self.lst()
        if c in "\"'": return self.string()
        return self.bare()
    def string(self):
        q = self.s[self.i]; self.i += 1; out = []
        esc = {"\\": "\\", '"': '"', "'": "'", "n": "\n", "r": "\r", "t": "\t", "b": "\b", "f": "\f", "s": " "}
        while True:
            if self.i >= len(self.s): raise EmuError("unterminated string")
            c = self.s[self.i]
            if c == "\\":
                n = self.s[self.i + 1]
                if n not in esc: raise EmuError(f"bad escape \\{n}")
                out.append(esc[n]); self.i += 2
            elif c == q: self.i += 1; return "".join(out)
            else: out.append(c); self.i += 1
    def bare(self):
        m = re.compile(r"[A-Za-z0-9_.+\-]+").match(self.s, self.i)
        if not m: raise EmuError(f"cannot parse value at {self.s[self.i:self.i+20]!r}")
        tok = m.group(0); self.i = m.end()
        nm = re.fullmatch(r"([-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?)([bBsSlLfFdD]?)", tok)
        if nm:
            body, suf = nm.groups()
            if suf: return Num(float(body) if suf.lower() in "fd" else int(body), suf.lower())
            return Num(float(body), "d") if re.search(r"[.eE]", body) else Num(int(body), "i")
        if tok == "true": return B(1)
        if tok == "false": return B(0)
        return tok
    def key(self):
        self.ws()
        if self.s[self.i] in "\"'": return self.string()
        m = re.compile(r"[A-Za-z0-9_.+\-]+").match(self.s, self.i)
        if not m: raise EmuError("bad key")
        self.i = m.end(); return m.group(0)
    def compound(self):
        self.i += 1; d = {}
        self.ws()
        if self.s[self.i] == "}": self.i += 1; return d
        while True:
            k = self.key(); self.ws()
            if self.s[self.i] != ":": raise EmuError("expected ':'")
            self.i += 1; d[k] = self.value(); self.ws()
            if self.s[self.i] == ",": self.i += 1; continue
            if self.s[self.i] == "}": self.i += 1; return d
            raise EmuError("expected ',' or '}'")
    def lst(self):
        self.i += 1; out = []; self.ws()
        if self.s[self.i] == "]": self.i += 1; return out
        while True:
            out.append(self.value()); self.ws()
            if self.s[self.i] == ",": self.i += 1; continue
            if self.s[self.i] == "]": self.i += 1; return out
            raise EmuError("expected ',' or ']'")

def parse_snbt(s):
    p = Snbt(s); v = p.value(); p.ws()
    if p.i != len(s): raise EmuError(f"trailing text after value: {s[p.i:]!r}")
    return v

# ------------------------------------------------------------------ paths
def parse_path(s, i=0):
    """Returns (nodes, end_index). Node: ('k',name) | ('i',n) | ('f',dict)"""
    nodes = []
    if s[i] == "{":
        p = Snbt(s, i); d = p.compound(); nodes.append(("f", d)); i = p.i
    else:
        k, i = _path_key(s, i); nodes.append(("k", k))
    while i < len(s):
        if s[i] == ".":
            k, i = _path_key(s, i + 1); nodes.append(("k", k))
        elif s[i] == "{" and nodes:
            p = Snbt(s, i); d = p.compound(); nodes.append(("f", d)); i = p.i
        elif s[i] == "[":
            j = s.index("]", i); body = s[i + 1:j]
            if re.fullmatch(r"-?\d+", body): nodes.append(("i", int(body))); i = j + 1
            else: raise EmuError(f"unsupported path index [{body}]")
        else: break
    return nodes, i

def _path_key(s, i):
    if s[i] == '"':
        p = Snbt(s, i); k = p.string(); return k, p.i
    m = re.compile(r"[A-Za-z0-9_+\-]+").match(s, i)
    if not m: raise EmuError(f"bad path key at {s[i:i+15]!r}")
    return m.group(0), m.end()

def nbt_match(have, want):
    if isinstance(want, dict):
        return isinstance(have, dict) and all(k in have and nbt_match(have[k], v) for k, v in want.items())
    if isinstance(want, list):
        return isinstance(have, list) and all(any(nbt_match(h, w) for h in have) for w in want)
    return have == want

def deepcopy(v):
    if isinstance(v, dict): return {k: deepcopy(x) for k, x in v.items()}
    if isinstance(v, list): return [deepcopy(x) for x in v]
    return v

def path_get(root, nodes):
    cur = root
    for n, a in nodes:
        if n == "k":
            if not isinstance(cur, dict) or a not in cur: return None
            cur = cur[a]
        elif n == "i":
            if not isinstance(cur, list): return None
            idx = a if a >= 0 else len(cur) + a
            if idx < 0 or idx >= len(cur): return None
            cur = cur[idx]
        elif n == "f":
            if not nbt_match(cur, a): return None
    return cur

def path_set(root, nodes, value):
    cur = root
    for k, (n, a) in enumerate(nodes):
        last = k == len(nodes) - 1
        if n == "k":
            if not isinstance(cur, dict): raise Fail("not a compound")
            if last: cur[a] = value; return
            if a not in cur: cur[a] = {}
            cur = cur[a]
        elif n == "i":
            if not isinstance(cur, list): raise Fail("not a list")
            idx = a if a >= 0 else len(cur) + a
            if idx < 0 or idx >= len(cur): raise Fail("index out of range")
            if last: cur[idx] = value; return
            cur = cur[idx]
        else: raise Fail("filter in set path")

def path_remove(root, nodes):
    parent = path_get(root, nodes[:-1]) if len(nodes) > 1 else root
    n, a = nodes[-1]
    if n == "k" and isinstance(parent, dict) and a in parent: del parent[a]; return
    if n == "i" and isinstance(parent, list):
        idx = a if a >= 0 else len(parent) + a
        if 0 <= idx < len(parent): del parent[idx]; return
    raise Fail("nothing to remove")

def as_string(v):
    if isinstance(v, str): return v
    if isinstance(v, Num):
        if v.t in "fd": return repr(float(v.v)).rstrip("0").rstrip(".") if v.v != int(v.v) else str(int(v.v)) + ".0"
        return str(v.v)
    return snbt_str(v)

def snbt_str(v):
    if isinstance(v, str): return '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'
    if isinstance(v, Num): return f"{v.v}{'' if v.t in 'id' else v.t}"
    if isinstance(v, list): return "[" + ",".join(snbt_str(x) for x in v) + "]"
    return "{" + ",".join(f"{k}:{snbt_str(x)}" for k, x in v.items()) + "}"

# ------------------------------------------------------------------ interpreter
class MC:
    CHAIN_LIMIT = 65536

    def __init__(self, pack):
        self.storage, self.scores, self.fns = {}, {}, {}
        self.log, self.warnings, self.count = [], [], 0
        self.depth = 0
        base = os.path.join(pack, "data")
        for ns in os.listdir(base):
            fdir = os.path.join(base, ns, "function")
            for root, _, names in os.walk(fdir):
                for n in names:
                    if n.endswith(".mcfunction"):
                        rel = os.path.relpath(os.path.join(root, n), fdir)[:-len(".mcfunction")].replace(os.sep, "/")
                        lines = [l.rstrip("\n") for l in open(os.path.join(root, n), encoding="utf-8")]
                        self.fns[f"{ns}:{rel}"] = [l for l in lines if l.strip() and not l.lstrip().startswith("#")]

    # storage helpers
    def st(self, sid): return self.storage.setdefault(sid, {})
    def put(self, sid, path, value):
        path_set(self.st(sid), parse_path(path)[0], value)
    def get(self, sid, path):
        return path_get(self.st(sid), parse_path(path)[0])
    def score(self, name, obj="macroengine.tmp"): return self.scores.get((name, obj))

    def call(self, fid, with_=None):
        self.count = 0
        return self.run_function(fid, with_)

    def run_function(self, fid, args=None):
        if fid not in self.fns: raise EmuError(f"unknown function {fid}")
        self.depth += 1
        if self.depth > 2000: raise EmuError("function nesting too deep")
        ret = (None, True)
        try:
            for line in self.fns[fid]:
                if line.startswith("$"):
                    if args is None: raise EmuError(f"{fid}: macro line without arguments")
                    line = self.substitute(line[1:], args, fid)
                self.count += 1
                if self.count > self.CHAIN_LIMIT: raise EmuError("max command chain length exceeded")
                try:
                    self.run(line)
                except Fail:
                    pass
        except Ret as r:
            ret = (r.val, r.ok)
        finally:
            self.depth -= 1
        return ret

    def substitute(self, line, args, fid):
        def rep(m):
            k = m.group(1)
            if k not in args: raise EmuError(f"{fid}: missing macro argument {k}")
            return as_string(args[k])
        return re.sub(r"\$\(([A-Za-z0-9_]+)\)", rep, line)

    # --- command dispatcher; returns (success, result)
    def run(self, cmd):
        cmd = cmd.strip()
        if cmd.startswith("execute "): return self.execute(cmd[8:].lstrip(), [])
        if cmd.startswith("return "): return self.do_return(cmd[7:])
        if cmd.startswith("function "): return self.do_function(cmd[9:])
        if cmd.startswith("data "): return self.do_data(cmd[5:])
        if cmd.startswith("scoreboard players "): return self.do_score(cmd[19:])
        if cmd.startswith(("tellraw", "say", "tag", "title", "scoreboard objectives", "schedule")):
            self.log.append(cmd); return (True, 1)
        self.warnings.append(f"unmodelled command: {cmd[:70]}")
        return (True, 1)

    def do_return(self, rest):
        if rest == "fail": raise Ret(0, False)
        if rest.startswith("run "):
            try: ok, res = self.run(rest[4:])
            except Fail: raise Ret(0, False)
            raise Ret(res if res is not None else 0, True)
        raise Ret(int(rest), True)

    def do_function(self, rest):
        m = re.fullmatch(r"(#?[a-z0-9_.\-]+:[a-z0-9_./\-]+)(?: with storage (\S+)(?: (.+))?)?", rest)
        if not m: raise EmuError(f"bad function command: {rest}")
        fid, sid, path = m.groups()
        if fid.startswith("#"): raise EmuError("function tags are not modelled")
        args = None
        if sid:
            args = self.st(sid) if not path else path_get(self.st(sid), parse_path(path)[0])
            if not isinstance(args, dict): raise Fail("macro source is not a compound")
        val, ok = self.run_function(fid, args)
        if val is None:
            self.last_noreturn = fid
        return (ok, val if val is not None else 0)

    def do_score(self, rest):
        p = rest.split()
        op = p[0]
        if op == "set": self.scores[(p[1], p[2])] = int(p[3]); return (True, int(p[3]))
        if op in ("add", "remove"):
            d = int(p[3]) * (1 if op == "add" else -1)
            self.scores[(p[1], p[2])] = self.scores.get((p[1], p[2]), 0) + d
            return (True, self.scores[(p[1], p[2])])
        if op == "get":
            if (p[1], p[2]) not in self.scores: raise Fail("no score")
            return (True, self.scores[(p[1], p[2])])
        if op == "reset": self.scores.pop((p[1], p[2]), None); return (True, 1)
        if op == "operation":
            a, ao, o, b, bo = p[1:6]
            if (b, bo) not in self.scores: self.warnings.append(f"operation reads unset score {b} {bo}"); raise Fail("unset source")
            x = self.scores.get((a, ao), 0); y = self.scores[(b, bo)]
            if o == "=": r = y
            elif o == "+=": r = x + y
            elif o == "-=": r = x - y
            elif o == "*=": r = x * y
            elif o == "/=":
                if y == 0: raise Fail("div0")
                r = x // y if (x >= 0) == (y > 0) or x % y == 0 else -(-x // y)
            elif o == "%=":
                if y == 0: raise Fail("mod0")
                r = x - y * math.floor(x / y)
            elif o == "<": r = min(x, y)
            elif o == ">": r = max(x, y)
            elif o == "><": self.scores[(a, ao)], self.scores[(b, bo)] = y, x; return (True, y)
            else: raise EmuError(f"operation {o}")
            self.scores[(a, ao)] = r; return (True, r)
        raise EmuError(f"scoreboard players {op}")

    def do_data(self, rest):
        m = re.match(r"(get|remove|modify) storage (\S+) ", rest)
        if not m: raise EmuError(f"bad data command: {rest}")
        verb, sid = m.groups(); i = m.end()
        nodes, j = parse_path(rest, i)
        root = self.st(sid)
        if verb == "get":
            v = path_get(root, nodes)
            if v is None: raise Fail("no data")
            scale = float(rest[j:].strip() or 1)
            if isinstance(v, Num): return (True, int(v.v * scale))
            if isinstance(v, (str, list, dict)): return (True, len(v))
        if verb == "remove":
            path_remove(root, nodes); return (True, 1)
        tail = rest[j:].strip()
        mm = re.match(r"(set|append) (value|from storage|string storage) ", tail)
        if not mm: raise EmuError(f"bad data modify: {tail[:60]}")
        mode, src = mm.groups(); body = tail[mm.end():]
        if src == "value": val = parse_snbt(body)
        else:
            sm = re.match(r"(\S+) ", body); ssid = sm.group(1)
            snodes, k = parse_path(body, sm.end())
            v = path_get(self.st(ssid), snodes)
            if v is None: raise Fail("source missing")
            if src == "from storage": val = deepcopy(v)
            else:
                s = as_string(v); rng = body[k:].split()
                a = int(rng[0]) if rng else 0
                b = int(rng[1]) if len(rng) > 1 else len(s)
                if a < 0 or b > len(s) or a > b: raise Fail("invalid substring")
                val = s[a:b]
        if mode == "append":
            cur = path_get(root, nodes)
            if not isinstance(cur, list): raise EmuError(f"append to non-list at {rest[:60]}")
            cur.append(val); return (True, 1)
        old = path_get(root, nodes)
        if old is not None and old == val: raise Fail("nothing changed")
        path_set(root, nodes, val); return (True, 1)

    # --- execute
    def execute(self, rest, stores):
        rest = rest.lstrip()
        if rest.startswith("run "):
            try:
                ok, res = self.run(rest[4:])
            except Fail:
                self._store(stores, False, 0); raise
            self._store(stores, ok, res); return (ok, res)
        m = re.match(r"(if|unless) score (\S+) (\S+) matches (\S+)\s*", rest)
        if m:
            pol, n, o, rng = m.groups()
            cond = self._range(self.scores.get((n, o)), rng, (n, o))
            return self._cond(pol, cond, rest[m.end():], stores)
        m = re.match(r"(if|unless) score (\S+) (\S+) (<=|>=|<|>|=) (\S+) (\S+)\s*", rest)
        if m:
            pol, a, ao, op, b, bo = m.groups()
            x, y = self.scores.get((a, ao)), self.scores.get((b, bo))
            if x is None or y is None: self.warnings.append(f"comparison reads unset score {a if x is None else b}"); cond = False
            else: cond = {"<": x < y, "<=": x <= y, ">": x > y, ">=": x >= y, "=": x == y}[op]
            return self._cond(pol, cond, rest[m.end():], stores)
        m = re.match(r"(if|unless) data storage (\S+) ", rest)
        if m:
            pol, sid = m.groups()
            nodes, j = parse_path(rest, m.end())
            cond = path_get(self.st(sid), nodes) is not None
            return self._cond(pol, cond, rest[j:], stores)
        m = re.match(r"store (result|success) score (\S+) (\S+)\s*", rest)
        if m:
            kind, n, o = m.groups()
            return self.execute(rest[m.end():], stores + [(kind, "score", n, o)])
        m = re.match(r"store (result|success) storage (\S+) ", rest)
        if m:
            kind, sid = m.groups()
            nodes, j = parse_path(rest, m.end())
            mm = re.match(r"\s*(int|byte|short|long|float|double) (\S+)\s*", rest[j:])
            if not mm: raise EmuError("bad store storage")
            return self.execute(rest[j + mm.end():], stores + [(kind, "storage", sid, nodes, mm.group(1), float(mm.group(2)))])
        raise EmuError(f"unsupported execute clause: {rest[:70]}")

    def _range(self, v, rng, key):
        if v is None:
            self.warnings.append(f"score matches on unset {key}"); return False
        lo, hi = (rng.split("..") + [""])[:2] if ".." in rng else (rng, rng)
        if ".." not in rng:
            return v == int(rng)
        return (lo == "" or v >= int(lo)) and (hi == "" or v <= int(hi))

    def _cond(self, pol, cond, rest, stores):
        ok = cond if pol == "if" else not cond
        if not ok:
            self._store(stores, False, 0); raise Fail("condition")
        if rest.strip() == "":
            self._store(stores, True, 1); return (True, 1)
        return self.execute(rest, stores)

    def _store(self, stores, ok, res):
        for st in stores:
            val = res if st[0] == "result" else (1 if ok else 0)
            if st[1] == "score": self.scores[(st[2], st[3])] = int(val)
            else:
                _, _, sid, nodes, typ, scale = st
                t = {"int": "i", "byte": "b", "short": "s", "long": "l", "float": "f", "double": "d"}[typ]
                path_set(self.st(sid), nodes, Num(int(val * scale) if t in "ibsl" else val * scale, t))
