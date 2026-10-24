import os
import pathlib
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import zyra_check


class ZyraCheckParserTest(unittest.TestCase):
    def test_current_dart_syntax_does_not_create_false_findings(self):
        with tempfile.TemporaryDirectory(dir=".") as raw:
            root = pathlib.Path(raw)
            definitions = root / "definitions.dart"
            caller = root / "caller.dart"
            definitions.write_text(
                """
class PauseIssue {
  PauseIssue();
}

class Preview {
  final List<String> _groups;
  const Preview._({required this._groups});
}

class GenderWords {
  static String subject() => 'they';
}
""",
                encoding="utf-8",
            )
            caller.write_text(
                """
import 'definitions.dart';

final pauseFactory = PauseIssue.new;
final preview = Preview._(groups: const []);
final copy = '${GenderWords.subject()} continue.';
""",
                encoding="utf-8",
            )
            units = [
                zyra_check.Unit(os.path.relpath(definitions)),
                zyra_check.Unit(os.path.relpath(caller)),
            ]
            zyra_check.findings.clear()
            zyra_check.check(units)

            self.assertEqual(zyra_check.findings["MISSING MEMBER"], [])
            self.assertEqual(zyra_check.findings["BAD NAMED ARG"], [])
            self.assertEqual(zyra_check.findings["UNUSED IMPORT"], [])


if __name__ == "__main__":
    unittest.main()
