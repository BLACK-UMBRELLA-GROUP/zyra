#!/usr/bin/env python3
"""Select ZYRA Flutter tests for a push or pull request. Run from SOURCE."""

import argparse
from collections import defaultdict, deque
import json
from pathlib import Path, PurePosixPath
import posixpath
import re
import subprocess
import sys


# Account for both branches of any Dart conditional import or export.
DIRECTIVE = re.compile(r"^\s*(?:import|export|part)\s+(r?['\"][^;]+);", re.M)
QUOTED_URI = re.compile(r"(['\"])([^'\"]+)\1")
SOURCE_READER = re.compile(
    r"\b(?:File|Directory|FileSystemEntity)\b|\brootBundle\.load\b"
)
SHARED_LIB = (
    "lib/config/",
    "lib/theme/",
    "lib/state/",
    "lib/l10n/",
)
DOCS_ONLY = {
    "README.md",
    "AGENTS.md",
    "SOURCE/README.md",
    "SOURCE/test/FAILURE_DECISIONS_2026-11.md",
}
CI_FILES = {
    ".github/workflows/zyra-ci.yml",
    ".github/scripts/zyra_test_scope.py",
}
CI_SMOKE_TESTS = (
    "test/compiled_app_boundary_test.dart",
    "test/visual/zyra_visual_regression_test.dart",
)
RENDERED_TEXT_CORPUS_TESTS = {
    "test/zyra_clearer_text_contrast_test.dart",
    "test/zyra_clearer_text_contrast_430_test.dart",
    "test/zyra_clearer_text_contrast_large_430_test.dart",
    "test/zyra_clearer_text_contrast_large_375_test.dart",
}
OFFLINE_CONFIG = {
    "lib/config/oauth_config.dart",
    "lib/config/supabase_config.dart",
}


class RunFullSuite(Exception):
    """The comparison or coverage is uncertain, so run every test."""


def git(*arguments):
    return subprocess.check_output(
        ["git", "-C", "..", *arguments], stderr=subprocess.DEVNULL
    )


def changes_since(base):
    if not re.fullmatch(r"[0-9a-f]{40}", base) or base == "0" * 40:
        raise RunFullSuite("The event has no valid comparison commit.")
    try:
        git("merge-base", "--is-ancestor", base, "HEAD")
        fields = git(
            "diff", "--name-status", "--no-renames", "-z", base, "HEAD"
        ).decode().removesuffix("\0").split("\0")
    except subprocess.CalledProcessError as error:
        raise RunFullSuite("The event base is unavailable or is not an ancestor.") from error

    if fields == [""]:
        return set()
    if len(fields) % 2 or any(status not in {"A", "M"} for status in fields[::2]):
        raise RunFullSuite("Files were removed, renamed or changed type.")
    return set(fields[1::2])


def changed_dart(paths):
    changed = set()
    for path in paths:
        if not path.startswith("SOURCE/") or not path.endswith(".dart"):
            raise RunFullSuite("Changes include a non-Dart input that tests may read.")
        source = path.removeprefix("SOURCE/")
        if source.startswith(SHARED_LIB) or (
            source.startswith("lib/") and source.count("/") == 1
        ):
            raise RunFullSuite("Shared app code or app startup changed.")
        if not source.startswith(("lib/", "test/")):
            raise RunFullSuite("Dart code outside the app and test folders changed.")
        if source.startswith(("test/support/", "test/fixtures/")) or source.endswith("_capture_support.dart"):
            raise RunFullSuite("Shared test fixtures or a capture harness changed.")
        if source in RENDERED_TEXT_CORPUS_TESTS:
            # The shard writer excludes the opt-in whole-app raster drivers.
            raise RunFullSuite("An opt-in rendered-text driver changed. Run ordinary regression.")
        changed.add(source)
    return changed


def dart_paths():
    paths = git("ls-files", "-z", "--", "SOURCE").decode().split("\0")
    return {path.removeprefix("SOURCE/") for path in paths if path.endswith(".dart")}


def dependency_path(source, uri):
    if uri.startswith("package:zyra/"):
        dependency = "lib/" + uri.removeprefix("package:zyra/")
    elif ":" in uri:
        return None
    else:
        dependency = posixpath.join(posixpath.dirname(source), uri)
    return posixpath.normpath(dependency)


def dependency_index(paths):
    dependents = defaultdict(set)
    source_readers = set()
    for source in paths:
        if not source.startswith(("lib/", "test/", "tool/", "tools/")):
            continue
        text = Path(source).read_text(encoding="utf-8")
        if source.startswith("test/") and SOURCE_READER.search(text):
            source_readers.add(source)
        for directive in DIRECTIVE.findall(text):
            for _, uri in QUOTED_URI.findall(directive):
                dependency = dependency_path(source, uri)
                if dependency in paths:
                    dependents[dependency].add(source)
                elif dependency is not None and dependency not in OFFLINE_CONFIG:
                    raise RunFullSuite("A repo-local Dart dependency could not be resolved.")
    return dependents, source_readers


def affected_paths(seeds, dependents):
    affected = set(seeds)
    remaining = deque(seeds)
    while remaining:
        for path in dependents.get(remaining.popleft(), ()):
            if path not in affected:
                affected.add(path)
                remaining.append(path)
    return affected


def changed_test_folder(source):
    folder = str(PurePosixPath(source).parent)
    if source.startswith("lib/"):
        return "test/" + folder.removeprefix("lib/")
    return folder


def test_selection(changed):
    paths = dart_paths()
    if not changed <= paths:
        raise RunFullSuite("A changed Dart file is outside the checked-out file set.")
    tests = {
        path for path in paths
        if path.startswith("test/") and path.endswith("_test.dart")
        and path not in RENDERED_TEXT_CORPUS_TESTS
    }
    dependents, source_readers = dependency_index(paths)
    selected = set()
    for source in changed:
        folder = changed_test_folder(source)
        folder_tests = {
            path for path in tests if folder != "test" and path.startswith(folder + "/")
        }
        related = (affected_paths({source}, dependents) & tests) | folder_tests
        if not related:
            raise RunFullSuite("A changed Dart file has no confidently related tests.")
        selected.update(related)
    if any(source.startswith("lib/") for source in changed):
        selected.update(affected_paths(source_readers, dependents) & tests)
    if selected == tests:
        raise RunFullSuite("The affected folders and dependencies span the suite.")
    return sorted(selected)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("base", help="Ancestor commit from the push or PR event")
    arguments = parser.parse_args()
    mode, tests = "full", []
    try:
        paths = changes_since(arguments.base)
        inputs = paths - DOCS_ONLY
        if inputs and inputs <= CI_FILES:
            if any(not Path(test).is_file() for test in CI_SMOKE_TESTS):
                raise RunFullSuite("A required CI smoke test is missing.")
            tests = list(CI_SMOKE_TESTS)
            mode = "selected"
            reason = "CI changed. Check offline access and visual regression."
        elif not inputs:
            mode = "none"
            reason = "No test input changed. Analysis still runs."
        else:
            tests = test_selection(changed_dart(inputs))
            mode = "selected"
            reason = f"Selected {len(tests)} tests by folder, import and source contract."
    except RunFullSuite as error:
        reason = str(error)
    except (OSError, UnicodeError, subprocess.CalledProcessError):
        reason = "Unable to read the checkout safely. Running the full suite."
    print(reason, file=sys.stderr)
    print(json.dumps({"mode": mode, "tests": tests}))


if __name__ == "__main__":
    main()
