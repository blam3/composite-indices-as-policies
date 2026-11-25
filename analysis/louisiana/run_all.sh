#!/usr/bin/env bash
# Reproduce every number in EXPECTED-RESULTS.json from the raw ACS files.
# Usage from repository root: bash analysis/louisiana/run_all.sh
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
REPO_ROOT="$(cd "$SVI_ROOT/../.." && pwd)"
cd "$SVI_ROOT"

echo "== preflight: dependencies =="
missing_bin=()
for b in Rscript unzip python3; do
  command -v "$b" >/dev/null 2>&1 || missing_bin+=("$b")
done
if [ ${#missing_bin[@]} -gt 0 ]; then
  echo "MISSING COMMANDS: ${missing_bin[*]}"
  echo "See the repository README.md. On macOS: brew install r python3"
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
  echo "Preflight failed. Nothing has been run. See the repository README.md."
  exit 2
fi

echo "== staging and checking raw inputs =="
# Already-extracted CSVs are supported; an empty zip glob is not an error.
mkdir -p data/raw/140
shopt -s nullglob
for f in data/raw/*.zip; do unzip -oq "$f" -d data/raw/; done
python3 "$REPO_ROOT/scripts/check_inputs.py" "$SVI_ROOT"

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
python3 "$REPO_ROOT/scripts/compare_results.py" \
  "$SVI_ROOT/results/EXPECTED-RESULTS.json" \
  "$SVI_ROOT/outputs-rerun/EXPECTED-RESULTS.json"
