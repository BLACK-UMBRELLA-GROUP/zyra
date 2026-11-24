#!/usr/bin/env python3
"""Keep opt-in raster corpora out of ordinary test selection and CI shards."""

from contextlib import redirect_stderr, redirect_stdout
import importlib.util
from io import StringIO
import json
from pathlib import Path
import re
import unittest
from unittest.mock import patch


SCRIPT_DIRECTORY = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location(
    "zyra_test_scope", SCRIPT_DIRECTORY / "zyra_test_scope.py"
)
scope = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(scope)
SHARD_SPEC = importlib.util.spec_from_file_location(
    "zyra_test_shard", SCRIPT_DIRECTORY / "zyra_test_shard.py"
)
shard = importlib.util.module_from_spec(SHARD_SPEC)
SHARD_SPEC.loader.exec_module(shard)

DRIVERS = {
    "test/zyra_clearer_text_contrast_test.dart",
    "test/zyra_clearer_text_contrast_430_test.dart",
    "test/zyra_clearer_text_contrast_large_430_test.dart",
    "test/zyra_clearer_text_contrast_large_375_test.dart",
}
CONTROLS = "test/zyra_rendered_text_audit_controls_test.dart"


class RenderedTextCorpusScopeTest(unittest.TestCase):
    def selection_for(self, paths, tracked_paths=None, dependents=None):
        output, errors = StringIO(), StringIO()
        diff = "".join("M\0" + path + "\0" for path in sorted(paths)).encode()
        tracked_paths = tracked_paths or {
            "test/guardian_focus_dashboard_test.dart",
            "test/unrelated_test.dart",
        }
        tracked = "".join(
            "SOURCE/" + path + "\0" for path in sorted(tracked_paths)
        )

        def git_result(*arguments):
            if arguments[0] == "merge-base":
                return b""
            if arguments[0] == "diff":
                return diff
            if arguments == ("ls-files", "-z", "--", "SOURCE"):
                return tracked.encode()
            self.fail(f"Unexpected read-only git request: {arguments}")

        with (
            patch.object(scope, "git", side_effect=git_result) as git,
            patch.object(scope, "dependency_index", return_value=(dependents or {}, set())) as dependencies,
            patch.object(scope.sys, "argv", ["zyra_test_scope.py", "a" * 40]),
            redirect_stdout(output),
            redirect_stderr(errors),
        ):
            scope.main()
        return json.loads(output.getvalue()), git, dependencies

    def test_each_driver_change_requests_the_existing_ordinary_three_shards(self):
        workflow = (SCRIPT_DIRECTORY.parent / "workflows" / "zyra-ci.yml").read_text(
            encoding="utf-8"
        )
        full_shards = re.search(r"^\s*full\) shards='([^']+)' ;;\s*$", workflow, re.M)
        self.assertIsNotNone(full_shards, "Full CI mode must declare its shard matrix.")
        self.assertEqual(json.loads(full_shards.group(1)), [0, 1, 2])

        for driver in sorted(DRIVERS):
            with self.subTest(driver=driver):
                selection, git, dependencies = self.selection_for({"SOURCE/" + driver})
                self.assertEqual(selection, {"mode": "full", "tests": []})
                self.assertEqual(git.call_count, 2)
                dependencies.assert_not_called()

    def test_driver_with_an_ordinary_test_still_requests_full(self):
        selection, git, dependencies = self.selection_for(
            {
                "SOURCE/test/zyra_clearer_text_contrast_large_375_test.dart",
                "SOURCE/test/guardian_focus_dashboard_test.dart",
            }
        )
        self.assertEqual(selection, {"mode": "full", "tests": []})
        self.assertEqual(git.call_count, 2)
        dependencies.assert_not_called()

    def test_shared_runner_only_change_requests_full(self):
        selection, git, dependencies = self.selection_for(
            {"SOURCE/test/support/zyra_clearer_text_corpus.dart"}
        )
        self.assertEqual(selection, {"mode": "full", "tests": []})
        self.assertEqual(git.call_count, 2)
        dependencies.assert_not_called()

    def test_an_ordinary_top_level_test_retains_selected_mode(self):
        ordinary = "test/guardian_focus_dashboard_test.dart"
        selection, git, dependencies = self.selection_for({"SOURCE/" + ordinary})
        self.assertEqual(selection, {"mode": "selected", "tests": [ordinary]})
        git.assert_any_call("ls-files", "-z", "--", "SOURCE")
        dependencies.assert_called_once()

    def test_capture_dependencies_do_not_select_opt_in_corpus_drivers(self):
        leaf = "test/visual/line121_signup_capture_test.dart"
        runner = "test/support/zyra_clearer_text_corpus.dart"
        tracked = {leaf, runner, "test/unrelated_test.dart"} | DRIVERS
        for affected_drivers in [{driver} for driver in sorted(DRIVERS)] + [DRIVERS]:
            with self.subTest(affected_drivers=sorted(affected_drivers)):
                selection, git, dependencies = self.selection_for(
                    {"SOURCE/" + leaf},
                    tracked_paths=tracked,
                    dependents={leaf: {runner}, runner: affected_drivers},
                )
                self.assertEqual(selection, {"mode": "selected", "tests": [leaf]})
                git.assert_any_call("ls-files", "-z", "--", "SOURCE")
                dependencies.assert_called_once()

    def test_independent_raster_controls_remain_ordinary(self):
        selection, _, _ = self.selection_for(
            {"SOURCE/" + CONTROLS},
            tracked_paths={CONTROLS, "test/unrelated_test.dart"} | DRIVERS,
        )
        self.assertEqual(selection, {"mode": "selected", "tests": [CONTROLS]})

    def test_shared_app_dependency_keeps_ordinary_controls_and_excludes_corpora(self):
        source = "lib/widgets/example.dart"
        runner = "test/support/zyra_clearer_text_corpus.dart"
        selection, _, _ = self.selection_for(
            {"SOURCE/" + source},
            tracked_paths={source, runner, CONTROLS, "test/unrelated_test.dart"} | DRIVERS,
            dependents={source: {runner, CONTROLS}, runner: DRIVERS},
        )
        self.assertEqual(selection, {"mode": "selected", "tests": [CONTROLS]})


class OrdinaryShardTest(unittest.TestCase):
    ordinary = {
        CONTROLS,
        "test/guardian_focus_dashboard_test.dart",
        "test/unrelated_test.dart",
        "test/visual/line121_signup_capture_test.dart",
    }

    def shard_selection(self, mode, selected, index=0, count=1):
        files = self.ordinary | DRIVERS
        folders = sorted({str(Path(path).parent) for path in files})
        walk = [
            (folder, [], sorted(Path(path).name for path in files if str(Path(path).parent) == folder))
            for folder in folders
        ]
        output, errors = StringIO(), StringIO()
        with (
            patch.object(shard.os, "walk", return_value=walk),
            patch.object(shard.Path, "is_file", return_value=True),
            patch("sys.argv", ["zyra_test_shard.py", mode, json.dumps(selected), str(index), str(count)]),
            redirect_stdout(output),
            redirect_stderr(errors),
        ):
            shard.main()
        return output.getvalue().splitlines()

    def test_scope_and_sharder_exclude_only_the_exact_four_drivers(self):
        self.assertEqual(scope.RENDERED_TEXT_CORPUS_TESTS, DRIVERS)
        self.assertEqual(shard.RENDERED_TEXT_CORPUS_TESTS, DRIVERS)
        self.assertNotIn(CONTROLS, DRIVERS)

    def test_full_three_shards_cover_every_ordinary_test_once(self):
        parts = [self.shard_selection("full", [], index, 3) for index in range(3)]
        combined = [path for part in parts for path in part]
        self.assertEqual(set(combined), self.ordinary)
        self.assertEqual(len(combined), len(self.ordinary))
        self.assertFalse(set(combined) & DRIVERS)
        for index, part in enumerate(parts):
            self.assertEqual(part, sorted(self.ordinary)[index::3])

    def test_selected_ordinary_controls_and_capture_fixture_remain_selected(self):
        selected = [CONTROLS, "test/visual/line121_signup_capture_test.dart"]
        self.assertEqual(self.shard_selection("selected", selected), sorted(selected))

    def test_selected_driver_requests_fail_closed_instead_of_becoming_audits(self):
        for driver in sorted(DRIVERS):
            for selected in ([driver], [CONTROLS, driver]):
                with self.subTest(selected=selected), self.assertRaises(SystemExit) as error:
                    self.shard_selection("selected", selected)
                self.assertEqual(error.exception.code, 2)

    def test_unknown_selected_test_still_fails_closed(self):
        with self.assertRaises(SystemExit) as error:
            self.shard_selection("selected", ["test/not_present_test.dart"])
        self.assertEqual(error.exception.code, 2)


if __name__ == "__main__":
    unittest.main()
