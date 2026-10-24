import importlib.util
from pathlib import Path
import unittest

path = Path(__file__).resolve().parents[2] / 'SYSTEM/tools/generate_doc_index.py'
spec = importlib.util.spec_from_file_location('zyra_doc_index', path)
index = importlib.util.module_from_spec(spec)
spec.loader.exec_module(index)


class DocumentCurrencyTest(unittest.TestCase):
    def test_explicit_supersession_overrides_preserved_filename(self):
        self.assertEqual(index.classify_currency(
            'SYSTEM/DOCUMENTS/PLAN_CURRENT_VERSION_V4.md',
            {'SupersededFlag': True}), (False, True))

    def test_rollback_copy_is_not_current(self):
        self.assertEqual(index.classify_currency(
            'SYSTEM/RESOURCES/PRICING/pre/PLAN_CURRENT_VERSION_V5.md', {}),
            (False, True))

    def test_live_and_plain_files_remain_distinct(self):
        self.assertEqual(index.classify_currency(
            'SYSTEM/DOCUMENTS/PLAN_CURRENT_VERSION_V5.md', {}), (True, False))
        self.assertEqual(index.classify_currency('APP/Feature/Summary.md', {}),
                         (False, False))


if __name__ == '__main__':
    unittest.main()
