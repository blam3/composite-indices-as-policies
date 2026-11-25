# Verification status — 2026-11-25

## Scope of the presentation cleanup

README, data staging instructions, runner paths, manifest comparison, and CI
were reviewed against the checked-in artifacts. Scientific input mappings,
simulation algorithms, and `results/EXPECTED-RESULTS.json` were not changed.
Python is used only for input-file hashing and JSON comparison/testing; the
scientific analysis remains in R.

The runner previously looked for a nonexistent historical checksum file and a
reference manifest at the wrong path. It now reads `results/EXPECTED-RESULTS.json`
and records current-input fingerprints explicitly as current-run provenance.
The full-data reproduction requirement was not weakened.

## Checks and limits

- Python comparison-tool tests cover deterministic mismatches, Monte Carlo
  tolerances, missingness/boolean mismatches, missing/extra fields, wrong types,
  nonfinite values, and absent input files.
- Shell syntax and reference-manifest consistency can be checked without data.
- CI includes R parsing and small boundary checks of rounding, ties, missingness,
  and ranking. These checks do not reproduce Louisiana or verify source mappings.
- The cleanup environment did not provide R or the raw ACS/CDC inputs. No full
  analysis rerun, new data download, or independent scientific validation is
  claimed. Historical execution claims remain historical.

## Open provenance discrepancies

The historical `STATUS.md` text quotes GROUPQ and NOVEH input-precision ratios
of 2.62 and 2.51, while the committed manifest contains 3.0884 and 2.9342 at
`deterministic.se_ratio_povQ5_over_povQ1`. The discrepancy is unresolved: neither
set has been silently promoted as the definitive result. Recompute with the
original inputs and inspect the estimand/sample/aggregation definitions before
changing numbers. The landing-page case study excludes these ratios.

The historical narrative also quotes top-decile equalisation findings (20.2%
leavers and 1.57× noise) that are not directly represented by named fields in
the committed manifest. Do not feature these as manifest-verified results until
the provenance is extended and checked. A green syntax check does not resolve
these questions.

## Next verification step

Stage the source inputs using `data/README.md`, install R dependencies, then run
`bash analysis/louisiana/run_all.sh`. Retain fingerprints, package versions,
console output, and fresh outputs. Investigate failures; do not alter the
reference or tolerance just to obtain a pass.
