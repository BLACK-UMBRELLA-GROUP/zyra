#!/usr/bin/env python3
"""Write the test files assigned to one runner, from the SOURCE directory."""

import argparse
import json
import os
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("full", "selected"))
    parser.add_argument("tests", help="JSON array of affected test paths")
    parser.add_argument("index", type=int)
    parser.add_argument("count", type=int)
    args = parser.parse_args()
    if not 0 <= args.index < args.count:
        parser.error("Shard index must be between zero and the shard count minus one.")

    # Flutter discovers these files recursively, without following symlinked
    # directories. Partition files so runners do not recompile every suite.
    available = {
        (Path(directory) / name).as_posix()
        for directory, _, files in os.walk("test")
        for name in files
        if name.endswith("_test.dart") and (Path(directory) / name).is_file()
    }
    if args.mode == "full":
        paths = sorted(available)
    else:
        try:
            selected = json.loads(args.tests)
        except json.JSONDecodeError as error:
            parser.error(f"Invalid test list: {error}")
        if not isinstance(selected, list) or not all(
            isinstance(path, str) and path in available for path in selected
        ):
            parser.error("The selected test list must contain existing Flutter test files.")
        paths = sorted(set(selected))

    shard = paths[args.index :: args.count]
    if not shard or any("\n" in path or "\r" in path for path in shard):
        parser.error("The shard must contain tests with single-line paths.")
    print("\n".join(shard))


if __name__ == "__main__":
    main()
