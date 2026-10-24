"""Keep deterministic pricing lint aligned with current Founder authority."""
import unittest

from zyra_ui_gate import RETIRED_TERMS


class CurrentPricingGateTest(unittest.TestCase):
    def test_role_specific_current_prices_are_not_retired(self):
        retired = {term for term, _ in RETIRED_TERMS}
        for current in ("£4.99", "£19.99", "£29.99"):
            self.assertNotIn(current, retired)

    def test_superseded_combined_and_yearly_offers_are_retired(self):
        retired = {term for term, _ in RETIRED_TERMS}
        for old in ("£34.99", "£39.99", "£49.99", "£349.90", "£399.90"):
            self.assertIn(old, retired)


if __name__ == "__main__":
    unittest.main()
