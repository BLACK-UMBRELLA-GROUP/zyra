#!/usr/bin/env python3

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("zyra_marketing_center.py")
SPEC = importlib.util.spec_from_file_location("zyra_marketing_center", MODULE_PATH)
marketing = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(marketing)


class MarketingCentreTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.store = marketing.Store(Path(self.temporary.name))

    def tearDown(self):
        self.temporary.cleanup()

    def item(self, item_id):
        return self.store._find(self.store.read(), item_id)

    def action(self, item_id, action, **values):
        return self.store.action({"id": item_id, "action": action, **values})[0]

    def assign_account(self, item_id, account_id="SOC-001"):
        return self.store.update_content({"id": item_id, "accountId": account_id})[0]

    def test_seed_has_eight_roles_and_no_public_activity(self):
        state = self.store.read()
        self.assertEqual(state["version"], 2)
        self.assertEqual(len(state["agents"]), 8)
        self.assertEqual(len(state["accounts"]), 9)
        self.assertEqual(len(state["campaigns"]), 3)
        self.assertFalse(state["connectionPolicy"]["liveConnectionsEnabled"])
        self.assertEqual({item["status"] for item in state["content"]}, {"DRAFT"})
        self.assertFalse(state["community"])
        self.assertFalse(state["metrics"])

    def test_exact_founder_approval_is_invalidated_by_edit(self):
        self.assign_account("CNT-001")
        self.action("CNT-001", "brand_check")
        self.action("CNT-001", "submit_founder")
        approved = self.action("CNT-001", "founder_approve")
        self.assertEqual(approved["status"], "APPROVED")
        self.assertEqual(approved["approval"]["previewHash"], marketing.preview_hash(approved))

        updated = self.store.update_content({"id": "CNT-001", "caption": "A revised caption."})[0]
        self.assertEqual(updated["status"], "DRAFT")
        self.assertIsNone(updated["approval"])
        self.assertIsNone(updated["brandCheck"])

    def test_sensitive_content_requires_compliance(self):
        self.assign_account("CNT-002")
        checked = self.action("CNT-002", "brand_check")
        self.assertEqual(checked["status"], "BRAND_REVIEWED")
        with self.assertRaises(marketing.StateError):
            self.action("CNT-002", "submit_founder")
        reviewed = self.action("CNT-002", "compliance_review", note="Checked")
        self.assertEqual(reviewed["status"], "COMPLIANCE_REVIEWED")
        submitted = self.action("CNT-002", "submit_founder")
        self.assertEqual(submitted["status"], "FOUNDER_REVIEW")

    def test_publication_cannot_skip_founder_approval(self):
        with self.assertRaises(marketing.StateError):
            self.action("CNT-001", "mark_published", url="https://example.com/post")
        self.assign_account("CNT-001")
        self.action("CNT-001", "brand_check")
        self.action("CNT-001", "submit_founder")
        self.action("CNT-001", "founder_approve")
        published = self.action("CNT-001", "mark_published", url="https://example.com/post")
        self.assertEqual(published["status"], "MANUALLY_PUBLISHED")
        self.assertEqual(published["publication"]["mode"], "MANUAL")

    def test_brand_guardian_blocks_unsupported_claims(self):
        result = marketing.brand_check({
            "title": "The best Muslim dating app",
            "body": "Download now for a guaranteed perfect match.",
            "sources": [],
        })
        self.assertFalse(result["passed"])
        self.assertGreaterEqual(len(result["issues"]), 3)

    def test_sensitive_community_items_are_human_only(self):
        item = self.store.add_community({
            "platform": "Instagram",
            "category": "safety",
            "message": "I need help.",
            "draftReply": "This must not auto-send.",
        })[0]
        self.assertTrue(item["humanOnly"])
        self.assertEqual(item["status"], "HUMAN_ESCALATION")

    def test_inspiration_capture_does_not_analyse_or_execute(self):
        first = self.store.add_inspiration({
            "platform": "TikTok",
            "sourceUrl": "https://example.test/video/1",
            "note": "",
        })[0]
        repeat = self.store.add_inspiration({
            "platform": "TikTok",
            "sourceUrl": "https://example.test/video/1/",
            "note": "",
        })[0]
        self.assertEqual(first["status"], "CAPTURED")
        self.assertIsNone(first["analysis"])
        self.assertEqual(repeat["status"], "DUPLICATE")
        self.assertEqual(repeat["duplicateOf"], first["id"])
        self.assertEqual(len(self.store.read()["content"]), 3)

    def test_state_file_remains_valid_json(self):
        self.action("CNT-003", "brand_check")
        with open(Path(self.temporary.name) / "state.json", encoding="utf-8") as handle:
            self.assertEqual(json.load(handle)["version"], 2)

    def test_account_register_rejects_secret_fields_and_live_connections(self):
        updated = self.store.update_account({
            "id": "SOC-001", "platform": "Facebook", "handle": "@zyra",
            "accountStatus": "ACTIVE", "integrationStatus": "MANUAL_ONLY",
        })[0]
        self.assertEqual(updated["handle"], "@zyra")
        with self.assertRaises(marketing.StateError):
            self.store.update_account({"id": "SOC-001", "password": "do-not-store"})
        with self.assertRaises(marketing.StateError):
            self.store.update_account({"id": "SOC-001", "integrationStatus": "CONNECTED"})

    def test_master_idea_allows_variants_but_daily_limit_blocks_fourth_idea(self):
        campaign = self.store.add_campaign({
            "title": "Helpful guardian explainer", "category": "Helpful",
            "audience": "Both", "pillar": "Education",
            "objective": "Explain guardian controls", "notes": "",
        })[0]
        base = {
            "title": "Variant", "pillar": "Education", "platform": "TikTok",
            "format": "Short video", "objective": "Explain", "hook": "Hook",
            "body": "Private testing explainer", "caption": "Private testing",
            "cta": "Learn more", "destination": "https://zyraconnect.app",
            "risk": "routine", "sources": ["governed-source"], "budgetGbp": 0,
            "accountId": "SOC-001", "scheduledAt": "2026-10-05T10:00",
            "scheduleTimezone": "Europe/London",
        }
        for campaign_id in ["CMP-001", "CMP-002", campaign["id"]]:
            self.store.add_content({**base, "campaignId": campaign_id})
        self.store.add_content({**base, "campaignId": "CMP-001", "platform": "Instagram"})
        fourth = self.store.add_campaign({
            "title": "Fourth", "category": "Trust", "audience": "Both",
            "pillar": "Education", "objective": "Fourth idea", "notes": "",
        })[0]
        with self.assertRaises(marketing.StateError):
            self.store.add_content({**base, "campaignId": fourth["id"]})

    def test_approval_hash_includes_account_media_and_schedule(self):
        self.assign_account("CNT-001")
        item = self.store.update_content({
            "id": "CNT-001", "scheduledAt": "2026-10-05T12:00",
            "scheduleTimezone": "Europe/London", "assetRef": "launch.mp4",
            "assetSha256": "a" * 64,
        })[0]
        before = marketing.preview_hash(item)
        changed = dict(item, scheduledAt="2026-10-05T13:00")
        self.assertNotEqual(before, marketing.preview_hash(changed))


if __name__ == "__main__":
    unittest.main()
