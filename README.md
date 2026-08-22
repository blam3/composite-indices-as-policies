# Composite Indices Are Policies, Not Measures

A research program on validating, repairing, and transporting allocation
scores — with a return route to LLM safety evaluation.

An index that ranks census tracts and funds the top decile is not a
measurement instrument. It is a policy, `π(x) = 1{w'x ≥ τ}`. Once you say
that plainly, the validation questions become well-posed: does the score
predict the harm it proxies, equally across the groups it sorts; is the
ranking stable given survey error in its inputs; do the weights encode a
defensible normative position; and does a guarantee established where the
index was built survive transport to the jurisdiction that adopts it.

**Full program:** [`docs/program.md`](docs/program.md)
**Current state:** [`docs/STATUS.md`](docs/STATUS.md) — read this first.

## Where things stand

| WP | Question | State |
|---|---|---|
| WP1 | How much of the SVI ranking is survey noise, and is the noise distributed evenly? | Analysis complete for Louisiana, independently audited; paper not drafted |
| WP2 | Does the index predict harm equally across groups and regions? | Not started — gated on outcome-data feasibility |
| WP3 | Does a safety guarantee survive transport? | Not started; one derivation owed before any code |
| WP4 | Do equal, outcome-optimal and participatory weights induce the same allocation? | Not started |
| WP5 | Are aggregate AI safety scores composites mistaken for reflective measures? | Not started, by design written last |

## The WP1 headline

The CDC/ATSDR SVI 2022 pipeline reproduces **exactly** for Louisiana —
57,368 of 57,368 published values across 1,379 tracts, and 57,918 of
57,918 cells agreeing on missing-versus-present. Resampling the ACS inputs
within their published sampling error, using variance replicates so
covariance is preserved, **about a quarter of the published top decile
falls off the funded list**.

The mechanism is not the obvious one. Input precision *is* regressive —
some indicators carry 2.5× the sampling error in the poorest tracts — but
the percentile-ranking step launders that heterogeneity into
near-homogeneous rank noise. A precision-equalisation experiment puts a
number on what that costs at the decision: the published funded set
carries **1.57×** the rank noise it would carry under equal input
precision, and its leaver rate falls from 24.9% to 20.2%.

Full results: [`docs/wp1-louisiana-findings.md`](docs/wp1-louisiana-findings.md).
Independent audit and response: [`docs/wp1-audit-response.md`](docs/wp1-audit-response.md).

## Reproducing WP1

```bash
# 1. Fetch the data (see data/README.md for the exact URLs)
# 2. Run the chain
cd analysis/louisiana/code
./run_all.sh
```

`run_all.sh` runs a dependency preflight, then the full chain, then diffs
the run against `analysis/louisiana/results/EXPECTED-RESULTS.json`.
Deterministic fields are compared exactly (`abs_tol=1e-9`); Monte Carlo
fields at 2%. **The reproduction gate is 100% on both values and
missingness, and it exits nonzero on failure. Do not relax it.**

Runtime: roughly 18 minutes on one core at B = 5,000.

## Layout

```
R/                        the future `svi-churn` package
analysis/louisiana/       WP1: code, results, per-state README
data/                     gitignored; data/README.md says how to fetch
docs/                     program document, STATUS, findings, prompt pack
figures/                  committed output figures
```

## Licence

Code is MIT (`LICENSE`). Prose and figures are CC BY 4.0 (`LICENSE-docs`).

## Citing

See `CITATION.cff`.
