"""Check staged Louisiana inputs and record fingerprints for this run.

Hashes describe the current local files. No historical/source checksum baseline
is supplied, so these fingerprints do not authenticate the files or establish
that they are byte-identical to those used in the original analysis.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path

TABLES = "B01001 B01003 B03002 B11012 B15002 B16005 B18101 B23025 B25003 B25014 B25024 B25044 B25106 B26001 B27001 C17002".split()


def inspect_inputs(root):
    records, errors = [], []
    files = [(f"data/raw/140/{t}_22.csv", {"GEOID", "ORDER", "ESTIMATE", *[f"Var_Rep{i}" for i in range(1, 81)]}) for t in TABLES]
    files.append(("data/raw/Louisiana.csv", {"FIPS", "RPL_THEMES"}))
    for relative, required in files:
        path = root / relative
        if not path.is_file():
            errors.append(f"Missing {relative}")
            continue
        with path.open(encoding="utf-8-sig", newline="") as stream:
            header = next(csv.reader(stream), [])
        missing = required - set(header)
        if missing:
            errors.append(f"{relative}: missing columns {', '.join(sorted(missing))}")
            continue
        digest = hashlib.sha256()
        with path.open("rb") as stream:
            for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                digest.update(chunk)
        records.append({"path": relative, "bytes": path.stat().st_size, "sha256": digest.hexdigest()})
    return records, errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path, help="analysis/louisiana directory")
    args = parser.parse_args()
    records, errors = inspect_inputs(args.root)
    if errors:
        raise SystemExit("Input preflight failed. See data/README.md.\n" + "\n".join(errors))
    out = args.root / "outputs-rerun" / "INPUT-FINGERPRINTS.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps({"scope": "current local inputs; not historical checksum verification", "files": records}, indent=2) + "\n")
    print(f"Inputs staged; current-run fingerprints written to {out}")


if __name__ == "__main__":
    main()
