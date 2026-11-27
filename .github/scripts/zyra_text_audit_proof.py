#!/usr/bin/env python3
"""Package raw raster evidence and strictly prove the Q239 hosted corpus union.

Report-only permits recorded product style findings. It never permits an
unsuccessful fixture process, incomplete evidence or a missing obligation.
"""

import argparse
from collections import Counter
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import sys
import urllib.request


SUITES = [
    "Seeker", "Basic plans", "Guardian One", "Signup", "Walkthrough",
    "Membership", "Menus", "Ended", "Compatibility", "Chat", "Settings",
    "Safety", "Filters", "Circle", "Family", "Seekers", "Phone", "Focus",
    "Recovery", "Remaining routes", "Coverage entries", "Help and safety",
    "Eid gifts",
]
FIVE = [
    ["Seeker", "Walkthrough", "Compatibility", "Filters", "Phone"],
    ["Basic plans", "Membership", "Chat", "Safety", "Circle", "Focus", "Help and safety"],
    ["Guardian One", "Signup", "Menus", "Ended", "Settings", "Family", "Seekers", "Recovery", "Eid gifts"],
    ["Remaining routes"],
    ["Coverage entries"],
]
# The original 22-suite modulo-four partition, with Eid added to bucket 3.
FOUR = [[name for i, name in enumerate(SUITES[:22]) if i % 4 == shard]
        + (["Eid gifts"] if shard == 2 else []) for shard in range(4)]
SETTINGS = {
    "normal-375": (375, 667, 1.0, FIVE),
    "normal-430": (430, 932, 1.0, FIVE),
    "large-375": (375, 667, 1.3, FOUR),
    "large-430": (430, 932, 1.3, FIVE),
}
METADATA = ("setting", "shard_index", "shard_count", "selected_suites",
            "registered_suites", "viewport", "head_sha", "run_id", "run_attempt",
            "report_complete", "report_only", "frames", "runs", "painted_pixels",
            "viewports", "coverage_gaps", "wall_seconds")


class ProofError(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise ProofError(message)


def read_json(path):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError) as error:
        raise ProofError(f"Missing or invalid evidence: {path.name}") from error


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def prepare(args):
    """Retain complete raw JSON where available; mark partial streams honestly."""
    output = args.output
    output.mkdir(parents=True, exist_ok=True)
    reports = sorted(args.build.glob("line126-rebuild-contrast-*.json"))
    final = [p for p in reports if not p.name.endswith("-progress.json")]
    candidates = final or reports
    audit = {}
    if len(candidates) == 1:
        audit = read_json(candidates[0])
        (output / "audit.json").write_bytes(candidates[0].read_bytes())
    streams = sorted(args.build.glob("line126-rebuild-contrast-*-items.jsonl"))
    records, stream_complete = [], len(streams) == 1
    if len(streams) == 1:
        for line in streams[0].read_text().splitlines():
            try:
                records.append(json.loads(line))
            except ValueError:
                stream_complete = False
    write_json(output / "items.json", records)
    manifest = {key: audit.get(key) for key in METADATA}
    manifest.update({
        "label": args.label,
        "audit_outcome": args.outcome,
        "process_seconds": args.process_seconds,
        "complete": len(final) == 1 and audit.get("report_complete") is True
                    and stream_complete,
        "audit_sha256": digest(output / "audit.json") if audit else None,
        "items_sha256": digest(output / "items.json"),
    })
    write_json(output / "coverage.json", manifest)


def expected_suites(setting, index):
    # Registration order is stable even when the written bucket list differs.
    names = SETTINGS[setting][3][index]
    return [name for name in SUITES if name in names]


def parse_time(value):
    return dt.datetime.fromisoformat(value.replace("Z", "+00:00"))


def validate_jobs(jobs_document, labels, head, run_id, attempt):
    require(str(jobs_document.get("run_id")) == run_id, "Job run ID differs")
    require(str(jobs_document.get("run_attempt")) == attempt, "Job attempt differs")
    require(jobs_document.get("head_sha") == head, "Job head differs")
    jobs = jobs_document.get("jobs")
    require(isinstance(jobs, list), "Missing hosted jobs")
    result = {}
    for label in labels:
        matches = [job for job in jobs if job.get("name") == f"Full text audit ({label})"]
        require(len(matches) == 1, f"Missing or duplicate hosted job: {label}")
        job = matches[0]
        require(job.get("status") == "completed", f"Hosted job incomplete: {label}")
        require(job.get("conclusion") == "success", f"Hosted job did not succeed: {label}")
        require(str(job.get("run_id")) == run_id, f"Hosted job run differs: {label}")
        require(str(job.get("run_attempt")) == attempt, f"Hosted job attempt differs: {label}")
        require(job.get("head_sha") == head, f"Hosted job head differs: {label}")
        seconds = (parse_time(job["completed_at"]) - parse_time(job["started_at"])).total_seconds()
        require(0 < seconds <= 25 * 60, f"Hosted job exceeded 25 minutes: {label}")
        steps = job.get("steps", [])
        for name in ("Run this audit setting and shard", "Prepare audit report and record result",
                     "Upload per-item raster report"):
            matches = [step for step in steps if step.get("name") == name]
            require(len(matches) == 1 and matches[0].get("conclusion") == "success",
                    f"Hosted step did not succeed: {label}: {name}")
        result[label] = {"job_id": job.get("id"), "job_seconds": seconds,
                         "html_url": job.get("html_url")}
    return result


def validate_shard(folder, setting, index, head, run_id, attempt):
    label = f"{setting}-{index + 1}"
    width, height, scale, partition = SETTINGS[setting]
    viewport = {"width": width, "height": height, "text_scale": scale}
    tuple_name = f"{width}x{height}@{scale:.1f}"
    manifest = read_json(folder / "coverage.json")
    audit = read_json(folder / "audit.json")
    items = read_json(folder / "items.json")
    require(isinstance(manifest, dict) and isinstance(audit, dict), f"Bad report object: {label}")
    require(manifest.get("label") == label, f"Artifact label differs: {label}")
    require(manifest.get("complete") is True, f"Incomplete report: {label}")
    require(manifest.get("audit_outcome") == "success", f"Fixture process failed: {label}")
    require(isinstance(manifest.get("process_seconds"), (int, float))
            and 0 < manifest["process_seconds"] <= 20 * 60, f"Invalid process time: {label}")
    for filename in ("audit", "items"):
        require(manifest.get(f"{filename}_sha256") == digest(folder / f"{filename}.json"),
                f"Unpaired {filename} evidence: {label}")
    for key in METADATA:
        require(manifest.get(key) == audit.get(key), f"Manifest differs from audit {key}: {label}")
    require(audit.get("setting") == ("normal" if setting == "normal-375" else setting),
            f"Wrong setting: {label}")
    for key, value in (("shard_index", index), ("shard_count", len(partition)),
                       ("registered_suites", SUITES),
                       ("selected_suites", expected_suites(setting, index)),
                       ("viewport", viewport), ("head_sha", head),
                       ("run_id", run_id), ("run_attempt", attempt),
                       ("report_complete", True), ("report_only", True),
                       ("viewports", [tuple_name])):
        require(audit.get(key) == value, f"Wrong {key}: {label}")
    require(isinstance(audit.get("coverage_gaps"), list)
            and all(isinstance(gap, str) for gap in audit["coverage_gaps"]),
            f"Invalid coverage gaps: {label}")
    states = audit.get("audited_states")
    require(isinstance(states, list) and isinstance(items, list)
            and len(states) == len(items) == audit.get("frames") and len(states) > 0,
            f"Incomplete frames/items evidence: {label}")
    require(audit.get("runs", 0) > 0 and audit.get("painted_pixels", 0) > 0
            and audit.get("raster_images", 0) > 0, f"No real raster evidence: {label}")
    require(sum(row.get("runs", 0) for row in states) == audit["runs"]
            and sum(row.get("pixels", 0) for row in states) == audit["painted_pixels"],
            f"Raster totals differ: {label}")
    item_count = failed_items = 0
    for state, frame in zip(states, items):
        require(state.get("viewport") == tuple_name, f"Wrong frame viewport: {label}")
        require(all(frame.get(key) == value for key, value in
                    (("width", width), ("height", height), ("text_scale", scale))),
                f"Wrong item viewport: {label}")
        require(all(frame.get(key) == state.get(key)
                    for key in ("group", "state", "plan", "scroll_frame")),
                f"Frame/item identity differs: {label}")
        screen = state.get("rendered_route") or f"{state.get('group')}:tab{state.get('tab')}"
        require(frame.get("screen") == screen, f"Frame/item screen differs: {label}")
        require(isinstance(frame.get("items"), list), f"Missing raster items: {label}")
        for item in frame["items"]:
            require(isinstance(item, dict) and isinstance(item.get("pass"), bool),
                    f"Missing actual item status: {label}")
            item_count += 1
            failed_items += item["pass"] is False
    require(item_count > 0, f"No measured text items: {label}")
    failures = audit.get("failures")
    require(isinstance(failures, list), f"Missing raw findings: {label}")
    require(0 < audit.get("wall_seconds", 0) <= 20 * 60, f"Invalid audit wall time: {label}")
    require(audit["wall_seconds"] <= manifest["process_seconds"] + 1,
            f"Audit wall time exceeds process time: {label}")
    return {"label": label, **{key: audit[key] for key in METADATA},
            "audit_sha256": manifest["audit_sha256"], "items_sha256": manifest["items_sha256"],
            "audit_outcome": manifest["audit_outcome"], "process_seconds": manifest["process_seconds"],
            "raw_findings": len(failures), "items": item_count, "failed_items": failed_items}


def verify(root, head, run_id, attempt, jobs_document):
    expected = [(setting, index) for setting, values in SETTINGS.items()
                for index in range(len(values[3]))]
    names = {f"zyra-text-audit-{setting}-{index + 1}-attempt-{attempt}"
             for setting, index in expected}
    actual = {path.name for path in root.iterdir() if path.is_dir()}
    require(actual == names, "Expected exactly the 19 matching shard artifact directories")
    labels = [f"{setting}-{index + 1}" for setting, index in expected]
    timings = validate_jobs(jobs_document, labels, head, run_id, attempt)
    shards = [validate_shard(root / f"zyra-text-audit-{setting}-{index + 1}-attempt-{attempt}",
                             setting, index, head, run_id, attempt)
              for setting, index in expected]
    unions = {}
    for setting, values in SETTINGS.items():
        selected = [shard for shard in shards if shard["label"].startswith(setting + "-")]
        counts = Counter(name for shard in selected for name in shard["selected_suites"])
        require(counts == Counter(SUITES), f"Suite missing or repeated in union: {setting}")
        gaps = sorted(set.intersection(*(set(shard["coverage_gaps"]) for shard in selected)))
        unions[setting] = {"coverage_gaps": gaps, "suite_counts": dict(counts),
                           "frames": sum(shard["frames"] for shard in selected),
                           "raw_findings": sum(shard["raw_findings"] for shard in selected)}
    result = {"status": "fail" if any(value["coverage_gaps"] for value in unions.values()) else "pass",
              "head_sha": head, "run_id": run_id, "run_attempt": attempt,
              "artifact_count": len(shards), "settings": unions, "shards": shards,
              "hosted_jobs": timings, "product_colour_gate": "not asserted"}
    return result


def collect_jobs(output):
    base = os.environ["GITHUB_API_URL"]
    repo = os.environ["GITHUB_REPOSITORY"]
    run = os.environ["GITHUB_RUN_ID"]
    attempt = os.environ["GITHUB_RUN_ATTEMPT"]
    headers = {"Authorization": f"Bearer {os.environ['GITHUB_TOKEN']}",
               "Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28"}
    jobs = []
    for page in range(1, 100):
        url = f"{base}/repos/{repo}/actions/runs/{run}/attempts/{attempt}/jobs?per_page=100&page={page}"
        with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=30) as response:
            batch = json.load(response)["jobs"]
        jobs.extend(batch)
        if len(batch) < 100:
            break
    write_json(output, {"run_id": run, "run_attempt": attempt,
                        "head_sha": os.environ["GITHUB_SHA"], "jobs": jobs})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    subs = parser.add_subparsers(dest="command", required=True)
    package = subs.add_parser("prepare")
    package.add_argument("--build", type=Path, required=True)
    package.add_argument("--output", type=Path, required=True)
    package.add_argument("--label", required=True)
    package.add_argument("--outcome", required=True)
    package.add_argument("--process-seconds", type=float, required=True)
    jobs = subs.add_parser("jobs")
    jobs.add_argument("--output", type=Path, required=True)
    proof = subs.add_parser("verify")
    proof.add_argument("--root", type=Path, required=True)
    proof.add_argument("--head", required=True)
    proof.add_argument("--run-id", required=True)
    proof.add_argument("--attempt", required=True)
    proof.add_argument("--jobs", type=Path, required=True)
    proof.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.command == "prepare":
        prepare(args)
    elif args.command == "jobs":
        collect_jobs(args.output)
    else:
        try:
            result = verify(args.root, args.head, args.run_id, args.attempt, read_json(args.jobs))
        except (ProofError, KeyError, TypeError, ValueError, OSError) as error:
            result = {"status": "fail", "reason": str(error), "head_sha": args.head,
                      "run_id": args.run_id, "run_attempt": args.attempt}
        write_json(args.output, result)
        print(json.dumps({key: value for key, value in result.items()
                          if key not in ("shards", "hosted_jobs")}, sort_keys=True))
        return 0 if result["status"] == "pass" else 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
