#!/usr/bin/env python3
"""Build the factual inventories used by the ZYRA UI gate.

This is an evidence generator, not a design authority. It observes the live
Flutter tree and overlays only the statuses explicitly listed in
SYSTEM/RESOURCES/UI_GATE/ui_gate_config.json. Unknown widgets stay
``observed``; unreferenced files stay ``candidate`` until Fable/Founder decide
what to archive or keep.

Governance: OA-ZYRA-257 · DR-ZYRA-214.
Cost: $0.00. Dependencies: Python standard library only.
"""

from __future__ import annotations

import collections
import datetime as dt
import hashlib
import json
import re
from pathlib import Path


TOOLS = Path(__file__).resolve().parent
SOURCE = TOOLS.parent
ZYRA = SOURCE.parent
LIB = SOURCE / "lib"
GATE = ZYRA / "SYSTEM" / "RESOURCES" / "UI_GATE"
INVENTORIES = GATE / "INVENTORIES"
CONFIG_FILE = GATE / "ui_gate_config.json"


def _json(path: Path, default):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return default


def _write_json(path: Path, value) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def _sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _rel(path: Path) -> str:
    return str(path.relative_to(SOURCE))


def _dart_strings(text: str):
    """Yield ordinary one-line Dart string literals and their line numbers."""
    pattern = re.compile(r"(?P<q>['\"])(?P<body>(?:\\.|(?!\1).)*?)(?P=q)")
    for line_no, line in enumerate(text.splitlines(), 1):
        if line.lstrip().startswith("//"):
            continue
        code = line.split("//", 1)[0]
        for match in pattern.finditer(code):
            yield match.group("body"), line_no


def _hist(values):
    counts = collections.Counter(values)
    return [
        {"value": value, "uses": count}
        for value, count in sorted(counts.items(), key=lambda item: (-item[1], str(item[0])))
    ]


def build_token_inventory(config: dict) -> dict:
    colors_file = SOURCE / "lib/theme/zyra_colors.dart"
    text_file = SOURCE / "lib/theme/zyra_text.dart"
    metrics_file = SOURCE / "lib/theme/zyra_card_metrics.dart"
    colors_text = colors_file.read_text(encoding="utf-8")
    text_text = text_file.read_text(encoding="utf-8")
    metrics_text = metrics_file.read_text(encoding="utf-8")

    color_tokens = []
    seen = set()
    for match in re.finditer(
        r"static\s+(?:const\s+)?(?:Color|LinearGradient)\s+(?:get\s+)?(\w+)\s*(?:=>|=)",
        colors_text,
    ):
        name = match.group(1)
        if name in seen:
            continue
        seen.add(name)
        tail = colors_text[match.end() : match.end() + 260]
        literal = re.search(r"Color\(0x([0-9A-Fa-f]{8})\)", tail)
        color_tokens.append(
            {
                "name": name,
                "kind": "gradient" if "Gradient" in match.group(0) else "color",
                "first_literal": f"0x{literal.group(1).upper()}" if literal else None,
            }
        )

    typography = []
    for match in re.finditer(
        r"static\s+(?:double|TextStyle)\s+(\w+)\s*\(([^)]*)\)", text_text, re.S
    ):
        params = " ".join(match.group(2).split())
        typography.append({"name": match.group(1), "parameters": params})
    for match in re.finditer(r"static\s+const\s+double\s+(\w+)\s*=\s*([0-9.]+)", text_text):
        typography.append({"name": match.group(1), "value": float(match.group(2))})

    metrics = [
        {"name": m.group(1), "value": float(m.group(2))}
        for m in re.finditer(
            r"static\s+const\s+double\s+(\w+)\s*=\s*([0-9.]+)", metrics_text
        )
    ]

    radii = []
    spacing = []
    icon_sizes = []
    button_heights = []
    durations = []
    curves = []
    gradients = 0
    shadows = 0
    borders = 0
    raw_font_sizes = []
    for path in sorted(LIB.rglob("*.dart")):
        text = path.read_text(encoding="utf-8", errors="replace")
        radii.extend(re.findall(r"BorderRadius\.circular\(\s*([0-9.]+)", text))
        button_heights.extend(re.findall(r"Size\.fromHeight\(\s*([0-9.]+)", text))
        durations.extend(re.findall(r"Duration\(milliseconds:\s*([0-9]+)", text))
        curves.extend(re.findall(r"\bCurves\.([A-Za-z0-9_]+)", text))
        raw_font_sizes.extend(re.findall(r"\bfontSize:\s*([0-9.]+)", text))
        for body in re.findall(r"EdgeInsets\.[A-Za-z]+\((.*?)\)", text, re.S):
            spacing.extend(re.findall(r"(?<![A-Za-z_])([0-9]+(?:\.[0-9]+)?)", body))
        for body in re.findall(r"\bIcon\((.*?)\)", text, re.S):
            size = re.search(r"\bsize:\s*([0-9.]+)", body)
            if size:
                icon_sizes.append(size.group(1))
        gradients += len(re.findall(r"\b(?:Linear|Radial|Sweep)Gradient\(", text))
        shadows += len(re.findall(r"\bBoxShadow\(", text))
        borders += len(re.findall(r"\bBorder\.(?:all|symmetric)\(", text))

    return {
        "schema_version": 1,
        "generated": dt.datetime.now(dt.timezone.utc).isoformat(),
        "programme": config["governance"]["programme"],
        "authority_note": "Observed from live token sources; this file does not approve new values.",
        "sources": [
            {"file": _rel(path), "sha256": _sha(path)}
            for path in (colors_file, text_file, metrics_file)
        ],
        "colors_and_gradients": color_tokens,
        "typography_api": typography,
        "card_metrics": metrics,
        "observed_usage": {
            "corner_radii": _hist(radii),
            "spacing_values": _hist(spacing),
            "icon_sizes": _hist(icon_sizes),
            "button_heights": _hist(button_heights),
            "animation_durations_ms": _hist(durations),
            "transition_curves": _hist(curves),
            "raw_font_sizes": _hist(raw_font_sizes),
            "gradient_constructors": gradients,
            "box_shadows": shadows,
            "border_constructors": borders,
        },
        "gaps_requiring_design_authority": [
            "Spacing, icon size, navigation dimension, shadow and animation values are observed but are not yet all named tokens.",
            "Observed frequency is evidence, not approval; one-off values require review before consolidation.",
        ],
    }


def _widget_classes(text: str):
    return re.findall(
        r"^class\s+([A-Za-z]\w+)\s+extends\s+(?:StatelessWidget|StatefulWidget)",
        text,
        re.M,
    )


def build_component_inventory(config: dict) -> dict:
    contracts = config.get("component_contracts", {})
    all_lib_text = {
        path: path.read_text(encoding="utf-8", errors="replace")
        for path in sorted(LIB.rglob("*.dart"))
    }
    components = []
    for path in sorted((LIB / "widgets").glob("*.dart")):
        text = all_lib_text[path]
        classes = _widget_classes(text)
        use_files = set()
        for other, other_text in all_lib_text.items():
            if other == path:
                continue
            if any(re.search(r"\b" + re.escape(name) + r"\s*\(", other_text) for name in classes):
                use_files.add(_rel(other))
        for name in classes or [path.stem]:
            contract = contracts.get(name, {})
            components.append(
                {
                    "name": name,
                    "implementation": _rel(path),
                    "file_sha256": _sha(path),
                    "observed_use_files": sorted(use_files),
                    "observed_use_count": len(use_files),
                    "status": contract.get(
                        "status", "observed-active" if use_files else "unreferenced-candidate"
                    ),
                    "family": contract.get("family"),
                    "approved_variants": contract.get("variants", []),
                    "replacement": contract.get("replacement"),
                    "decision": contract.get("decision"),
                }
            )

    by_name = collections.defaultdict(list)
    for path, text in all_lib_text.items():
        for name in _widget_classes(text):
            by_name[name.lower()].append(_rel(path))
    duplicates = [
        {"normalised_name": name, "files": files}
        for name, files in sorted(by_name.items())
        if len(files) > 1
    ]
    return {
        "schema_version": 1,
        "generated": dt.datetime.now(dt.timezone.utc).isoformat(),
        "programme": config["governance"]["programme"],
        "authority_note": "Current/retired statuses come only from ui_gate_config.json; unknown widgets remain observed.",
        "components": components,
        "duplicate_widget_names": duplicates,
    }


def build_copy_inventory(config: dict) -> dict:
    occurrences = collections.defaultdict(list)
    for path in sorted(LIB.rglob("*.dart")):
        text = path.read_text(encoding="utf-8", errors="replace")
        for value, line in _dart_strings(text):
            if len(value) >= 4:
                occurrences[value].append({"file": _rel(path), "line": line})

    terms = config.get("terminology", {})
    retired_rows = []
    for retired, replacement in terms.get("retired", {}).items():
        sites = []
        for value, value_sites in occurrences.items():
            if retired in value:
                sites.extend(value_sites)
        retired_rows.append(
            {"term": retired, "replacement": replacement, "live_sites": sites}
        )
    approved_rows = []
    for term in terms.get("approved", []):
        sites = []
        for value, value_sites in occurrences.items():
            if term in value:
                sites.extend(value_sites)
        approved_rows.append({"term": term, "live_site_count": len(sites)})
    duplicates = [
        {
            "text": value,
            "file_count": len({site["file"] for site in sites}),
            "site_count": len(sites),
            "sites": sites[:20],
        }
        for value, sites in occurrences.items()
        if len({site["file"] for site in sites}) >= 3
    ]
    duplicates.sort(key=lambda row: (-row["file_count"], row["text"]))
    return {
        "schema_version": 1,
        "generated": dt.datetime.now(dt.timezone.utc).isoformat(),
        "programme": config["governance"]["programme"],
        "authority_note": "The audit flags copy; it never rewrites product language.",
        "approved_terms": approved_rows,
        "retired_terms": retired_rows,
        "review_only_terms": terms.get("review_only", []),
        "cross_file_duplicate_strings": duplicates,
    }


def build_developer_inventory(config: dict) -> dict:
    dev_files = sorted((LIB / "dev").glob("*.dart"))
    tests = [
        SOURCE / "test/dev_scenario_panel_policy_test.dart",
        SOURCE / "test/global_dev_overlay_test.dart",
        SOURCE / "test/zyra_developer_access_test.dart",
        SOURCE / "test/guardian_network_preview_test.dart",
    ]
    combined = "\n".join(path.read_text(encoding="utf-8", errors="replace") for path in dev_files)
    retired = config.get("terminology", {}).get("retired", {})
    retired_hits = {
        term: len(re.findall(re.escape(term), combined))
        for term in retired
        if re.findall(re.escape(term), combined)
    }
    return {
        "schema_version": 1,
        "generated": dt.datetime.now(dt.timezone.utc).isoformat(),
        "programme": config["governance"]["programme"],
        "architecture": {
            "state": "ZyraDevScenario",
            "surface_coordinator": "ZyraDevSurfaceCoordinator",
            "global_overlay": "ZyraGlobalDevOverlay",
            "guardian_network": "GNContext/GNScene/GNStage",
        },
        "controls": ["Preview", "Actions", "Home", "Style"],
        "reset_detected": bool(re.search(r"\b(?:reset|resetAll)\s*\(", combined)),
        "release_guards_detected": bool(re.search(r"kReleaseMode|kDebugMode", combined)),
        "retired_term_hits": retired_hits,
        "verification_tests": [
            {"file": _rel(path), "exists": path.exists()}
            for path in tests
        ],
        "known_boundary": "Mock state is developer-only; production services remain authoritative.",
    }


def write_dead_ui_report(component_inventory: dict) -> Path:
    candidates = [
        row
        for row in component_inventory["components"]
        if row["observed_use_count"] == 0
    ]
    lines = [
        "# ZYRA Duplicate / Dead UI Report",
        "",
        f"**Generated:** {dt.datetime.now(dt.timezone.utc).isoformat()}",
        "**Programme:** OA-ZYRA-257 · **Decision:** DR-ZYRA-214",
        "",
        "This is reachability evidence, not deletion authority. Test-only, routed-by-name,",
        "developer-only and future components can legitimately have zero `lib/` consumers.",
        "Fable/Founder decide merge, archive, keep or remove; the gate changes nothing.",
        "",
        f"## Unreferenced widget candidates ({len(candidates)})",
        "",
        "| Component | File | Contract status | Replacement | Risk |",
        "|---|---|---|---|---|",
    ]
    for row in candidates:
        status = row["status"]
        risk = "Medium — inspect tests/routes before archival" if "retired" in status else "High — intent unknown"
        lines.append(
            f"| `{row['name']}` | `{row['implementation']}` | {status} | "
            f"{row.get('replacement') or '—'} | {risk} |"
        )
    duplicates = component_inventory.get("duplicate_widget_names", [])
    lines.extend(["", f"## Duplicate widget names ({len(duplicates)})", ""])
    if duplicates:
        for row in duplicates:
            lines.append(f"- `{row['normalised_name']}`: " + ", ".join(f"`{p}`" for p in row["files"]))
    else:
        lines.append("No same-named widget classes were detected.")
    lines.extend(
        [
            "",
            "## Queue discipline",
            "",
            "These observations remain under OA-ZYRA-257 until product/design triage.",
            "A separate OA is required only if Fable graduates a genuine independent finding.",
            "",
        ]
    )
    path = INVENTORIES / "DUPLICATE_DEAD_UI_REPORT.md"
    path.write_text("\n".join(lines), encoding="utf-8")
    return path


def main() -> int:
    INVENTORIES.mkdir(parents=True, exist_ok=True)
    config = _json(CONFIG_FILE, {})
    if not config:
        raise SystemExit(f"Missing or invalid configuration: {CONFIG_FILE}")
    token_inventory = build_token_inventory(config)
    component_inventory = build_component_inventory(config)
    copy_inventory = build_copy_inventory(config)
    developer_inventory = build_developer_inventory(config)
    outputs = {
        "DESIGN_TOKEN_INVENTORY.json": token_inventory,
        "COMPONENT_INVENTORY.json": component_inventory,
        "TERMINOLOGY_COPY_INVENTORY.json": copy_inventory,
        "DEVELOPER_TOGGLE_INVENTORY.json": developer_inventory,
    }
    for name, value in outputs.items():
        _write_json(INVENTORIES / name, value)
    dead_report = write_dead_ui_report(component_inventory)
    print(
        "UI INVENTORY: "
        f"{len(token_inventory['colors_and_gradients'])} colour/gradient tokens · "
        f"{len(component_inventory['components'])} widget entries · "
        f"{len(copy_inventory['cross_file_duplicate_strings'])} duplicate-copy candidates · "
        f"report {dead_report}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
