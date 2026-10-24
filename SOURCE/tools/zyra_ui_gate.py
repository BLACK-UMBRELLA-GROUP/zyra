#!/usr/bin/env python3
"""ZYRA UI CONSISTENCY GATE — deterministic layer (Phase 0).

Governed by: ZYRA_UI_CONSISTENCY_GATE_CURRENT_VERSION_V1.md (SYSTEM/DOCUMENTS)
Register:    OA-ZYRA-257 · Decision: DR-ZYRA-214 · Author: Fable, 2026-08-23

The $0 first line of the Founder's UI Consistency & Visual Regression
directive: pure-stdlib, deterministic, run-anywhere (Mac terminal or the
device VM). It NEVER changes app code, never calls any AI, and never
replaces a baseline — it measures, fingerprints, deduplicates and reports.
Codex's screenshot/golden layer sits above it; Fable/Founder judgement sits
above that.

Usage:
  python3 tools/zyra_ui_gate.py            # change-gated (skips if no UI change)
  python3 tools/zyra_ui_gate.py --force    # full run regardless

Outputs (SYSTEM/RESOURCES/UI_GATE/):
  REPORTS/ZYRA_UI_AUDIT_<date>_<runid>.md  — permanent report per run
  state.json                               — per-file shas + finding ledger
  suppressions.json                        — reviewed false-positives (by fingerprint)
"""

from __future__ import annotations

import hashlib
import json
import re
import sys
import time
from collections import Counter, defaultdict
from pathlib import Path

# ── locations ───────────────────────────────────────────────────────────────
TOOLS_DIR = Path(__file__).resolve().parent
SOURCE = TOOLS_DIR.parent                      # .../ZYRA/SOURCE
ZYRA = SOURCE.parent                           # .../ZYRA
LIB = SOURCE / "lib"
GATE_DIR = ZYRA / "SYSTEM" / "RESOURCES" / "UI_GATE"
REPORTS = GATE_DIR / "REPORTS"
STATE_F = GATE_DIR / "state.json"
SUPPRESS_F = GATE_DIR / "suppressions.json"

THEME_DIR = "lib/theme"
EXEMPT_DIRS = ("lib/dev/",)   # developer-only surfaces: separate rule set

# Terminology retired by governed documents (never in user-facing lib code).
RETIRED_TERMS = [
    ("Profile Unlock", "renamed Compatibility Unlock 2026-08-03 (ZYRA_PRICING)"),
    ("Unlock Profile", "renamed Compatibility Unlock 2026-08-03 (ZYRA_PRICING)"),
    ("Extended Guardian", "renamed Guardian+ (spec V5)"),
    ("GuardianNetworkPreview", "retired preview model (OA-ZYRA-251)"),
    ("£34.99", "retired One price; current Seeker One £29.99/month (DR-ZYRA-248)"),
    ("£39.99", "retired One price; current Seeker One £29.99/month (DR-ZYRA-248)"),
    ("£49.99", "retired combined One offer; role-specific One/Family (DR-ZYRA-248)"),
    ("£349.90", "yearly subscriptions retired; monthly only"),
    ("£399.90", "yearly subscriptions retired; monthly only"),
]
# £9.99 survives in EXACTLY one place: the Compatibility Unlock Plus 5-pack.
PRICE_999_MAX = 1

DEV_WORDS = ["PROVISIONAL", "preview build", "mock data", "developer panel",
             "dev-only", "DEV —"]

SEV = {"CRIT": "\U0001f534", "HIGH": "\U0001f7e0", "MED": "\U0001f7e1",
       "LOW": "\U0001f7e2", "INFO": "ℹ️"}


def sha16(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()[:16]


def fp(rule: str, file: str, key: str) -> str:
    return hashlib.sha1(f"{rule}|{file}|{key}".encode()).hexdigest()[:12]


def rel(p: Path) -> str:
    return str(p.relative_to(SOURCE))


def strings_in(line: str):
    """Crude single-line Dart string-literal extractor (both quote kinds)."""
    out = []
    for q in ("'", '"'):
        i = 0
        while True:
            a = line.find(q, i)
            if a == -1:
                break
            b = a + 1
            buf = []
            while b < len(line):
                if line[b] == "\\":
                    buf.append(line[b:b + 2]); b += 2; continue
                if line[b] == q:
                    break
                buf.append(line[b]); b += 1
            if b >= len(line):
                break
            out.append("".join(buf))
            i = b + 1
    return out


def main() -> int:
    force = "--force" in sys.argv
    GATE_DIR.mkdir(parents=True, exist_ok=True)
    REPORTS.mkdir(parents=True, exist_ok=True)

    files = sorted(LIB.rglob("*.dart"))
    shas = {rel(p): sha16(p.read_bytes()) for p in files}
    tree_fp = sha16(json.dumps(shas, sort_keys=True).encode())

    state = {"files": {}, "findings": {}}
    if STATE_F.exists():
        try:
            state = json.loads(STATE_F.read_text())
        except Exception:
            pass
    suppress = set()
    if SUPPRESS_F.exists():
        try:
            suppress = {s["fingerprint"] for s in json.loads(SUPPRESS_F.read_text())}
        except Exception:
            pass

    changed = [f for f, s in shas.items() if state.get("files", {}).get(f) != s]
    removed = [f for f in state.get("files", {}) if f not in shas]
    if not changed and not removed and not force and state.get("files"):
        print(f"UI GATE: no UI file changes since last run (tree {tree_fp}) — skipped. Use --force for a full run.")
        return 0

    t0 = time.time()
    findings = []   # dicts: rule, sev, file, line, key, msg

    def add(rule, sev, file, line, key, msg):
        findings.append({"rule": rule, "sev": sev, "file": file, "line": line,
                         "key": key, "msg": msg, "fp": fp(rule, file, key)})

    # Parse theme colors for UIG-02 comparisons.
    theme_colors = {}
    zc = SOURCE / "lib/theme/zyra_colors.dart"
    if zc.exists():
        for m in re.finditer(r"(\w+)\s*=\s*Color\(0x([0-9A-Fa-f]{8})\)", zc.read_text()):
            theme_colors[m.group(2).upper()] = m.group(1)

    color_uses = defaultdict(list)          # hex -> [(file, line)]
    radius_hist = Counter(); radius_at = defaultdict(list)
    height_hist = Counter(); height_at = defaultdict(list)
    string_files = defaultdict(set)         # literal -> {files}
    class_files = defaultdict(set)          # normalised class name -> {files}
    imports = defaultdict(set)              # file -> set(imported rel paths)
    price999 = []

    for p in files:
        f = rel(p)
        in_theme = f.startswith(THEME_DIR)
        exempt = any(f.startswith(d) for d in EXEMPT_DIRS)
        text = p.read_text(errors="replace")
        lines = text.splitlines()
        for i, raw in enumerate(lines, 1):
            line = raw.split("//")[0] if not raw.lstrip().startswith("//") else ""
            comment_line = raw.lstrip().startswith("//")
            # colors (dev-panel surfaces exempt: toggle correctness, not palette purity)
            if not in_theme and not exempt:
                for m in re.finditer(r"Color\(0x([0-9A-Fa-f]{8})\)", line):
                    color_uses[m.group(1).upper()].append((f, i))
            # raw font sizes
            if not in_theme and re.search(r"\bfontSize:\s*\d", line):
                add("UIG-03", "MED", f, i, f"fontSize@{raw.strip()[:40]}",
                    "raw fontSize outside ZyraText token layer")
            # radii + heights
            for m in re.finditer(r"BorderRadius\.circular\(\s*(\d+(?:\.\d+)?)\s*\)", line):
                radius_hist[m.group(1)] += 1; radius_at[m.group(1)].append((f, i))
            for m in re.finditer(r"Size\.fromHeight\(\s*(\d+(?:\.\d+)?)\s*\)", line):
                height_hist[m.group(1)] += 1; height_at[m.group(1)].append((f, i))
            # banned APIs
            if re.search(r"\.withOpacity\(|\.withAlpha\(", line):
                add("UIG-08", "HIGH", f, i, "withOpacity/withAlpha",
                    "banned API (convention: withValues)")
            # imports for orphan analysis
            im = re.match(r"\s*(?:import|export)\s+'([^']+)'", raw)
            if im:
                imports[f].add(im.group(1))
            # class inventory
            cm = re.match(r"\s*class\s+(_?\w+)\s+extends\s+(?:StatelessWidget|StatefulWidget)", raw)
            if cm:
                class_files[cm.group(1).lstrip("_").lower()].add(f)
            if comment_line:
                continue
            # strings: retired terms, dev wording, duplicates, £9.99
            for s in strings_in(line):
                if len(s) >= 12 and not s.startswith("assets/"):
                    string_files[s].add(f)
                if not exempt:
                    for term, why in RETIRED_TERMS:
                        if term in s:
                            add("UIG-06", "HIGH", f, i, term,
                                f"retired term in UI string — {why}")
                    if "£9.99" in s:
                        price999.append((f, i, s[:60]))
                    for w in DEV_WORDS:
                        if w in s:
                            add("UIG-07", "MED", f, i, w,
                                "dev wording in a string outside lib/dev — verify it is developer-gated")

    # UIG-02 verdicts
    for hexv, uses in sorted(color_uses.items()):
        if hexv[2:] in ("FFFFFF", "000000"):
            continue  # white/black alpha veils are Flutter idiom, not palette drift
        nfiles = {u[0] for u in uses}
        if hexv in theme_colors:
            f0, l0 = uses[0]
            add("UIG-02", "MED", f0, l0, hexv,
                f"Color(0x{hexv}) duplicates theme token ZyraColors.{theme_colors[hexv]} — use the token ({len(uses)} use(s), {len(nfiles)} file(s))")
        elif len(nfiles) >= 3:
            f0, l0 = uses[0]
            add("UIG-02", "MED", f0, l0, hexv,
                f"Color(0x{hexv}) hard-coded in {len(nfiles)} files ({len(uses)} uses) — promote to a ZyraColors token")
        elif len(uses) >= 3:
            f0, l0 = uses[0]
            add("UIG-02", "LOW", f0, l0, hexv,
                f"Color(0x{hexv}) repeated {len(uses)}x in {f0} — local constant or token candidate")

    # UIG-04/05 one-off dimensions
    for v, n in radius_hist.items():
        if n == 1:
            f0, l0 = radius_at[v][0]
            add("UIG-04", "LOW", f0, l0, f"radius:{v}",
                f"one-off corner radius {v} (histogram has {len(radius_hist)} distinct values)")
    for v, n in height_hist.items():
        if n == 1:
            f0, l0 = height_at[v][0]
            add("UIG-05", "LOW", f0, l0, f"btnheight:{v}",
                f"one-off button height Size.fromHeight({v})")

    # UIG-06b £9.99 budget
    if len(price999) > PRICE_999_MAX:
        for f, i, s in price999:
            add("UIG-06", "HIGH", f, i, "£9.99-budget",
                f"£9.99 appears {len(price999)}x in lib (budget {PRICE_999_MAX}: the Unlock Plus 5-pack only): '{s}'")

    # UIG-09 duplicate long strings across ≥3 files
    for s, fs in sorted(string_files.items(), key=lambda kv: -len(kv[1])):
        if len(fs) >= 3:
            add("UIG-09", "LOW", sorted(fs)[0], 0, sha16(s.encode())[:8],
                f"string {s[:48]!r} duplicated across {len(fs)} files — canon/copy candidate")

    # UIG-10 orphan lib files (never imported; entrypoint + generated excluded)
    imported = set()
    for f, ims in imports.items():
        base = Path(f).parent
        for im in ims:
            if im.startswith("package:zyra/"):
                imported.add("lib/" + im[len("package:zyra/"):])
            elif not im.startswith(("package:", "dart:")):
                q = (base / im).resolve()
                try:
                    imported.add(rel(q))
                except ValueError:
                    pass
    for f in shas:
        if f in ("lib/main.dart",) or f.endswith(".g.dart"):
            continue
        if f not in imported:
            add("UIG-10", "MED", f, 0, "orphan",
                "dart file never imported from lib/ — dead/unreachable UI candidate")

    # UIG-11 same widget class name defined in multiple files
    for name, fs in sorted(class_files.items()):
        if len(fs) >= 2:
            add("UIG-11", "LOW", sorted(fs)[0], 0, name,
                f"widget class '{name}' defined in {len(fs)} files: {', '.join(sorted(fs))} — consolidation candidate")

    # ── dedup ledger (section 16 of the directive) ──────────────────────────
    now = time.strftime("%Y-%m-%d")
    ledger = state.get("findings", {})
    live_fps = set()
    new_ct = reopen_ct = 0
    for fnd in findings:
        k = fnd["fp"]
        live_fps.add(k)
        if k in suppress:
            fnd["suppressed"] = True
            continue
        row = ledger.get(k)
        if row is None:
            ledger[k] = {"rule": fnd["rule"], "file": fnd["file"], "key": fnd["key"],
                         "first_seen": now, "last_seen": now, "count": 1, "status": "open"}
            new_ct += 1
        else:
            if row.get("status") == "resolved":
                reopen_ct += 1
            row.update(last_seen=now, status="open", count=row.get("count", 0) + 1)
    resolved_ct = 0
    for k, row in ledger.items():
        if row.get("status") == "open" and k not in live_fps:
            row["status"] = "resolved"; row["resolved"] = now; resolved_ct += 1

    live = [f for f in findings if not f.get("suppressed")]
    counts = Counter(f["sev"] for f in live)
    verdict = ("ATTENTION" if counts["CRIT"] or counts["HIGH"]
               else "PASS-WITH-FINDINGS" if live else "CLEAN")
    run_id = sha16(f"{tree_fp}{time.time()}".encode())[:8]
    dur = time.time() - t0

    # ── report ──────────────────────────────────────────────────────────────
    rp = REPORTS / f"ZYRA_UI_AUDIT_{now}_{run_id}.md"
    L = []
    L.append(f"# ZYRA UI AUDIT — {now} · run {run_id} (deterministic layer)\n")
    L.append(f"Verdict: **{verdict}** · source tree fingerprint `{tree_fp}` · "
             f"{len(files)} dart files · {len(changed)} changed since last run · "
             f"{dur:.1f}s · cost $0.00 (no AI calls)\n")
    L.append(f"Findings: {SEV['CRIT']} {counts['CRIT']} · {SEV['HIGH']} {counts['HIGH']} · "
             f"{SEV['MED']} {counts['MED']} · {SEV['LOW']} {counts['LOW']} · "
             f"new {new_ct} · reopened {reopen_ct} · resolved {resolved_ct} · "
             f"suppressed {sum(1 for f in findings if f.get('suppressed'))}\n")
    if changed:
        L.append("<details><summary>Changed files</summary>\n")
        L.extend(f"- `{c}`" for c in changed[:60])
        if len(changed) > 60:
            L.append(f"- … and {len(changed)-60} more")
        L.append("</details>\n")
    L.append("## Design-token sources\n")
    L.append(f"- ZyraColors: {len(theme_colors)} named colour tokens · ZyraText / ZyraCardMetrics present")
    L.append(f"- Corner-radius histogram ({len(radius_hist)} distinct): " +
             ", ".join(f"{v}×{n}" for v, n in radius_hist.most_common(12)))
    L.append(f"- Button-height histogram: " +
             (", ".join(f"{v}×{n}" for v, n in height_hist.most_common(8)) or "none found") + "\n")
    order = {"CRIT": 0, "HIGH": 1, "MED": 2, "LOW": 3, "INFO": 4}
    for sev in ("CRIT", "HIGH", "MED", "LOW"):
        rows = [f for f in live if f["sev"] == sev]
        if not rows:
            continue
        L.append(f"## {SEV[sev]} {sev} ({len(rows)})\n")
        seen_fp = set()
        for f in sorted(rows, key=lambda x: (x["rule"], x["file"], x["line"])):
            if f["fp"] in seen_fp:
                continue
            seen_fp.add(f["fp"])
            sites = sum(1 for x in rows if x["fp"] == f["fp"])
            led = ledger.get(f["fp"], {})
            loc = f"{f['file']}" + (f":{f['line']}" if f["line"] else "")
            extra = f", {sites} sites" if sites > 1 else ""
            L.append(f"- `{f['fp']}` **{f['rule']}** `{loc}` — {f['msg']} "
                     f"(first {led.get('first_seen','?')}, seen {led.get('count',1)}×{extra})")
        L.append("")
    L.append("## Boundary\nThis layer changes nothing, decides nothing, and calls no AI. "
             "Genuine findings graduate to the OA register by Fable; suppressions require a reviewed entry in "
             "suppressions.json; the screenshot/golden layer (Codex) and baseline governance sit in the governed "
             "spec.\n")
    rp.write_text("\n".join(L))

    state.update(files=shas, findings=ledger, last_run={"date": now, "run_id": run_id,
                 "tree": tree_fp, "verdict": verdict, "counts": dict(counts),
                 "duration_s": round(dur, 1)})
    STATE_F.write_text(json.dumps(state, indent=1, sort_keys=True))
    if not SUPPRESS_F.exists():
        SUPPRESS_F.write_text(json.dumps(
            [{"fingerprint": "example000000", "reason": "template — replace",
              "reviewed_by": "Fable", "date": now}], indent=1))

    print(f"UI GATE: {verdict} — {len(live)} live findings "
          f"({counts['CRIT']} crit, {counts['HIGH']} high, {counts['MED']} med, {counts['LOW']} low); "
          f"report: {rp}")
    return 1 if counts["CRIT"] else 0


if __name__ == "__main__":
    sys.exit(main())
