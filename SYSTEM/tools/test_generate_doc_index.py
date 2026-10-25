"""Isolated metadata/currency checks; never collect or regenerate the live index."""

import tempfile
import unittest
from pathlib import Path

import generate_doc_index as index


PRICING = Path(__file__).parent.parent.parent / "BUSINESS" / "ZYRA PRICING"
# Superseded versions were renamed into ARCHIVE on 2026-10-24 (one-CURRENT rule).
PRICING_ARCHIVE = PRICING / "ARCHIVE"
ARCHIVED = {3: "ZYRA_PRICING_2026-09-18_V3.md", 4: "ZYRA_PRICING_2026-09-21_V4.md", 5: "ZYRA_PRICING_2026-09-24_V5.md"}
CURRENT_NAME = "EXAMPLE_CURRENT_VERSION_V2.md"
OLD_BANNER = "> **SUPERSEDED — NOT CURRENT. DO NOT USE AS A SOURCE OF TRUTH.**"
DATED_BANNER = "> **SUPERSEDED — 2026-09-24.** Replaced by a later contract."
FIELDS = "\n**Version:** V2\n**Status:** CURRENT_VERSION\n**Owner:** Founder\n"


class DocumentationIndexCurrencyTests(unittest.TestCase):
    def metadata(self, text):
        with tempfile.TemporaryDirectory(prefix="zyra-doc-index-fixture-") as directory:
            path = Path(directory) / CURRENT_NAME
            path.write_text(text, encoding="utf-8")
            return index.read_meta(path)

    def currency(self, text, rel=CURRENT_NAME):
        return index.classify_currency(rel, self.metadata(text))

    def test_actual_pricing_v5_explicit_banner_is_not_current(self):
        name = ARCHIVED[5]
        meta = index.read_meta(PRICING_ARCHIVE / name)
        self.assertTrue(meta["SupersededFlag"])
        self.assertIn("CURRENT_VERSION", meta["Status"])
        self.assertEqual(index.classify_currency(name, meta), (False, True))

    def test_actual_controlling_pricing_v6_remains_current(self):
        name = "ZYRA_PRICING_CURRENT_VERSION_V6.md"
        meta = index.read_meta(PRICING / name)
        self.assertFalse(meta["SupersededFlag"])
        self.assertEqual(index.classify_currency(name, meta), (True, False))
        self.assertEqual(meta["Version"], "V6")

    def test_retained_v3_and_v4_banners_remain_non_current(self):
        for version in (3, 4):
            with self.subTest(version=version):
                name = ARCHIVED[version]
                meta = index.read_meta(PRICING_ARCHIVE / name)
                self.assertEqual(index.classify_currency(name, meta), (False, True))

    def test_old_lead_banner_preserves_existing_classification(self):
        meta = self.metadata(OLD_BANNER + "\n\n# Example\n" + FIELDS)
        self.assertTrue(meta["SupersededFlag"])
        self.assertEqual(meta["Owner"], "Founder")
        self.assertEqual(meta["Title"], "Example")

    def test_dated_lead_banner_is_explicit_supersession(self):
        self.assertEqual(self.currency(DATED_BANNER + "\n" + FIELDS), (False, True))

    def test_explicit_banner_directly_after_title_is_recognised(self):
        for banner in (OLD_BANNER, DATED_BANNER):
            with self.subTest(banner=banner):
                self.assertEqual(self.currency("# Example\n\n" + banner + FIELDS), (False, True))

    def test_blank_lines_and_crlf_do_not_hide_explicit_banner(self):
        text = "\r\n \t\r\n  # Example\r\n \t\r\n  " + DATED_BANNER + "\r\n" + FIELDS
        self.assertEqual(self.currency(text), (False, True))

    def test_up_to_three_spaces_keep_valid_lead_banners_recognised(self):
        for spaces in range(4):
            for title_first in (False, True):
                with self.subTest(spaces=spaces, title_first=title_first):
                    title = " " * spaces + "# Example\n\n" if title_first else ""
                    text = title + " " * spaces + DATED_BANNER + FIELDS
                    self.assertEqual(self.currency(text), (False, True))

    def test_space_and_tab_indented_code_banners_are_not_status(self):
        for indentation in ("    ", "     ", "        ", "\t", " \t", "\t "):
            for title_first in (False, True):
                with self.subTest(indentation=indentation, title_first=title_first):
                    title = "# Example\n\n" if title_first else ""
                    self.assertEqual(self.currency(title + indentation + DATED_BANNER + FIELDS), (True, False))

    def test_indented_code_h1_does_not_promote_following_example_to_banner(self):
        for indentation in ("    ", "        ", "\t", " \t"):
            with self.subTest(indentation=indentation):
                text = indentation + "# Example\n\n" + DATED_BANNER + FIELDS
                self.assertEqual(self.currency(text), (True, False))

    def test_code_indentation_inside_blockquote_is_not_status(self):
        bold = DATED_BANNER[2:]
        for indentation in ("     ", "        ", " \t", "\t "):
            for title_first in (False, True):
                with self.subTest(indentation=indentation, title_first=title_first):
                    title = "# Example\n\n" if title_first else ""
                    self.assertEqual(self.currency(title + ">" + indentation + bold + FIELDS), (True, False))

    def test_body_prose_about_supersession_is_not_a_banner(self):
        text = "# Example\n" + FIELDS + "\nThis superseded the prior version.\n"
        self.assertEqual(self.currency(text), (True, False))

    def test_supersedes_field_does_not_supersede_its_own_document(self):
        text = "# Example\n" + FIELDS + "**Supersedes:** EXAMPLE_V1.md\n"
        self.assertEqual(self.currency(text), (True, False))

    def test_historical_quoted_banner_below_heading_is_not_current_status(self):
        text = "# Example\n" + FIELDS + "\n## Historical excerpt\n\n" + OLD_BANNER
        self.assertEqual(self.currency(text), (True, False))

    def test_described_quote_after_title_does_not_change_current_status(self):
        text = "# Example\n\nHistorical example, not this document's status:\n\n" + DATED_BANNER + FIELDS
        self.assertEqual(self.currency(text), (True, False))

    def test_fenced_and_nested_quoted_examples_are_not_banners(self):
        for example in ("```markdown\n" + OLD_BANNER + "\n```", ">" + OLD_BANNER):
            with self.subTest(example=example):
                self.assertEqual(self.currency("# Example\n\n" + example + FIELDS), (True, False))

    def test_counterexamples_and_incomplete_markers_are_not_banners(self):
        for example in (
            "> **NOT SUPERSEDED — NOT CURRENT.**",
            "> This was labelled **SUPERSEDED — NOT CURRENT.** in the old copy.",
            "> **SUPERSEDED — MAYBE.**",
            "> **SUPERSEDED — 2026-09-24.**quoted-without-boundary",
            "> **SUPERSEDED — 2026-09-24.",
        ):
            with self.subTest(example=example):
                self.assertEqual(self.currency("# Example\n\n" + example + FIELDS), (True, False))

    def test_current_filename_without_supersession_stays_current(self):
        self.assertEqual(self.currency("# Example\n" + FIELDS), (True, False))

    def test_archive_and_rollback_paths_keep_existing_precedence(self):
        for directory in ("ARCHIVE", "archives", "TEMPORARY", "pre", "backup", "backups"):
            with self.subTest(directory=directory):
                self.assertEqual(self.currency("# Example\n" + FIELDS, f"SYSTEM/{directory}/{CURRENT_NAME}"), (False, True))

    def test_dated_archive_filename_remains_reference_only(self):
        self.assertEqual(self.currency("# Example\n" + FIELDS, "EXAMPLE_2026-09-24_V1.md"), (False, True))

    def test_named_delivery_preimages_are_history_even_with_current_headers(self):
        for directory in ("DOC_PRE", "doc_pre_delivery", "DELIVERY_DOC_PRE",
                          "LAUNCH_DOC_PRE", "PRE_SOURCE"):
            with self.subTest(directory=directory):
                rel = f"SYSTEM/RESOURCES/REVIEWS/fixture/{directory}/SYSTEM/DOCUMENTS/{CURRENT_NAME}"
                self.assertEqual(self.currency("# Example\n" + FIELDS, rel), (False, True))

    def test_preview_and_post_names_do_not_become_preimages_by_prefix(self):
        for directory in ("DOC_PREVIEW", "PRE_SOURCES", "DOC_POST", "SYSTEM/DOCUMENTS"):
            with self.subTest(directory=directory):
                self.assertEqual(self.currency("# Example\n" + FIELDS, f"{directory}/{CURRENT_NAME}"), (True, False))

    def test_task_named_preimage_directories_are_history(self):
        for directory in ("DELIVERY_HANDOVER_PRE", "COMBINED_DOC_PRE",
                          "GUARDIAN_INVITE_PRE", "supporting_doc_pre"):
            with self.subTest(directory=directory):
                rel = f"SYSTEM/RESOURCES/REVIEWS/fixture/{directory}/SYSTEM/DOCUMENTS/{CURRENT_NAME}"
                self.assertEqual(self.currency("# Example\n" + FIELDS, rel), (False, True))

    def test_pre_in_filename_does_not_reclassify_current_document(self):
        rel = "SYSTEM/DOCUMENTS/PRE_LAUNCH_CURRENT_VERSION_V1.md"
        self.assertEqual(self.currency("# Example\n" + FIELDS, rel), (True, False))

    def test_plain_filename_classification_is_unchanged(self):
        self.assertEqual(self.currency("# Example\n" + FIELDS, "Summary.md"), (False, False))
        self.assertEqual(self.currency(OLD_BANNER + FIELDS, "Summary.md"), (False, True))

    def test_authority_fields_are_not_rewritten(self):
        meta = self.metadata("# Example\n\n" + DATED_BANNER + FIELDS + "**Author:** Fable\n")
        self.assertEqual(meta["Owner"], "Founder")
        self.assertEqual(meta["Author"], "Fable")
        self.assertEqual(meta["Status"], "CURRENT_VERSION")


if __name__ == "__main__":
    unittest.main()
