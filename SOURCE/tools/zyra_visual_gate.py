#!/usr/bin/env python3
"""ZYRA UI Consistency Gate — local render/orchestration layer (L2).

Runs deterministic and Flutter checks, captures *candidate* screenshots when
asked, compares only explicitly approved baselines, and writes permanent
evidence. It never invokes AI, changes product code, approves a baseline or
enables a schedule.

Usage:
  python3 tools/zyra_visual_gate.py
  python3 tools/zyra_visual_gate.py --force --full --capture-candidates

Governance: OA-ZYRA-257 · DR-ZYRA-214.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import re
import shlex
import subprocess
import sys
import time
from pathlib import Path


TOOLS = Path(__file__).resolve().parent
SOURCE = TOOLS.parent
ZYRA = SOURCE.parent
GATE = ZYRA / "SYSTEM" / "tools" / "ui_gate"
REPORTS = GATE / "REPORTS"
CANDIDATES = GATE / "CANDIDATES"
VISUAL_STATE = GATE / "visual_state.json"
MATRIX_FILE = GATE / "state_matrix.json"
CONFIG_FILE = GATE / "ui_gate_config.json"
L1_STATE = GATE / "state.json"
APPROVED_MANIFEST = SOURCE / "test/visual/approved/manifest.json"
CANDIDATE_DIR = SOURCE / "test/visual/candidates"
VISUAL_TEST = "test/visual/zyra_visual_regression_test.dart"


def _load(path: Path, default):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return default


def _save(path: Path, value) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(temporary, path)


def _sha_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def _ui_files():
    paths = set((SOURCE / "lib").rglob("*.dart"))
    paths.update((SOURCE / "test/visual").rglob("*.dart"))
    paths.update((SOURCE / "assets").rglob("*"))
    paths.update([SOURCE / "pubspec.yaml", CONFIG_FILE, MATRIX_FILE, APPROVED_MANIFEST])
    return sorted(path for path in paths if path.exists() and path.is_file())


def _fingerprint():
    files = {}
    for path in _ui_files():
        try:
            key = str(path.relative_to(SOURCE))
        except ValueError:
            key = "ZYRA/" + str(path.relative_to(ZYRA))
        files[key] = _sha_bytes(path.read_bytes())[:16]
    tree = _sha_bytes(json.dumps(files, sort_keys=True).encode("utf-8"))[:16]
    return tree, files


def _run(name: str, command, timeout: int = 1200):
    started = time.monotonic()
    env = dict(os.environ)
    env.update(
        {
            "CI": "true",
            "FLUTTER_SUPPRESS_ANALYTICS": "true",
            "DART_SUPPRESS_ANALYTICS": "true",
        }
    )
    try:
        completed = subprocess.run(
            command,
            cwd=SOURCE,
            env=env,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
        output = (completed.stdout or "") + (completed.stderr or "")
        failure_cases = sorted(set(
            match.strip()
            for match in re.findall(
                r"The test description was:\s*\n\s*([^\n]+)", output
            )
            if match.strip()
        ))
        return {
            "name": name,
            "command": " ".join(shlex.quote(str(value)) for value in command),
            "exit_code": completed.returncode,
            "passed": completed.returncode == 0,
            "duration_s": round(time.monotonic() - started, 2),
            "failure_cases": failure_cases,
            "output_tail": "\n".join(output.strip().splitlines()[-35:]),
        }
    except subprocess.TimeoutExpired as error:
        return {
            "name": name,
            "command": " ".join(shlex.quote(str(value)) for value in command),
            "exit_code": 124,
            "passed": False,
            "duration_s": round(time.monotonic() - started, 2),
            "output_tail": f"Timed out after {timeout}s: {error}",
        }


def _candidate_manifest(tree: str, matrix: dict) -> dict:
    CANDIDATES.mkdir(parents=True, exist_ok=True)
    screenshots = []
    for path in sorted(CANDIDATE_DIR.glob("*.png")):
        screenshots.append(
            {
                "id": path.stem,
                "source_path": str(path.relative_to(SOURCE)),
                "sha256": _sha_bytes(path.read_bytes()),
                "bytes": path.stat().st_size,
                "approved": False,
            }
        )
    manifest = {
        "schema_version": 1,
        "status": "candidate-only-not-authoritative",
        "programme": "OA-ZYRA-257",
        "generated": dt.datetime.now(dt.timezone.utc).isoformat(),
        "source_fingerprint": tree,
        "automatic_promotion_allowed": False,
        "matrix_fixture_count": len(matrix.get("render_fixtures", [])),
        "screenshots": screenshots,
    }
    _save(CANDIDATES / "manifest.json", manifest)
    return manifest


def _expected_render_count(matrix: dict) -> int:
    total = 0
    for fixture in matrix.get("render_fixtures", []):
        total += len(fixture.get("devices", []))
        if fixture.get("large_text"):
            total += 1
    return total


def _fixture_for_case(case: str, matrix: dict) -> tuple[dict, str, bool]:
    """Return governed fixture metadata encoded in a Flutter test case."""
    case_id = case.split(" renders without", 1)[0]
    parts = case_id.split("__")
    fixture_id = parts[0] if parts else case_id
    device = parts[1] if len(parts) > 1 else "unknown"
    large_text = "text-130" in parts[2:]
    fixture = next(
        (
            item
            for item in matrix.get("render_fixtures", [])
            if item.get("id") == fixture_id
        ),
        {},
    )
    return fixture, device, large_text


def _finding_detail(rule: str, key: str, step: dict, matrix: dict) -> dict:
    if rule == "UIG-L2-RENDER":
        fixture, device, large_text = _fixture_for_case(key, matrix)
        return {
            "severity": "HIGH",
            "screen": fixture.get("screen", "Visual fixture"),
            "source_file": VISUAL_TEST,
            "role": fixture.get("role", "representative"),
            "plan": fixture.get("plan", "representative"),
            "state": fixture.get("state", "render"),
            "device": device,
            "accessibility": "130% text" if large_text else "normal text",
            "evidence": f"Flutter render case failed: {key}",
            "expected": "The representative screen renders within its device bounds with no Flutter layout exception.",
            "actual": "The render produced an overflow or another layout exception; candidate evidence was retained and not approved.",
            "impact": "Content can clip, overlap or become unusable for the represented device/state.",
            "recommended_correction": "Inspect the named screen and shared component at this device width, correct the responsive layout, then rerun the same fixture.",
            "owner": "Codex",
            "related_decision": "DR-ZYRA-214",
        }

    if rule == "UIG-L2-FUNCTIONAL":
        return {
            "severity": "CRITICAL",
            "screen": "Application test suite",
            "source_file": "test/",
            "role": "all",
            "plan": "all",
            "state": "functional validation",
            "device": "representative",
            "accessibility": "as declared by test",
            "evidence": f"Flutter test case failed: {key}",
            "expected": "The named functional/widget test passes alongside the visual suite.",
            "actual": "The named case failed during the complete Flutter suite.",
            "impact": "A functional regression or nondeterministic test boundary may exist beyond visual appearance.",
            "recommended_correction": "Reproduce the named test in isolation and with the full suite, then fix the product defect or test isolation boundary.",
            "owner": "Codex",
            "related_decision": "DR-ZYRA-214",
        }

    check_details = {
        "format check": {
            "severity": "MEDIUM",
            "screen": "Repository UI source",
            "source_file": "lib/ and test/",
            "expected": "Dart UI and test sources already match the deterministic formatter.",
            "actual": "dart format reported files that would change.",
            "impact": "Formatting drift makes review noisier and can conceal meaningful UI changes.",
            "recommended_correction": "Format the reported files in an owned, reviewable change without altering product intent.",
        },
        "flutter analyze": {
            "severity": "CRITICAL",
            "screen": "Application build",
            "source_file": "lib/ and test/",
            "expected": "Flutter static analysis completes with no errors.",
            "actual": "flutter analyze failed.",
            "impact": "The application may not compile or may contain a broken production path.",
            "recommended_correction": "Resolve analyzer errors before any UI feature or release is marked complete.",
        },
        "zyra structural/reference check": {
            "severity": "HIGH",
            "screen": "Application structure",
            "source_file": "tools/zyra_check.py",
            "expected": "ZYRA's structural/reference contract passes for current sources.",
            "actual": "The structural/reference checker reported unresolved references or contract drift.",
            "impact": "Reference drift can leave stale architecture, invalid calls or misleading validation evidence.",
            "recommended_correction": "Review each reported site against analyzer truth and the current architecture; fix source or checker false positives explicitly.",
        },
        "complete Flutter suite": {
            "severity": "CRITICAL",
            "screen": "Application test suite",
            "source_file": "test/",
            "expected": "The complete Flutter suite passes.",
            "actual": "One or more Flutter tests failed.",
            "impact": "A functional regression may exist beyond visual appearance.",
            "recommended_correction": "Resolve or explicitly classify each failing test before release.",
        },
    }
    detail = check_details.get(
        step["name"],
        {
            "severity": "HIGH",
            "screen": "UI gate",
            "source_file": step.get("command", "tools/"),
            "expected": f"{step['name']} passes.",
            "actual": f"{step['name']} exited {step.get('exit_code')}.",
            "impact": "The UI gate cannot attest this validation layer.",
            "recommended_correction": "Inspect the permanent failed-check evidence and correct or classify the failure.",
        },
    )
    return {
        **detail,
        "role": "all",
        "plan": "all",
        "state": "validation",
        "device": "all",
        "accessibility": "not applicable",
        "evidence": f"{step['name']} exited {step.get('exit_code')}; command: {step.get('command')}",
        "owner": "Codex",
        "related_decision": "DR-ZYRA-214",
    }


def _normalise_legacy_findings(ledger: dict) -> None:
    """Correct the one pre-v1 parser shape without erasing its history."""
    for row in ledger.values():
        case = row.get("case") or ""
        if row.get("rule") != "UIG-L2-RENDER" or " renders without" in case:
            continue
        row.update(
            rule="UIG-L2-FUNCTIONAL",
            severity="CRITICAL",
            screen="Application test suite",
            source_file="test/",
            role="all",
            plan="all",
            state="functional validation",
            device="representative",
            accessibility="as declared by test",
            evidence=f"Flutter test case failed: {case}",
            expected="The named functional/widget test passes alongside the visual suite.",
            actual="The named case failed during the complete Flutter suite.",
            impact="A functional regression or nondeterministic test boundary may exist beyond visual appearance.",
            recommended_correction="Reproduce the named test in isolation and with the full suite, then fix the product defect or test isolation boundary.",
            classification_note="Historical case reclassified after the parser learned to distinguish visual and functional test names; occurrence history retained.",
        )


def _report(
    run_id: str,
    tree: str,
    changed,
    steps,
    verdict: str,
    duration: float,
    matrix: dict,
    candidate_manifest: dict,
    approved_count: int,
    l1: dict,
    new_count: int,
    resolved_count: int,
    ledger: dict,
) -> Path:
    today = dt.date.today().isoformat()
    report = REPORTS / f"ZYRA_VISUAL_AUDIT_{today}_{run_id}.md"
    REPORTS.mkdir(parents=True, exist_ok=True)
    counts = l1.get("last_run", {}).get("counts", {})
    render_count = _expected_render_count(matrix)
    lines = [
        f"# ZYRA VISUAL AUDIT — {today} · run {run_id}",
        "",
        f"**Verdict:** {verdict}  ",
        f"**Source fingerprint:** `{tree}` · **duration:** {duration:.1f}s · **cost:** $0.00 · **AI calls:** 0  ",
        f"**Governance:** OA-ZYRA-257 · DR-ZYRA-214 · baselines may not update automatically",
        "",
        "## Coverage measured",
        "",
        f"- Render variants executed: **{render_count}** across "
        f"{len(matrix.get('render_fixtures', []))} representative fixtures.",
        f"- Roles declared: {', '.join(matrix.get('roles', []))}.",
        f"- Devices: {', '.join(device.get('id', '?') for device in matrix.get('devices', []))}.",
        f"- Candidate screenshots present: {len(candidate_manifest.get('screenshots', []))}.",
        f"- Approved baselines compared: {approved_count}.",
        f"- L1 live findings: {sum(counts.values())} "
        f"(critical {counts.get('CRIT', 0)}, high {counts.get('HIGH', 0)}, "
        f"medium {counts.get('MED', 0)}, low {counts.get('LOW', 0)}).",
        f"- L2 findings: new {new_count} · resolved {resolved_count}.",
        "",
        "## Changed inputs",
        "",
    ]
    if changed:
        lines.extend(f"- `{path}`" for path in changed)
    else:
        lines.append("- Forced audit; no fingerprint delta was required.")
    lines.extend(["", "## Deterministic and render checks", ""])
    for step in steps:
        mark = "PASS" if step["passed"] else "FAIL"
        lines.append(
            f"- **{mark} — {step['name']}** · {step['duration_s']:.2f}s · "
            f"exit {step['exit_code']} · `{step['command']}`"
        )
        if step.get("failure_cases"):
            lines.append(
                "  - Failed cases: "
                + "; ".join(f"`{case}`" for case in step["failure_cases"])
            )
    failed = [step for step in steps if not step["passed"]]
    if failed:
        lines.extend(["", "## Failed-check evidence", ""])
        for step in failed:
            lines.extend(
                [
                    f"### {step['name']}",
                    "",
                    "```text",
                    step.get("output_tail") or "No output captured.",
                    "```",
                    "",
                ]
            )
    lines.extend(["", "## Finding ledger", ""])
    open_findings = [
        (fingerprint, row)
        for fingerprint, row in ledger.items()
        if row.get("status") == "open"
    ]
    resolved_findings = [
        (fingerprint, row)
        for fingerprint, row in ledger.items()
        if row.get("status") == "resolved"
    ]
    if open_findings:
        lines.extend(
            [
                "### Open",
                "",
                "| Fingerprint | Severity | Screen / state | Role / plan | Device | Evidence | Expected / actual | Impact / correction | Owner | Status / trace |",
                "|---|---|---|---|---|---|---|---|---|---|",
            ]
        )
        for fingerprint, row in sorted(open_findings):
            expected_actual = f"Expected: {row.get('expected', '—')} Actual: {row.get('actual', '—')}"
            impact_correction = f"Impact: {row.get('impact', '—')} Correction: {row.get('recommended_correction', '—')}"
            values = [
                f"`{fingerprint}`",
                row.get("severity", "—"),
                f"{row.get('screen', '—')} / {row.get('state', '—')}",
                f"{row.get('role', '—')} / {row.get('plan', '—')}",
                f"{row.get('device', '—')} · {row.get('accessibility', '—')}",
                row.get("evidence", "—"),
                expected_actual,
                impact_correction,
                row.get("owner", "—"),
                f"{row.get('status', '—')} · {row.get('programme', '—')} · {row.get('related_decision', '—')} · seen {row.get('count', 0)}×",
            ]
            lines.append("| " + " | ".join(str(value).replace("|", "\\|") for value in values) + " |")
    else:
        lines.append("No open L2 findings.")
    lines.extend(["", "### Resolved", ""])
    if resolved_findings:
        for fingerprint, row in sorted(resolved_findings):
            lines.append(
                f"- `{fingerprint}` {row.get('screen', row.get('step', 'check'))} — "
                f"resolved {row.get('resolved', 'date unavailable')} after {row.get('count', 0)} occurrence(s)."
            )
    else:
        lines.append("No L2 findings resolved in the current ledger yet.")
    lines.extend(
        [
            "",
            "## Baseline governance",
            "",
            (
                "No approved screenshot baselines exist yet. The PNGs in `test/visual/candidates/` "
                "are evidence for review, not design authority."
                if approved_count == 0
                else f"Compared {approved_count} explicitly approved manifest entries."
            ),
            "A changed render cannot replace an approved baseline. Fable checks intent; the Founder "
            "approves where required; a new version and full metadata are then filed manually.",
            "",
            "## Screen-matrix truth",
            "",
            "The matrix lists every required core screen. `render+widget` means a current screenshot "
            "fixture exists; `existing-widget+static` means current functional/static coverage exists "
            "but a dedicated approved screenshot is still pending. No coverage is overstated.",
            "",
            "## Cost and activation",
            "",
            "This run used local Python/Dart/Flutter only: $0.00. No overnight schedule was created or "
            "enabled. Activation remains blocked on Fable review and Founder baseline approval.",
            "",
        ]
    )
    report.write_text("\n".join(lines), encoding="utf-8")
    return report


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--full", action="store_true", help="run the complete Flutter test suite")
    parser.add_argument("--capture-candidates", action="store_true")
    args = parser.parse_args()

    started = time.monotonic()
    previous = _load(VISUAL_STATE, {"files": {}, "findings": {}, "history": []})
    tree, files = _fingerprint()
    changed = [path for path, sha in files.items() if previous.get("files", {}).get(path) != sha]
    removed = [path for path in previous.get("files", {}) if path not in files]
    if not args.force and not changed and not removed and previous.get("files"):
        print(f"VISUAL GATE: no relevant UI changes (tree {tree}) — skipped; cost $0.00")
        return 0

    steps = [
        _run("inventory", [sys.executable, "tools/zyra_ui_inventory.py"]),
        _run("L1 deterministic gate", [sys.executable, "tools/zyra_ui_gate.py", "--force"]),
        _run(
            "format check",
            ["dart", "format", "--output=none", "--set-exit-if-changed", "lib", "test"],
        ),
        _run("flutter analyze", ["flutter", "analyze", "--no-pub"]),
        _run(
            "structural checker self-tests",
            [sys.executable, "-m", "unittest", "tools/test_zyra_check.py"],
        ),
        _run("zyra structural/reference check", [sys.executable, "tools/zyra_check.py", "--quiet"]),
        _run("visual render and approved-baseline checks", ["flutter", "test", "--no-pub", VISUAL_TEST]),
    ]
    if args.capture_candidates:
        steps.append(
            _run(
                "candidate screenshot capture",
                [
                    "flutter",
                    "test",
                    "--no-pub",
                    VISUAL_TEST,
                    "--update-goldens",
                    "--dart-define=ZYRA_CAPTURE_CANDIDATES=true",
                ],
            )
        )
    if args.full:
        steps.append(_run("complete Flutter suite", ["flutter", "test", "--no-pub"], timeout=1800))

    matrix = _load(MATRIX_FILE, {})
    candidate_manifest = _candidate_manifest(tree, matrix)
    approved = _load(APPROVED_MANIFEST, {})
    approved_count = len(approved.get("baselines", []))
    l1 = _load(L1_STATE, {})

    now = dt.date.today().isoformat()
    ledger = previous.get("findings", {})
    _normalise_legacy_findings(ledger)
    live = set()
    new_count = 0
    run_failure_fingerprints = set()
    for step in steps:
        if step["passed"]:
            continue
        cases = step.get("failure_cases") or []
        is_render_step = step["name"] in (
            "visual render and approved-baseline checks",
            "candidate screenshot capture",
        )
        keys = [
            ("UIG-L2-RENDER" if is_render_step else "UIG-L2-FUNCTIONAL", case)
            for case in cases
        ]
        if not keys:
            keys = [("UIG-L2-CHECK", step["name"])]
        for rule, key in keys:
            fingerprint = hashlib.sha1(f"{rule}|{key}".encode("utf-8")).hexdigest()[:12]
            live.add(fingerprint)
            if fingerprint in run_failure_fingerprints:
                continue
            run_failure_fingerprints.add(fingerprint)
            row = ledger.get(fingerprint)
            details = _finding_detail(rule, key, step, matrix)
            if row is None:
                ledger[fingerprint] = {
                    "rule": rule,
                    "step": step["name"],
                    "case": key if rule == "UIG-L2-RENDER" else None,
                    "first_seen": now,
                    "last_seen": now,
                    "count": 1,
                    "status": "open",
                    "programme": "OA-ZYRA-257",
                    **details,
                }
                new_count += 1
            else:
                row.update(
                    last_seen=now,
                    count=row.get("count", 0) + 1,
                    status="open",
                    **details,
                )
    resolved_count = 0
    for fingerprint, row in ledger.items():
        if row.get("status") == "open" and fingerprint not in live:
            row.update(status="resolved", resolved=now)
            resolved_count += 1

    failed = [step for step in steps if not step["passed"]]
    if failed:
        verdict = "FAIL"
    elif approved_count == 0:
        verdict = "BASELINE-PENDING"
    else:
        l1_counts = l1.get("last_run", {}).get("counts", {})
        verdict = "PASS-WITH-FINDINGS" if sum(l1_counts.values()) else "PASS"

    duration = time.monotonic() - started
    run_id = _sha_bytes(f"{tree}|{time.time()}".encode("utf-8"))[:8]
    report = _report(
        run_id,
        tree,
        changed + [f"REMOVED: {path}" for path in removed],
        steps,
        verdict,
        duration,
        matrix,
        candidate_manifest,
        approved_count,
        l1,
        new_count,
        resolved_count,
        ledger,
    )
    history = previous.get("history", [])[-29:]
    history.append(
        {
            "date": now,
            "run_id": run_id,
            "tree": tree,
            "verdict": verdict,
            "duration_s": round(duration, 1),
            "cost_usd": 0.0,
            "screens_checked": _expected_render_count(matrix),
            "approved_baselines": approved_count,
            "new_regressions": new_count,
            "resolved_regressions": resolved_count,
            "report": str(report.relative_to(ZYRA)),
        }
    )
    state = {
        "schema_version": 1,
        "programme": "OA-ZYRA-257",
        "files": files,
        "findings": ledger,
        "history": history,
        "last_run": history[-1],
        "coverage": {
            "roles": matrix.get("roles", []),
            "devices": [device.get("id") for device in matrix.get("devices", [])],
            "fixtures": len(matrix.get("render_fixtures", [])),
            "render_variants": _expected_render_count(matrix),
        },
        "baseline_status": approved.get("status", "missing"),
        "recurring_enabled": False,
    }
    _save(VISUAL_STATE, state)
    print(
        f"VISUAL GATE: {verdict} — {_expected_render_count(matrix)} render variants · "
        f"{approved_count} approved baselines · $0.00 · report: {report}"
    )
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
