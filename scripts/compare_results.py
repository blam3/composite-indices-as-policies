"""Compare a fresh manifest with the committed reference without weakening gates."""
import argparse
import json
import math
from pathlib import Path


def compare(expected, actual):
    errors = []

    def walk(x, y, path=""):
        if path.endswith("/R_version") or path.endswith("/note"):
            return  # Explanatory strings and platform metadata are not results.
        if isinstance(x, dict):
            if not isinstance(y, dict):
                errors.append(f"{path}: expected an object")
                return
            for key in x.keys() - y.keys():
                errors.append(f"{path}/{key}: missing")
            for key in y.keys() - x.keys():
                errors.append(f"{path}/{key}: unexpected")
            for key in x.keys() & y.keys():
                walk(x[key], y[key], f"{path}/{key}")
        elif isinstance(x, list):
            if not isinstance(y, list) or len(x) != len(y):
                errors.append(f"{path}: list type/length differs")
                return
            for i, (a, b) in enumerate(zip(x, y)):
                walk(a, b, f"{path}/{i}")
        elif isinstance(x, bool) or isinstance(y, bool):
            if type(x) is not type(y) or x != y:
                errors.append(f"{path}: boolean differs")
        elif isinstance(x, (int, float)) and isinstance(y, (int, float)):
            exact = path.startswith("/deterministic/") or path.startswith("/monte_carlo/meta/")
            if not (math.isfinite(x) and math.isfinite(y)) or not math.isclose(
                x, y, rel_tol=0 if exact else 0.02, abs_tol=1e-9 if exact else 1e-6
            ):
                errors.append(f"{path}: expected {x}, got {y} ({'exact' if exact else '2% relative'} gate)")
        elif type(x) is not type(y) or x != y:
            errors.append(f"{path}: value/type differs")

    walk(expected, actual)
    return sorted(errors)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("expected", type=Path)
    parser.add_argument("actual", type=Path)
    args = parser.parse_args()
    errors = compare(json.loads(args.expected.read_text()), json.loads(args.actual.read_text()))
    if errors:
        raise SystemExit("Result comparison failed:\n" + "\n".join(errors))
    print("DETERMINISTIC FIELDS: exact match (absolute tolerance 1e-9).")
    print("MONTE CARLO FIELDS: agree within 2% relative tolerance; seed/draw count exact.")


if __name__ == "__main__":
    main()
