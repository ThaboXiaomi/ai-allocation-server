import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

import unittest

from conflict_utils import parse_time_12h, validate_resolve_conflict_payload


class ConflictUtilsTests(unittest.TestCase):
    def test_parse_time_12h_valid(self):
        self.assertEqual(parse_time_12h("12:00 AM"), 0)
        self.assertEqual(parse_time_12h("12:00 PM"), 12 * 60)
        self.assertEqual(parse_time_12h("1:30 PM"), 13 * 60 + 30)

    def test_parse_time_12h_invalid(self):
        self.assertIsNone(parse_time_12h("13:00 PM"))
        self.assertIsNone(parse_time_12h("10:99 AM"))
        self.assertIsNone(parse_time_12h("10:00"))

    def test_validate_payload_missing(self):
        ok, message = validate_resolve_conflict_payload({"allocationId": "a"})
        self.assertFalse(ok)
        self.assertIn("Missing required fields", message)

    def test_validate_payload_invalid_time_order(self):
        ok, message = validate_resolve_conflict_payload(
            {
                "allocationId": "a",
                "date": "2025-01-01",
                "startTime": "2:00 PM",
                "endTime": "1:00 PM",
            }
        )
        self.assertFalse(ok)
        self.assertEqual(message, "endTime must be later than startTime.")

    def test_validate_payload_valid(self):
        ok, message = validate_resolve_conflict_payload(
            {
                "allocationId": "a",
                "date": "2025-01-01",
                "startTime": "1:00 PM",
                "endTime": "2:00 PM",
            }
        )
        self.assertTrue(ok)
        self.assertIsNone(message)


if __name__ == "__main__":
    unittest.main()
