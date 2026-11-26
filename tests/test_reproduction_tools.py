import copy
import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


def module(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / "scripts" / f"{name}.py")
    obj = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(obj)
    return obj


class ReproductionGates(unittest.TestCase):
    def setUp(self):
        self.compare = module("compare_results").compare
        self.reference = {"deterministic": {"reproduction": {"values_exact": 57368, "missing_ok": True}}, "monte_carlo": {"meta": {"B_draws": 5000, "seed": 20260818}, "rate": 0.25}}

    def test_reference_matches_itself(self):
        self.assertEqual(self.compare(self.reference, self.reference), [])

    def test_small_deterministic_error_fails(self):
        actual = copy.deepcopy(self.reference)
        actual["deterministic"]["reproduction"]["values_exact"] -= 1
        self.assertTrue(self.compare(self.reference, actual))

    def test_missingness_failure_and_boolean_coercion_fail(self):
        for value in (False, 1):
            actual = copy.deepcopy(self.reference)
            actual["deterministic"]["reproduction"]["missing_ok"] = value
            self.assertTrue(self.compare(self.reference, actual))

    def test_monte_carlo_tolerance_and_exact_metadata(self):
        actual = copy.deepcopy(self.reference)
        actual["monte_carlo"]["rate"] = 0.251
        self.assertEqual(self.compare(self.reference, actual), [])
        actual["monte_carlo"]["meta"]["seed"] += 1
        self.assertTrue(self.compare(self.reference, actual))
        actual = copy.deepcopy(self.reference)
        actual["monte_carlo"]["rate"] = 0.26
        self.assertTrue(self.compare(self.reference, actual))

    def test_missing_extra_nonfinite_and_type_changed_results_fail(self):
        for value in ({}, {"extra": 1}, float("nan"), "0.25"):
            actual = copy.deepcopy(self.reference)
            actual["monte_carlo"]["rate"] = value
            self.assertTrue(self.compare(self.reference, actual))

    def test_missing_inputs_fail_before_analysis(self):
        inputs = module("check_inputs")
        with tempfile.TemporaryDirectory() as directory:
            records, errors = inputs.inspect_inputs(Path(directory))
        self.assertFalse(records)
        self.assertEqual(len(errors), len(inputs.TABLES) + 1)


if __name__ == "__main__":
    unittest.main()
