# WP1 — Louisiana, SVI 2022 / ACS 2018–2022

```
00_config.R               paths
01_build_estimates.R      VRT files -> [tract x component x 81] numerators and denominators
02_validate_estimates.R   numerators/denominators vs CDC's published E_ values
03_svi_pipeline.R         the CDC aggregation rule as a pure function  <- reusable core
04_validate_pipeline.R    full pipeline vs published EP_/EPL_/SPL_/RPL_, values AND missingness
05_replicate_simulation.R six designs at B = 5,000, plus the model-free 80-replicate check
06_qa_variance.R          SDR estimator vs the published SE column
07_decision_reliability.R leavers, entrants, label changes, P(funded); covariance decomposition
08_subgroup_reliability.R subgroup reliability with clustered SEs and a draw-block bootstrap
09_why_flat.R             the precision-equalisation experiment
10_figure.R               four-panel results figure
11_expected_results.R     machine-checkable manifest, split deterministic vs Monte Carlo
run_all.sh                dependency preflight, full chain, exact-vs-tolerant diff
```

The six simulation designs: `replicate` (all covariance), `within_tract`
(cross-tract removed), `no_cov` (all removed), `replicate_minclamp`
(boundary sensitivity), and the matched EP-level pair `ep_actual` /
`ep_equalised` (the precision-equalisation experiment).

`03_svi_pipeline.R` takes an arbitrary component specification, so swapping
any of them is a one-line change. It is the seed of the `svi-churn` package.

**Porting to another state** is meant to be a change of FIPS code and file
list in `00_config.R` and nothing else. If it is not, that is a finding
about the code, and it should be fixed in `03_svi_pipeline.R` rather than
patched around in the caller.
