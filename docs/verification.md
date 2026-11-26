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

## Update — 2026-11-26 (branch `wp1/wyoming-replication`)

- **Full-data Louisiana rerun done.** `bash analysis/louisiana/run_all.sh` ran
  end to end on R 4.5.2 with the inputs staged per `data/README.md`. The gate
  reports 57,368/57,368 values and 57,918/57,918 missingness cells. Deterministic
  fields match exactly, and the Monte Carlo fields are bit-identical to the
  committed manifest. It was rerun again after merging `main`'s runner.
- **The equalisation provenance is extended.** `11_expected_results.R` now emits
  `equalisation_experiment.decile_mean_sd_actual` / `_equalised`,
  `top_decile_noise_ratio_actual_over_equalised` (Louisiana 1.567) and
  `decisions_ep_actual` / `decisions_ep_equalised` (top-decile leaver rate 25.0%
  → 20.2%). No pre-existing manifest field changed; this was checked leaf by leaf.
- **GROUPQ/NOVEH corrected.** The rerun recomputes the manifest's 3.0884 and
  2.9342 from the staged inputs as exact deterministic fields. `STATUS.md` §2
  now carries 3.09 and 2.93, on the researcher's instruction. No script in the
  repository produces the old 2.62/2.51, so their origin is unknown.
- **Second state.** Wyoming runs through the same runner and checks, with only
  `STATE_FIPS`/`STATE_NAME` changed. `scripts/check_inputs.py` now reads both
  from the state's `00_config.R`. See `docs/wp1-wyoming-findings.md`.
