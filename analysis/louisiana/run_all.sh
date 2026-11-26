#!/usr/bin/env bash
# Reproduce every number in EXPECTED-RESULTS.json from the raw ACS files.
# Usage:  cd svi-wp1-audit && ./run_all.sh
#
# REVISED 2026-08-19 in response to the independent audit (items 2 and 7).
#   item 7: the run previously died at code/10_figure.R because gridExtra was
#           absent, silently skipping the manifest and the final diff. There is
#           now a preflight that checks every declared dependency BEFORE any
#           work begins and prints the exact install command.
#   item 2: the diff previously applied a 2% tolerance to every field, so a
#           deterministic value could be wrong by 1.9% and still print
#           "ALL NUMBERS MATCH". Deterministic fields are now compared exactly;
#           tolerance applies only to Monte Carlo fields.
set -euo pipefail
export SVI_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SVI_ROOT"

echo "== preflight: dependencies =="
missing_bin=()
for b in Rscript unzip python3; do
  command -v "$b" >/dev/null 2>&1 || missing_bin+=("$b")
done
if [ ${#missing_bin[@]} -gt 0 ]; then
  echo "MISSING COMMANDS: ${missing_bin[*]}"
  echo "See ENVIRONMENT.md. On macOS: brew install r python3"
  exit 2
fi
if ! Rscript -e '
pk <- c("data.table","ggplot2","dplyr","gridExtra","jsonlite","splines")
miss <- pk[!vapply(pk, requireNamespace, logical(1), quietly = TRUE)]
if (length(miss)) {
  cat("MISSING R PACKAGES:", paste(miss, collapse = ", "), "\n")
  cat("Install them with:\n  Rscript -e '"'"'install.packages(c(",
      paste(sprintf("\"%s\"", miss), collapse = ","),
      "), repos=\"https://cloud.r-project.org\")'"'"'\n", sep = "")
  quit(status = 1L)
}
cat("all R packages present:", paste(pk, collapse = ", "), "\n")
cat(R.version.string, "\n")'; then
  echo "Preflight failed. Nothing has been run. See ENVIRONMENT.md."
  exit 2
fi

echo "== unpacking raw VRT files =="
mkdir -p data/raw/140
shopt -s nullglob                     # a state staged as bare CSVs has no zips
for f in data/raw/*.zip; do unzip -oq "$f" -d data/raw/; done
shopt -u nullglob
ls data/raw/140/*.csv | wc -l

echo "== verifying input checksums =="
# Kept at the state root, not under data/, because data/ is never committed.
[ -f INPUT-CHECKSUMS.sha256 ] || { echo "MISSING INPUT-CHECKSUMS.sha256"; exit 2; }
shasum -a 256 -c INPUT-CHECKSUMS.sha256 2>/dev/null || sha256sum -c INPUT-CHECKSUMS.sha256

echo "== 01 build estimates =="        ; Rscript code/01_build_estimates.R
echo "== 02 validate counts =="        ; Rscript code/02_validate_estimates.R
echo "== 04 validate full pipeline ==" ; Rscript code/04_validate_pipeline.R
echo "== 06 QA variance estimator =="  ; Rscript code/06_qa_variance.R
echo "== 05 simulation (B=${SVI_B:-5000}) ==" ; SVI_B="${SVI_B:-5000}" Rscript code/05_replicate_simulation.R
echo "== 07 decision reliability =="   ; Rscript code/07_decision_reliability.R
echo "== 08 subgroup reliability =="   ; Rscript code/08_subgroup_reliability.R
echo "== 09 why flat =="               ; Rscript code/09_why_flat.R
echo "== 10 figure =="                 ; Rscript code/10_figure.R
echo "== 11 expected-results manifest ="; Rscript code/11_expected_results.R

echo
echo "== DIFF: your run vs the claimed results =="
python3 - <<'PY'
import json, math, sys
a = json.load(open('results/EXPECTED-RESULTS.json'))        # claimed
b = json.load(open('outputs-rerun/EXPECTED-RESULTS.json'))  # yours

# AUDIT item 2: the top level of the manifest separates fields that MUST match
# exactly (reproduction counts, tract counts, SE ratios computed from published
# replicates -- no RNG touches any of them) from fields that are Monte Carlo
# estimates and will not be bit-identical across platforms.
EXACT_ROOTS   = ("/deterministic",)
TOLERANT_ROOT = "/monte_carlo"
TOL = 2e-2
exact_bad, tol_bad, missing = [], [], []

def is_exact(path):
    return any(path.startswith(r) for r in EXACT_ROOTS)

def walk(x, y, path=""):
    if isinstance(x, dict):
        for k in x:
            if k not in y:
                missing.append(path + "/" + k); continue
            walk(x[k], y[k], path + "/" + k)
    elif isinstance(x, list):
        if not isinstance(y, list) or len(x) != len(y):
            (exact_bad if is_exact(path) else tol_bad).append((path, x, y)); return
        for i, (xi, yi) in enumerate(zip(x, y)):
            walk(xi, yi, f"{path}[{i}]")
    elif isinstance(x, bool) or isinstance(y, bool):
        if x != y: (exact_bad if is_exact(path) else tol_bad).append((path, x, y))
    elif isinstance(x, (int, float)) and isinstance(y, (int, float)):
        if is_exact(path):
            if not math.isclose(x, y, rel_tol=0.0, abs_tol=1e-9):
                exact_bad.append((path, x, y))
        elif not math.isclose(x, y, rel_tol=TOL, abs_tol=1e-6):
            tol_bad.append((path, x, y))
    elif x != y and "note" not in path and "R_version" not in path:
        (exact_bad if is_exact(path) else tol_bad).append((path, x, y))

walk(a, b)

def dump(label, rows):
    print(f"\n{label}: {len(rows)}")
    for p, claimed, got in rows:
        print(f"  {p}\n    claimed: {claimed}\n    yours:   {got}")

ok = True
if missing:
    print(f"\nFIELDS PRESENT IN THE CLAIM BUT ABSENT FROM YOUR RUN: {len(missing)}")
    for p in missing: print("  " + p)
    ok = False
if exact_bad:
    dump("DETERMINISTIC MISMATCHES (these must be exact)", exact_bad); ok = False
if tol_bad:
    dump(f"MONTE CARLO MISMATCHES (outside {TOL:.0%} relative tolerance)", tol_bad); ok = False

if ok:
    print("DETERMINISTIC FIELDS: exact match.")
    print(f"MONTE CARLO FIELDS:   agree within {TOL:.0%} relative tolerance.")
else:
    sys.exit(1)
PY
