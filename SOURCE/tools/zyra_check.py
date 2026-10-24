#!/usr/bin/env python3
"""ZYRA static checker — the errors that have actually broken this build.

WHY THIS EXISTS
---------------
`flutter analyze` is the real tool and this does not replace it. But an AI
session working on ZYRA often cannot run it: the Flutter SDK downloads from
storage.googleapis.com and packages from pub.dev, both unreachable from the
assistant's sandbox, and the resolved pub cache lives on the Founder's Mac.

So verification fell back to hand-written greps, which have produced false
alarms (methods inherited from ChangeNotifier reported as missing) and, worse,
missed real breakage. This encodes the checks properly, once.

WHAT IT CATCHES — every one of these has actually happened here
--------------------------------------------------------------
  1  BROKEN IMPORT      the Guardian rename moved files; four imports were
                        string literals pointing at ../wali/ and nothing
                        told us until the build failed.
  2  MISSING METHOD     `hydrateDecisions` was deleted with the block it sat
                        in. The caller in zyra_session_router survived,
                        syntactically valid and completely broken. Brace
                        counting cannot catch this class of mistake.
  3  BAD NAMED ARG      `ZyraText.subtext(color: null)` and
                        `chapterLabel(size: ...)` — passing an argument the
                        constructor does not declare.
  4  UNUSED IMPORT      left behind by refactors; harmless but they hide
                        which files genuinely depend on which.
  5  MISSING IMPORT     a project symbol used in a file that never imports
                        the file defining it.

WHAT IT DOES NOT CATCH
----------------------
Type errors, null-safety, most lints, anything inside Flutter or a package.
A clean run here is necessary, not sufficient. Still run flutter analyze.

USAGE
-----
  python3 tools/zyra_check.py            from SOURCE/
  python3 tools/zyra_check.py --quiet    findings only, exit 1 if any
"""

import os
import re
import sys
from collections import defaultdict

LIB = "lib"
QUIET = "--quiet" in sys.argv


# ---------------------------------------------------------------- lexing

def strip_code(src):
    """Remove comments and string bodies, preserving offsets.

    Offsets are preserved so a match index still maps to the right line.
    Earlier ad-hoc greps stripped strings by deleting them, which shifted
    every subsequent line number and made findings point at the wrong place.
    """
    out = list(src)
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c == "/" and i + 1 < n and src[i + 1] == "/":
            while i < n and src[i] != "\n":
                out[i] = " "
                i += 1
        elif c == "/" and i + 1 < n and src[i + 1] == "*":
            while i < n and not (src[i] == "*" and i + 1 < n and src[i + 1] == "/"):
                if src[i] != "\n":
                    out[i] = " "
                i += 1
            for j in range(i, min(i + 2, n)):
                out[j] = " "
            i += 2
        elif c in "'\"":
            # r'...' and '''...''' both collapse to blanks
            triple = src[i:i + 3] in ("'''", '"""')
            q = src[i:i + 3] if triple else c
            out[i] = " "
            i += len(q)
            while i < n:
                if src[i] == "\\":
                    out[i] = " "
                    if i + 1 < n and src[i + 1] != "\n":
                        out[i + 1] = " "
                    i += 2
                    continue
                if src[i:i + len(q)] == q:
                    for j in range(i, i + len(q)):
                        out[j] = " "
                    i += len(q)
                    break
                if src[i] != "\n":
                    out[i] = " "
                i += 1
        else:
            i += 1
    return "".join(out)


def line_of(src, idx):
    return src.count("\n", 0, idx) + 1


def collapse_generics(line):
    """`Future<({bool mine, bool theirs})>` -> `Future<>`.

    Declaration patterns treat the return type as one whitespace-free token,
    which is wrong the moment a generic contains a comma-space or a record
    type. That produced eight false 'missing method' reports against
    ZyraJourneyService on the first run — every one of them a method that
    plainly exists, which is exactly the kind of noise that trains someone
    to ignore the tool.
    """
    out, depth = [], 0
    for ch in line:
        if ch == "<":
            depth += 1
            out.append(ch)
        elif ch == ">":
            depth -= 1
            out.append(ch)
        elif depth > 0:
            continue
        else:
            out.append(ch)
    return "".join(out)


def dart_files():
    for root, _, files in os.walk(LIB):
        for f in sorted(files):
            if f.endswith(".dart"):
                yield os.path.join(root, f)


# ---------------------------------------------------------------- model

class Unit:
    def __init__(self, path):
        self.path = path
        with open(path, encoding="utf-8") as source:
            self.raw = source.read()
        self.code = strip_code(self.raw)
        self.imports = []            # (target, resolved_path_or_None, line)
        self.classes = {}            # name -> {methods:set, fields:set, ctor_params:set, static:set}
        self.top_level = set()       # top-level fns, consts, enums, typedefs

        for m in re.finditer(r"import\s+'([^']+)'", self.raw):
            t = m.group(1)
            resolved = None
            if not t.startswith(("package:", "dart:")):
                resolved = os.path.normpath(os.path.join(os.path.dirname(path), t))
            self.imports.append((t, resolved, line_of(self.raw, m.start())))

        self._parse_classes()
        self._parse_top_level()

    # -- class bodies -----------------------------------------------------

    def _body(self, open_brace):
        depth, i, n = 0, open_brace, len(self.code)
        while i < n:
            if self.code[i] == "{":
                depth += 1
            elif self.code[i] == "}":
                depth -= 1
                if depth == 0:
                    return self.code[open_brace + 1:i], i
            i += 1
        return self.code[open_brace + 1:], n

    def _parse_classes(self):
        pat = r"\b(?:abstract\s+|sealed\s+|final\s+|base\s+|mixin\s+)*(class|enum|mixin|extension)\s+(\w+)"
        for m in re.finditer(pat, self.code):
            kind, name = m.group(1), m.group(2)
            brace = self.code.find("{", m.end())
            if brace < 0:
                continue
            body, _ = self._body(brace)

            info = {"kind": kind, "methods": set(), "fields": set(),
                    "ctor_params": set(), "enum_values": set()}

            # LINE-BASED, deliberately. The first version used whole-body
            # regexes like `(?:[\w<>,\s?\[\]]+\s+)?(\w+)\s*\(` — a character
            # class containing \s followed by \s+ is ambiguous, so the engine
            # backtracks exponentially and the checker hung past 45s on this
            # codebase. Declarations live on one line in Dart; scanning lines
            # is both faster and far more predictable.
            for raw_line in body.split("\n"):
                ln = collapse_generics(raw_line.strip())
                if not ln or ln.startswith(("//", "*", "@")):
                    continue
                # named constructor: `const Foo._(...)`, `Foo.uploaded(...)`
                nc = re.match(r"(?:const\s+|factory\s+|static\s+)*"
                              + re.escape(name) + r"\.(\w+)\s*\(", ln)
                if nc:
                    info["methods"].add(nc.group(1))
                    continue
                # private unnamed-ish constructor written `Foo._();`
                if re.match(re.escape(name) + r"\._\s*\(", ln):
                    info["methods"].add("_")
                    continue
                # getters / setters
                g = re.match(r"(?:static\s+)?(?:[\w<>?\[\],]+\s+)?(get|set)\s+(\w+)", ln)
                if g:
                    info["methods"].add(g.group(2))
                    continue
                # `name(` possibly preceded by one return type token
                mm = re.match(r"(?:static\s+|external\s+|factory\s+)*"
                              r"(?:[\w<>?\[\],]+\s+)?(\w+)\s*\(", ln)
                if mm:
                    info["methods"].add(mm.group(1))
                # `Type name =` / `Type name;`
                fm = re.match(r"(?:static\s+|const\s+|final\s+|late\s+|var\s+)*"
                              r"(?:[\w<>?\[\],]+\s+)?(\w+)\s*(?:=|;)", ln)
                if fm:
                    info["fields"].add(fm.group(1))
            # named constructor params, incl. `this.x`, `super.key`, `required T x`
            for cm in re.finditer(re.escape(name) + r"\.?\w*\s*\(([^)]*)\)", body):
                for p in re.finditer(r"(?:this\.|super\.)?(\w+)\s*(?:,|=|\}|$)", cm.group(1)):
                    parameter = p.group(1)
                    info["ctor_params"].add(parameter)
                    # Dart exposes a private field-formal such as
                    # `required this._groups` to the same-library caller as
                    # `groups:`. Flutter analyze accepts that spelling; the
                    # fallback checker must not invent a BAD NAMED ARG.
                    if parameter.startswith("_") and len(parameter) > 1:
                        info["ctor_params"].add(parameter[1:])
            if kind == "enum":
                head = body.split(";")[0]
                for ev in re.finditer(r"\b([a-z]\w*)\b", head):
                    info["enum_values"].add(ev.group(1))
                info["fields"] |= info["enum_values"]
                info["methods"] |= {"values", "name", "index"}

            self.classes[name] = info

    def _parse_top_level(self):
        # Line-based for the same backtracking reason as _parse_classes.
        for raw in self.code.split("\n"):
            if not raw or raw[0].isspace():
                continue          # top level only: column 0
            line = collapse_generics(raw)
            m = re.match(r"(?:const|final|var)\s+(?:[\w<>?\[\],]+\s+)?(\w+)\s*=", line)
            if m:
                self.top_level.add(m.group(1))
                continue
            # top-level GETTER — `SupabaseClient get supabase => ...` in
            # main.dart. Missing this reported eleven files as having an
            # unused import of main.dart when every one of them uses
            # `supabase` on the next line.
            m = re.match(r"(?:[\w<>?\[\],]+\s+)?get\s+(\w+)", line)
            if m:
                self.top_level.add(m.group(1))
                continue
            # `(?:<>)?` — A GENERIC TOP-LEVEL FUNCTION. collapse_generics
            # turns `Future<T?> showZyraGlassDialog<T>({` into
            # `Future<> showZyraGlassDialog<>({`, so the name is followed
            # by the collapsed generic rather than by `(` and this pattern
            # missed it. Its non-generic neighbour showZyraGlassChoice
            # matched fine, which is why only one symbol was invisible.
            #
            # The cost was not theoretical: journey_timeline_screen.dart
            # imports zyra_glass_dialog.dart and calls
            # showZyraGlassDialog at :249, and this checker reported that
            # import as unused for weeks. A second audit on 2026-08-14
            # repeated the finding and recommended deleting the import,
            # which would have broken the build. A false positive that
            # survives long enough gets believed.
            m = re.match(r"(?:[\w<>?\[\],]+)\s+(\w+)\s*(?:<>)?\s*\(", line)
            if m:
                self.top_level.add(m.group(1))


# ---------------------------------------------------------------- checks

# Members that exist by inheritance, not declaration. Every one of these has
# produced a false alarm in a previous hand-rolled sweep.
INHERITED = {
    "addListener", "removeListener", "notifyListeners", "dispose", "setState",
    "build", "initState", "didChangeDependencies", "didUpdateWidget", "mounted",
    "createState", "toString", "hashCode", "noSuchMethod", "runtimeType",
    "copyWith", "then", "catchError", "whenComplete", "call", "of", "toList",
    "map", "where", "add", "remove", "contains", "clear", "length", "isEmpty",
    "isNotEmpty", "first", "last", "forEach", "join", "reduce", "fold", "cast",
    "values", "keys", "index", "name", "toDouble", "toInt", "abs", "clamp",
    # Every Dart class has an unnamed-constructor tear-off spelled `.new`
    # when that constructor exists. It is syntax, not a declared member.
    "new",
}

# ---------------------------------------------------------------- doc refs
#
# DANGLING DOC REF — added 2026-08-08, Founder-approved.
#
# Code comments cite governed documents by filename. The naming convention
# puts a version number IN the filename and RENAMES the file when a document
# is superseded, so a reference does not merely go stale — the file it names
# ceases to exist. Eight comments in the Guardian system point at
# WALI_ARCHITECTURE_CURRENT_VERSION_V5.md, which is gone.
#
# This is engineering invariant I1 applied to documentation: a permanent
# reference resting on a name the convention requires to change. See
# MASTER_STANDARDS/ZYRA_ENGINEERING_INVARIANTS.
#
# ── BASELINE. Thirteen references across five documents were already broken
# when this check was written. Shipping without a baseline would make the
# tool red from its first run, and a check that is always red is one people
# learn to ignore — worse than no check, because it looks like coverage.
#
# Reported as an explicit count, never as bare "clean". A baseline that
# reads as passing with no qualification is how debt becomes invisible.
#
# DO NOT ADD TO THIS SET. A new dangling reference is a finding. Entries may
# only be added by explicit governance approval, and the set must be EMPTY
# once the Option A rename lands — at which point delete it and this note.
DANGLING_BASELINE = {
    "WALI_ARCHITECTURE_CURRENT_VERSION_V5.md",   # 8 sites, now V6
    "BROWSE_UX_SPEC_CURRENT_VERSION_V1.md",      # 2 sites, now V4
    "BROWSE_UX_SPEC_CURRENT_VERSION_V3.md",      # 1 site,  now V4
    "ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4.md",   # 1 site,  now V5
    "IMAGE_HANDLING_CURRENT_VERSION_V1.md",      # 1 site,  now V2
}   # 13 sites. Counts measured by the check itself, not by the hand audit,
    # which transposed the two BROWSE_UX_SPEC rows and missed a sixth
    # document entirely (see ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3.md, still
    # an open finding pending governance approval).

# A reference worth checking looks like a governed document: SHOUTY_SNAKE,
# reasonably long. Two false-positive sources, both of which fired on the
# first hand-run of this logic and produced 7 phantoms out of 20 hits:
#
#   1. WRAPPED COMMENTS. A filename split across two comment lines yields
#      fragments — "V1.md", "VERSION_V1.md", "26.md". The uppercase-prefix
#      and length rules below reject them.
#   2. SPACES IN REAL FILENAMES. Documents like "Profile Information.md"
#      exist, so a bare token match yields "Information.md" and calls it
#      dangling. Handled by matching against real basenames AND their
#      last-token forms.
DOC_REF_RE = re.compile(r"\b([A-Z][A-Z0-9_]{7,}\.md)\b")


def _known_markdown_names(root):
    """Every .md basename under the ZYRA tree, plus the last space-separated
    token of each, so a reference to a document whose name contains spaces
    is not mistaken for a broken one."""
    names = set()
    for dirpath, _, files in os.walk(root):
        if "/.git" in dirpath:
            continue
        for f in files:
            if f.endswith(".md"):
                names.add(f)
                if " " in f:
                    names.add(f.rsplit(" ", 1)[-1])
    return names


def _comment_blocks(raw):
    """Contiguous `//` runs, unwrapped, with an offset->line map for each.

    Comments wrap mid-filename, and the break is always at an underscore:

        // ... (MATCH_UX_SPEC_CURRENT_
        // VERSION_V1.md). No backend yet ...

    Joining those with a space leaves the token split, and every tail then
    reads as a phantom reference — `VERSION_V1.md`, `CURRENT_VERSION_V3.md`.
    So a line ending in `_` joins with no separator; everything else joins
    with a space. Prose never ends a line in an underscore, and joining
    ordinary wrapped prose without one would manufacture the false positives
    this is here to avoid."""
    blocks, buf, spans = [], None, []
    for lineno, line in enumerate(raw.split("\n"), start=1):
        stripped = line.strip()
        if stripped.startswith("//"):
            body = stripped.lstrip("/").strip()
            if buf is None:
                buf = ""
            elif not buf.endswith("_"):
                buf += " "
            spans.append((len(buf), lineno))
            buf += body
        elif buf is not None:
            blocks.append((buf, spans))
            buf, spans = None, []
    if buf is not None:
        blocks.append((buf, spans))
    return blocks


def _line_of(spans, offset):
    """The source line a joined-block offset came from."""
    line = spans[0][1]
    for off, lineno in spans:
        if off > offset:
            break
        line = lineno
    return line


def check_doc_refs(units):
    """Report references to governed documents that no longer exist."""
    # SOURCE/tools/zyra_check.py -> ZYRA/
    zyra_root = os.path.dirname(os.path.dirname(os.path.abspath(LIB)))
    known = _known_markdown_names(zyra_root)
    baselined = set()

    for u in units:
        for text, spans in _comment_blocks(u.raw):
            for m in DOC_REF_RE.finditer(text):
                name = m.group(1)
                if name in known:
                    continue
                if name in DANGLING_BASELINE:
                    baselined.add(name)
                    continue
                report("DANGLING DOC REF", u.path, _line_of(spans, m.start()),
                       f"{name} — no such document. Cite the SYSTEM, not a "
                       f"versioned filename (Naming Conventions rule 5).")
    return len(baselined)


findings = defaultdict(list)


def report(kind, path, line, msg):
    findings[kind].append((path, line, msg))


def check(units):
    by_path = {u.path: u for u in units}
    # global symbol table: name -> defining file
    defined_in = {}
    for u in units:
        for c in u.classes:
            defined_in.setdefault(c, u.path)
        for t in u.top_level:
            defined_in.setdefault(t, u.path)

    all_classes = {}
    for u in units:
        for c, info in u.classes.items():
            all_classes[c] = info

    for u in units:
        # 1 — broken relative imports
        for target, resolved, ln in u.imports:
            if resolved and not os.path.exists(resolved):
                report("BROKEN IMPORT", u.path, ln, f"'{target}' does not exist")

        imported_paths = {r for _, r, _ in u.imports if r}

        # 2 + 3 — calls onto known project classes
        for m in re.finditer(r"\b([A-Z]\w+)\.(\w+)\s*(\()?", u.code):
            cls, member, is_call = m.group(1), m.group(2), m.group(3)
            if cls not in all_classes:
                continue
            info = all_classes[cls]
            known = info["methods"] | info["fields"] | info["ctor_params"] | {cls}
            if member in INHERITED or member in known:
                pass
            elif member[0].isupper():
                pass  # nested type reference
            else:
                report("MISSING MEMBER", u.path, line_of(u.raw, m.start()),
                       f"{cls}.{member} is not declared on {cls}")

            # named arguments actually passed
            if is_call and info["ctor_params"]:
                depth, i, n = 1, m.end(), len(u.code)
                while i < n and depth:
                    if u.code[i] == "(":
                        depth += 1
                    elif u.code[i] == ")":
                        depth -= 1
                    i += 1
                args = u.code[m.end():i - 1]
                top, d = "", 0
                for ch in args:
                    if ch in "([{":
                        d += 1
                    elif ch in ")]}":
                        d -= 1
                    elif d == 0:
                        top += ch
                # only check factories/ctors we fully parsed
                sig = info["methods"] | info["ctor_params"]
                for am in re.finditer(r"(?:^|,)\s*(\w+)\s*:", top):
                    arg = am.group(1)
                    if arg not in sig and member in info["methods"]:
                        report("BAD NAMED ARG", u.path, line_of(u.raw, m.start()),
                               f"{cls}.{member}(...) got '{arg}:' which it does not declare")

        # 4 — unused imports (project files only)
        for target, resolved, ln in u.imports:
            if not resolved or not os.path.exists(resolved):
                continue
            other = by_path.get(os.path.relpath(resolved))
            if other is None:
                continue
            exported = set(other.classes) | other.top_level
            if not exported:
                continue
            used_in_code = any(
                re.search(r"\b" + re.escape(s) + r"\b", u.code)
                for s in exported
            )
            # strip_code correctly blanks string bodies, but Dart executes
            # expressions inside `${...}`. Imports referenced only in an
            # interpolation must therefore count as used.
            used_in_interpolation = any(
                re.search(
                    r"\$\{[^}]*\b" + re.escape(s) + r"\b[^}]*\}",
                    u.raw,
                    re.DOTALL,
                )
                for s in exported
            )
            if not used_in_code and not used_in_interpolation:
                report("UNUSED IMPORT", u.path, ln, f"'{target}' — nothing from it is referenced")

        # 5 — project class used without importing its file
        for m in re.finditer(r"\b(Zyra[A-Z]\w+|_?[A-Z]\w*(?:Screen|Service|State|Sheet|Panel))\b", u.code):
            sym = m.group(1)
            home = defined_in.get(sym)
            if not home or home == u.path or sym in u.classes:
                continue
            if os.path.relpath(home) not in {os.path.relpath(p) for p in imported_paths}:
                report("MISSING IMPORT", u.path, line_of(u.raw, m.start()),
                       f"{sym} is defined in {home} which this file does not import")


# ---------------------------------------------------------------- main

def main():
    if not os.path.isdir(LIB):
        print("run me from SOURCE/ (no lib/ here)")
        return 2

    units = [Unit(p) for p in dart_files()]
    check(units)
    baselined = check_doc_refs(units)

    order = ["BROKEN IMPORT", "MISSING MEMBER", "BAD NAMED ARG",
             "MISSING IMPORT", "UNUSED IMPORT", "DANGLING DOC REF"]
    total = sum(len(findings[k]) for k in order)

    if not QUIET:
        print(f"ZYRA static check — {len(units)} files\n")
    for k in order:
        rows = findings[k]
        if not rows:
            if not QUIET:
                # The baseline is stated, never implied. "clean" on its own
                # would hide five documents' worth of known debt.
                if k == "DANGLING DOC REF" and baselined:
                    print(f"  {k:16s} PASS — {baselined} baselined "
                          f"reference(s) (scheduled for Option A), "
                          f"0 new findings")
                else:
                    print(f"  {k:16s} clean")
            continue
        print(f"\n  {k}  ({len(rows)})")
        seen = set()
        for path, ln, msg in rows:
            key = (path, msg)
            if key in seen:
                continue
            seen.add(key)
            print(f"    {path}:{ln}  {msg}")

    if not QUIET:
        print(f"\n  {total} finding(s). This does NOT replace flutter analyze.")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
