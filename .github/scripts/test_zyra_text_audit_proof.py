#!/usr/bin/env python3
"""Small synthetic Q239 manifest/union failure paths; no Flutter corpus run."""

import ast
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from types import SimpleNamespace
import unittest
import uuid

import zyra_text_audit_proof as proof


REPO = Path(__file__).resolve().parents[2]
HEAD = "a" * 40
RUN = "123456"
ATTEMPT = "1"


class UnionProofTests(unittest.TestCase):
    def setUp(self):
        # Evidence is retained under build; these tests never delete files.
        base = Path(os.environ.get("ZYRA_PROOF_TEST_ROOT", REPO / "SOURCE/build/line144-proof-tests"))
        self.folder = base / (self._testMethodName + "-" + uuid.uuid4().hex)
        self.root = self.folder / "shards"
        self.root.mkdir(parents=True)
        self.jobs = {"head_sha": HEAD, "run_id": RUN, "run_attempt": ATTEMPT, "jobs": []}
        for setting, (width, height, scale, partition) in proof.SETTINGS.items():
            for index in range(len(partition)):
                label = f"{setting}-{index + 1}"
                folder = self.root / f"zyra-text-audit-{label}-attempt-{ATTEMPT}"
                folder.mkdir()
                state = {"group": "fixture", "state": "settled", "plan": "Seeker One",
                         "scroll_frame": 0, "viewport": f"{width}x{height}@{scale:.1f}",
                         "rendered_route": "settings", "tab": 4, "runs": 1, "pixels": 10}
                audit = {"setting": "normal" if setting == "normal-375" else setting,
                         "shard_index": index, "shard_count": len(partition),
                         "selected_suites": proof.expected_suites(setting, index),
                         "registered_suites": proof.SUITES,
                         "viewport": {"width": width, "height": height, "text_scale": scale},
                         "head_sha": HEAD, "run_id": RUN, "run_attempt": ATTEMPT,
                         "report_complete": True, "report_only": True,
                         "frames": 1, "runs": 1, "painted_pixels": 10, "raster_images": 1,
                         "viewports": [f"{width}x{height}@{scale:.1f}"], "coverage_gaps": [],
                         "wall_seconds": 1.5, "audited_states": [state],
                         "status": "fail", "failures": [{"text": "Sample", "ratio": 2.0}]}
                items = [{"group": "fixture", "state": "settled", "plan": "Seeker One",
                          "scroll_frame": 0, "screen": "settings", "width": width,
                          "height": height, "text_scale": scale,
                          "items": [{"text": "Sample", "ratio": 2.0,
                                     "required_ratio": 4.5, "pass": False}]}]
                proof.write_json(folder / "audit.json", audit)
                proof.write_json(folder / "items.json", items)
                self.refresh(folder)
                self.jobs["jobs"].append({
                    "id": len(self.jobs["jobs"]) + 1,
                    "name": f"Full text audit ({label})", "status": "completed", "conclusion": "success",
                    "run_id": int(RUN), "run_attempt": 1, "head_sha": HEAD,
                    "started_at": "2026-11-27T17:00:00Z", "completed_at": "2026-11-27T17:02:00Z",
                    "steps": [{"name": name, "conclusion": "success"} for name in (
                        "Run this audit setting and shard", "Prepare audit report and record result",
                        "Upload per-item raster report")],
                })

    def shard(self, setting="normal-375", index=0):
        return self.root / f"zyra-text-audit-{setting}-{index + 1}-attempt-{ATTEMPT}"

    def refresh(self, folder, **overrides):
        audit = proof.read_json(folder / "audit.json")
        manifest = {key: audit.get(key) for key in proof.METADATA}
        manifest.update({"label": folder.name.removeprefix("zyra-text-audit-").removesuffix("-attempt-1"),
                         "complete": True, "audit_outcome": "success", "process_seconds": 2,
                         "audit_sha256": proof.digest(folder / "audit.json"),
                         "items_sha256": proof.digest(folder / "items.json"), **overrides})
        proof.write_json(folder / "coverage.json", manifest)

    def mutate(self, field, value, folder=None):
        folder = folder or self.shard()
        audit = proof.read_json(folder / "audit.json")
        audit[field] = value
        proof.write_json(folder / "audit.json", audit)
        self.refresh(folder)

    def verify(self):
        return proof.verify(self.root, HEAD, RUN, ATTEMPT, self.jobs)

    def test_retains_failed_style_items_while_proving_complete_fixtures(self):
        result = self.verify()
        self.assertEqual(result["status"], "pass")
        self.assertEqual(result["artifact_count"], 19)
        self.assertEqual(result["shards"][0]["viewports"], ["375x667@1.0"])
        self.assertEqual(sum(shard["failed_items"] for shard in result["shards"]), 19)
        self.assertEqual(sum(shard["raw_findings"] for shard in result["shards"]), 19)
        self.assertEqual(result["product_colour_gate"], "not asserted")

    def test_rejects_fixture_red_even_with_complete_json(self):
        self.refresh(self.shard(), audit_outcome="failure")
        with self.assertRaisesRegex(proof.ProofError, "Fixture process failed"):
            self.verify()

    def test_rejects_failed_actual_hosted_step(self):
        self.jobs["jobs"][0]["steps"][0]["conclusion"] = "failure"
        with self.assertRaisesRegex(proof.ProofError, "Hosted step did not succeed"):
            self.verify()

    def test_rejects_failed_actual_job(self):
        self.jobs["jobs"][0]["conclusion"] = "failure"
        with self.assertRaisesRegex(proof.ProofError, "Hosted job did not succeed"):
            self.verify()

    def test_rejects_foreign_job_run(self):
        self.jobs["jobs"][0]["run_id"] = int(RUN) + 1
        with self.assertRaisesRegex(proof.ProofError, "Hosted job run differs"):
            self.verify()

    def test_rejects_incomplete_report(self):
        self.refresh(self.shard(), complete=False)
        with self.assertRaisesRegex(proof.ProofError, "Incomplete report"):
            self.verify()

    def test_rejects_progress_marked_complete(self):
        self.mutate("report_complete", False)
        with self.assertRaisesRegex(proof.ProofError, "Wrong report_complete"):
            self.verify()

    def test_rejects_missing_artifact(self):
        self.shard().rename(self.folder / "held-missing-artifact")
        with self.assertRaisesRegex(proof.ProofError, "exactly the 19"):
            self.verify()

    def test_rejects_duplicate_artifact(self):
        (self.root / "duplicate").mkdir()
        with self.assertRaisesRegex(proof.ProofError, "exactly the 19"):
            self.verify()

    def test_rejects_missing_items(self):
        (self.shard() / "items.json").rename(self.folder / "held-items.json")
        with self.assertRaisesRegex(proof.ProofError, "Missing or invalid evidence"):
            self.verify()

    def test_rejects_unpaired_items(self):
        proof.write_json(self.shard() / "items.json", [])
        with self.assertRaisesRegex(proof.ProofError, "Unpaired items"):
            self.verify()

    def test_rejects_all_provenance_mismatches(self):
        for field, value in (("head_sha", "b" * 40), ("run_id", "654321"),
                             ("run_attempt", "2"), ("shard_index", 1), ("shard_count", 4),
                             ("viewport", {"width": 375, "height": 932, "text_scale": 1.0})):
            with self.subTest(field=field):
                original = proof.read_json(self.shard() / "audit.json")
                self.mutate(field, value)
                with self.assertRaisesRegex(proof.ProofError, f"Wrong {field}"):
                    self.verify()
                proof.write_json(self.shard() / "audit.json", original)
                self.refresh(self.shard())

    def test_rejects_repeated_or_missing_suite(self):
        self.mutate("selected_suites", ["Seeker", "Seeker"])
        with self.assertRaisesRegex(proof.ProofError, "Wrong selected_suites"):
            self.verify()

    def test_rejects_no_real_raster(self):
        self.mutate("painted_pixels", 0)
        with self.assertRaisesRegex(proof.ProofError, "No real raster"):
            self.verify()

    def test_rejects_wrong_item_identity(self):
        items = proof.read_json(self.shard() / "items.json")
        items[0]["plan"] = "Guardian Basic"
        proof.write_json(self.shard() / "items.json", items)
        self.refresh(self.shard())
        with self.assertRaisesRegex(proof.ProofError, "Frame/item identity differs"):
            self.verify()

    def test_retains_raw_audit_observations_with_successful_fixture_process(self):
        observations = [{"coverage_error": "Synthetic retained probe observation"},
                        {"render_error": "Synthetic retained raster observation"}]
        self.mutate("failures", observations)
        result = self.verify()
        self.assertEqual(result["status"], "pass")
        self.assertEqual(result["shards"][0]["raw_findings"], 2)
        self.assertEqual(proof.read_json(self.shard() / "audit.json")["failures"], observations)
        self.assertEqual(proof.read_json(self.shard() / "audit.json")["status"], "fail")
        self.assertFalse(proof.read_json(self.shard() / "items.json")[0]["items"][0]["pass"])

    def test_preserves_shard_gaps_but_resolves_union(self):
        self.mutate("coverage_gaps", ["route:test"])
        result = self.verify()
        self.assertEqual(result["status"], "pass")
        self.assertEqual(result["shards"][0]["coverage_gaps"], ["route:test"])
        self.assertEqual(result["settings"]["normal-375"]["coverage_gaps"], [])

    def test_fails_nonzero_union_gap_and_cli(self):
        for index in range(5):
            self.mutate("coverage_gaps", ["route:test"], self.shard(index=index))
        result = self.verify()
        self.assertEqual(result["status"], "fail")
        self.assertEqual(result["settings"]["normal-375"]["coverage_gaps"], ["route:test"])
        jobs_file = self.folder / "jobs.json"
        output = self.folder / "proof.json"
        proof.write_json(jobs_file, self.jobs)
        run = subprocess.run([sys.executable, str(Path(proof.__file__)), "verify",
                              "--root", str(self.root), "--head", HEAD, "--run-id", RUN,
                              "--attempt", ATTEMPT, "--jobs", str(jobs_file), "--output", str(output)],
                             capture_output=True, text=True)
        self.assertEqual(run.returncode, 1)
        self.assertEqual(proof.read_json(output)["status"], "fail")

    def test_rejects_full_job_overhead_outside_budget(self):
        self.jobs["jobs"][0]["completed_at"] = "2026-11-27T17:25:01Z"
        with self.assertRaisesRegex(proof.ProofError, "exceeded 25 minutes"):
            self.verify()

    def test_rejects_process_outside_budget(self):
        self.refresh(self.shard(), process_seconds=1201)
        with self.assertRaisesRegex(proof.ProofError, "Invalid process time"):
            self.verify()

    def test_source_registry_partition_and_workflow_match(self):
        source = (REPO / "SOURCE/test/support/zyra_clearer_text_corpus.dart").read_text()
        registry = source.split("final _registeredSuites =", 1)[1].split("];", 1)[0]
        self.assertEqual(re.findall(r"\('([^']+)',", registry), proof.SUITES)
        for name, expected in (("_large375Buckets", proof.FOUR), ("_fiveShardBuckets", proof.FIVE)):
            literal = source.split(f"const {name} =", 1)[1].split(";", 1)[0].strip()
            self.assertEqual(ast.literal_eval(literal), expected)
        workflow = (REPO / ".github/workflows/zyra-ci.yml").read_text()
        labels = re.findall(r"^          - label: (.+)$", workflow, re.M)
        expected = [f"{setting}-{index + 1}" for setting, values in proof.SETTINGS.items()
                    for index in range(len(values[3]))]
        self.assertEqual(labels, expected)
        self.assertEqual(len(set(labels)), 19)
        self.assertIn("--dart-define=ZYRA_LINE126_REPORT_ONLY=true", workflow)
        self.assertIn("timeout-minutes: 25", workflow)
        self.assertIn("20m flutter test", workflow)

    def test_packager_retains_raw_report_and_failed_item_status(self):
        build = self.folder / "build"
        build.mkdir()
        audit_file = build / "line126-rebuild-contrast-normal-1.json"
        audit_file.write_bytes((self.shard() / "audit.json").read_bytes())
        records = proof.read_json(self.shard() / "items.json")
        (build / "line126-rebuild-contrast-normal-1-items.jsonl").write_text(
            "\n".join(json.dumps(row) for row in records) + "\n")
        output = self.folder / "packaged"
        proof.prepare(SimpleNamespace(build=build, output=output, label="normal-375-1",
                                      outcome="success", process_seconds=2))
        self.assertTrue(proof.read_json(output / "coverage.json")["complete"])
        self.assertEqual((output / "audit.json").read_bytes(), audit_file.read_bytes())
        self.assertFalse(proof.read_json(output / "items.json")[0]["items"][0]["pass"])

    def test_packager_marks_truncated_progress_incomplete(self):
        build = self.folder / "build"
        build.mkdir()
        audit = proof.read_json(self.shard() / "audit.json")
        audit["report_complete"] = False
        proof.write_json(build / "line126-rebuild-contrast-normal-1-progress.json", audit)
        (build / "line126-rebuild-contrast-normal-1-items.jsonl").write_text('{"items":[]}\n{"cut":')
        output = self.folder / "packaged"
        proof.prepare(SimpleNamespace(build=build, output=output, label="normal-375-1",
                                      outcome="failure", process_seconds=1200))
        manifest = proof.read_json(output / "coverage.json")
        self.assertFalse(manifest["complete"])
        self.assertEqual(manifest["audit_outcome"], "failure")
        self.assertEqual(len(proof.read_json(output / "items.json")), 1)


if __name__ == "__main__":
    unittest.main(verbosity=2)
