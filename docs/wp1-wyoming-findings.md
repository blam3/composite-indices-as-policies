# WP1, second state: reproducing CDC/ATSDR SVI 2022 for Wyoming and recomputing the decision-reliability numbers

Branch `wp1/wyoming-replication`. Every number below comes from
`analysis/wyoming/results/EXPECTED-RESULTS.json`, written by the unchanged
Louisiana chain run with `STATE_FIPS = "56"`. Louisiana comparators come from
`analysis/louisiana/results/EXPECTED-RESULTS.json`. Both are ACS 2018–2022
5-year VRT, summary level 140, B = 5,000, seed 20260818, R 4.5.2. Every
coefficient is a **descriptive association** with county-clustered CR1
standard errors. No p-values are reported.

The prediction was committed before the chain ran, in
`docs/wp1-wyoming-prediction.md` (commit `8710c18`). The scorecard at the end
compares the two line by line.

## What was done

- **State-agnosticism.** `03_svi_pipeline.R` needed no change; it already
  takes any component specification. What was not state-agnostic was the
  callers: `01` and `06` hardcoded `"%s_22.csv"`, `00_config.R` hardcoded
  `Louisiana.csv`, `11` hardcoded the state label, and `08` indexed
  `[1:200]` tracts. `STATE_FIPS` and `STATE_NAME` now live in `00_config.R`,
  and those are the only two lines that differ between the two states.
  `analysis/wyoming/code/` holds a real `00_config.R` and symlinks to every
  other Louisiana script.
- **`run_all.sh` did not run in this checkout, for either state.** It
  unzipped a glob that matched nothing, checked a checksum file that did not
  exist, and diffed against a manifest path that had moved. `main` repaired the
  same defects independently on 2026-11-25, and that version is the one merged
  here. It records current-file fingerprints through `scripts/check_inputs.py`,
  which no longer hardcodes Louisiana, and compares against
  `results/EXPECTED-RESULTS.json` through `scripts/compare_results.py`.
- **Manifest extended, for both states.** Three figures quoted in STATUS §2
  were in the logs but not in `EXPECTED-RESULTS.json`: the decile rank-noise
  profiles, the top-decile noise ratio (Louisiana 1.57×) and the equalised
  leaver rate (Louisiana 20.2%). `11` now emits them. No existing field
  changed in either manifest; this was checked leaf by leaf.

## Reproduction

| | Wyoming | Louisiana |
|---|---|---|
| CDC tracts / VRT tracts / dropped | 160 / 160 / 0 | 1,379 / 1,388 / 9 (water) |
| Count checks (`02`) | 19/19 exact | 19/19 exact |
| **Values** | **6,678 / 6,678** | 57,368 / 57,368 |
| **Missingness cells** | **6,720 / 6,720** | 57,918 / 57,918 |

**No new convention was needed.** The three Louisiana conventions (SAS
rounding, the `(min-rank − 1)/(n_valid − 1)` tie-low percentile, and
re-quantisation between summation and ranking) reproduce Wyoming without
modification. **One limit on what this shows:** Wyoming's only missingness is
one zero-population tract that is missing in every field. Louisiana had
per-variable partial missingness. So Wyoming confirms the zero-denominator
exclusion rule only trivially. A clean second state is also not a check on
the line-number mappings; see `docs/wp1-line-number-verification.md` for
that.

After the shared-code edits, Louisiana reran end to end through `run_all.sh`
and still reproduces: deterministic fields exact, and Monte Carlo fields
bit-identical to the 2026-08-19 manifest despite the change from R 4.3.3 to
R 4.5.2.

## Rank stability, all six designs

| Design | Median SD | Median 90% width | >20 pts | >40 pts |
|---|---|---|---|---|
| `replicate` | **0.1113** [0.0898] | **36.1** [29.3] | 86.2% [80.8%] | **35.2%** [14.9%] |
| `within_tract` | 0.1108 [0.0897] | 36.1 | 86.2% | 35.2% [15.4%] |
| `no_cov` | 0.0996 [0.0873] | 32.3 | 81.1% | 25.8% [5.0%] |
| `replicate_minclamp` | 0.1140 [0.0910] | 36.7 | 87.4% | 38.4% |
| `ep_actual` | 0.1123 [0.0894] | 36.7 | 85.5% | 36.5% |
| `ep_equalised` | 0.1000 [0.0808] | 32.3 | 79.9% | 22.6% |

Louisiana in brackets.

**Cross-tract covariance again changes nothing.** The `replicate` to
`within_tract` SD ratio is 1.004, and the >40-point share is identical.

**Within-tract covariance matters more than in Louisiana.** The
`within_tract` to `no_cov` ratio is **1.112** against Louisiana's 1.027. As a
result, independent-MOE simulation is optimistic **at the median** in
Wyoming (0.0996 against 0.1113), not only in the tail. That strengthens the
existing STATUS claim.

**Assumption-free check.** Running the pipeline on the 80 published
replicates with no Gaussian step gives a median SD of 0.1175, against
0.1113 from the Gaussian draws. The ratio is **0.947** [1.006] and the
cross-tract correlation is 0.917 [0.931]. In Wyoming the Gaussian model
*understates* the replicate spread by about 5%. The headline Wyoming
reliability numbers are therefore, if anything, mildly optimistic.

**Boundary clamps.** 3.06% of simulated numerator cells were floored at zero
[2.81%]. No denominators were floored, no tract lost a valid percentile in
any draw, and every tract retained all 5,000 draws. Clamping is less
frequent in high-poverty tracts (Q5/Q1 0.80 [0.76]). Relaxing the clamps
raises the median SD (0.1140) and the decile leaver rate (27.1%), so the
clamps are mildly conservative, as in Louisiana.

## At the decision

Replicate design. Leavers, entrants and label changes are reported
separately, from `churn_metrics()`.

| Funded set | Funded | **Expected leavers** | Entrants | Label changes | P(funded) < 0.90 | Unfunded P(funded) > 0.10 | 90% interval crosses cutoff |
|---|---|---|---|---|---|---|---|
| Top decile | 16 | **4.26 (26.6%)** [24.9%] | 4.25 | 8.51 | 12 | 13 | 13 |
| Top quintile | 32 | **6.45 (20.1%)** [18.8%] | 6.42 | 12.87 | 20 | 24 | 24 |
| Top quartile | 40 | **8.10 (20.3%)** [15.9%] | 8.08 | 16.18 | 22 | 26 | 28 |

About a quarter of Wyoming's published top decile would fall off the list
if the survey were rerun, roughly the same as Louisiana's. Most of the
funded tracts have a weak claim to their status: 13 of 16 have a 90%
interval crossing the cutoff, and 12 of 16 have P(funded) < 0.90. The
Monte Carlo SE of the decile leaver count, blocked over draws, is 0.022.

**The leaver rate does not fall from quintile to quartile** (20.1% then
20.3%), whereas Louisiana's falls from 18.8% to 15.9%. With 32 and 40 funded
tracts this rests on a handful of tracts near the 0.75 and 0.80 cutoffs. It
is recorded as observed, not explained.

Top-decile leaver rate under the other designs: `within_tract` 26.6%,
`no_cov` 24.0%, `replicate_minclamp` 27.1%, `ep_actual` 27.1%,
`ep_equalised` 22.5%.

## Subgroup-conditional reliability

**Input precision is regressive, less cleanly than in Louisiana.** EP-level
SE, highest- against lowest-poverty quintile (32 tracts each):

| | POV150 | UNEMP | HBURD | NOHSDP | UNINSUR | AGE65 | AGE17 | DISABL | SNGPNT | LIMENG | MINRTY | MUNIT | MOBILE | CROWD | NOVEH | GROUPQ |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Wyoming | 2.59 | 1.57 | 1.26 | 1.77 | 1.36 | 0.82 | 1.04 | 1.14 | 1.63 | 1.08 | **1.21** | 2.54 | 1.29 | **0.74** | 2.09 | 2.78 |
| Louisiana | 2.22 | 2.39 | 1.52 | 2.19 | 1.52 | 1.02 | 1.39 | 1.36 | 1.92 | 1.40 | 0.85 | 1.63 | 1.03 | 2.38 | 2.93 | 3.09 |

Fourteen of sixteen ratios exceed 1. Two differences stand out:

- **MINRTY is regressive in Wyoming** (1.21) where it was flat in Louisiana
  (0.85). Wyoming's high-poverty tracts include the Wind River reservation
  tracts in Fremont County, where the minority share is mid-range and the SE
  of a percentage is largest. That was the predicted mechanism. It is
  consistent with the result but not tested by it.
- **CROWD inverts** (0.74).

Albany County student tracts raise POV150 and GROUPQ together, so Wyoming's
poverty quintiles mix two different populations.

**Rank noise is again not regressive.** The five covariates explain
R² = 0.042 of rank SD [0.025]. The poverty coefficient is −0.00001 (clustered
SE 0.0031), against a median SD of 0.111.

**Flip model.** Top-decile flip, with a spline in the distance to the
cutoff. The poverty odds ratio is 0.93 per SD [0.88], with a clustered SE on
the log odds of **0.209** [0.049]. That is about four times wider, with 23
counties, some holding a single tract. The sign is not informative at this
n. The minority odds ratio is 0.84 (SE 0.068). The draw-block SEs are an
order of magnitude smaller than the clustered ones, as in Louisiana, so
these are not simulation artefacts.

`08`'s "tracts closest to the cutoff" block covers all 159 tracts in
Wyoming and is uninformative.

## The precision-equalisation experiment

Mean rank SD by decile of the published percentile (about 16 tracts per
decile in Wyoming):

| Decile | WY actual | WY equalised | LA actual | LA equalised |
|---|---|---|---|---|
| 1 | 0.0501 | 0.0517 | 0.0363 | 0.0389 |
| 2 | 0.0904 | 0.0819 | 0.0735 | 0.0742 |
| 3 | 0.0964 | 0.0953 | 0.0913 | 0.0877 |
| 4 | 0.1309 | 0.1195 | 0.1052 | 0.0986 |
| 5 | 0.1353 | 0.1220 | 0.1091 | 0.0998 |
| 6 | 0.1380 | 0.1238 | 0.1128 | 0.0996 |
| 7 | 0.1376 | 0.1229 | 0.1125 | 0.0934 |
| 8 | 0.1327 | 0.1156 | 0.1002 | 0.0791 |
| 9 | 0.1142 | 0.0787 | 0.0881 | 0.0650 |
| 10 | 0.0592 | 0.0389 | 0.0530 | 0.0339 |

- **The shape survives equalisation.** The decile profiles correlate at
  **0.950** [0.935], and the peak stays in decile 6.
- **Rank position explains more.** R² of `ns(rpl0, 6)` on rank SD is 0.662
  under actual precision and 0.787 equalised [0.613 and 0.713].
- **The level shift concentrates in the funded set again.** Wyoming's
  published top decile carries **1.52×** the rank noise it would carry under
  equal input precision [1.57×]. The matched leaver rate falls from 27.1%
  (`ep_actual`) to **22.5%** (`ep_equalised`) [25.0% to 20.2%], so about a
  sixth of top-decile churn is attributable to unequal input precision
  [about a fifth].
- **Partial correlation.** Between input imprecision and rank SD, holding
  rank position fixed: **0.542** [0.485]. As in Louisiana, this is close to
  conditioning on a mediator. It is an association, and the experiment above
  is what licenses the causal reading.

## Wyoming against Louisiana

**The WP1 claim transports.** Four results come out the same in a state with
a ninth of the tracts, a different racial composition and a different rural
structure:

- the CDC rule reproduces exactly with no new convention;
- a quarter of the top decile churns;
- input precision is regressive while rank noise is not;
- equalising precision cuts top-decile rank noise by about a third and
  leaves the inverted U intact.

What changes is the level. Rank noise is about 24% higher at the median, and
the share of tracts with a 90% interval wider than 40 points more than
doubles (35.2% against 14.9%). That second figure was the largest surprise.
Wyoming's middle deciles sit at SD 0.13–0.14, just past the SD of about
0.12 that a 40-point interval implies, so a modest shift in the noise level
moves half the state across a fixed width threshold. The funded set is
partly sheltered from that shift: top-decile SD is only 12% higher than
Louisiana's (0.0592 against 0.0530), which is why the leaver rate moves only
from 24.9% to 26.6%.

**Does the rank-position mechanism bite harder at Wyoming's n?** Partly, and
not in the way the prediction said. Rank position explains more of rank
noise: R² 0.65 against 0.59, and 0.79 against 0.71 once precision is
equalised. The inverted U is *not* steeper in relative terms: the peak
decile is 2.8 times the bottom decile in Wyoming against 3.1 times in
Louisiana. The prediction also said precision
would matter *less* once position is fixed. It matters more: the partial
correlation rose from 0.485 to 0.542. Wyoming does not show the rank map
washing out heterogeneous precision any more thoroughly than Louisiana. Both
channels are stronger at once. A sharper position effect and a stronger
residual precision effect can coexist because the unconditional correlation
between imprecision and rank SD is lower in Wyoming (0.27 against 0.37).
One hypothesis, untested: imprecision in Wyoming is spread more evenly across
rank positions, so it shows up mostly after position is removed. **This is a descriptive pattern in two states,
not a test of the n mechanism.** The chain does not separate n from
cross-tract spread, so whether the higher Wyoming noise comes from fewer
tracts or from narrower input distributions is untested.

## Scorecard against the pre-registered prediction

| Prediction | Result | |
|---|---|---|
| Gate 6,678 / 6,720, pass | 6,678 / 6,720, pass | ✓ |
| Median SD 0.10 (0.085–0.125) | 0.1113 | ✓ in range |
| Median width 32 (27–40) | 36.1 | ✓ in range |
| >40-pt share ~20% | **35.2%** | ✗ |
| Decile leaver rate 28% (20–38) | 26.6% | ✓ |
| Quintile ~20%, quartile ~17% | 20.1%, **20.3%** | quintile ✓, quartile ✗ |
| Decile > quintile > quartile (high confidence) | quintile ≈ quartile | **✗** |
| Cross-tract null | holds | ✓ |
| `no_cov` matches the median | **understates it by 10%** | ✗ |
| 80-replicate ratio ~1.0 | **0.947** | ✗ |
| POV150, UNEMP, NOHSDP > 1.5 | 2.59, 1.57, 1.77 | ✓ |
| MINRTY 1.1–1.6 | 1.21 | ✓ |
| Rank-position R² > 0.59 (point 0.65) | 0.651 | ✓ |
| Partial correlation < 0.485 (point 0.35) | **0.542** | **✗ wrong direction** |
| Profile correlation ≥ 0.85 | 0.950 | ✓ |
| Top-decile noise 1.4× (1.2–1.8) | 1.52× | ✓ |
| Leaver drop ~5 pts | 4.6 (matched EP pair) | ✓ |
| Flip clustered SE ~3× | ~4× | ✓ (not a test) |
| "Bites harder", operationalised as R² up **and** partial correlation down | R² up, partial correlation **up** | **✗ not confirmed** |

**Untested:** STATUS §6 task 3's prediction that the smooth normal
approximation Φ((r−τ)/ς(r)) fails near tie clumps. The chain computes no
such approximation.

## Reproducing this

```bash
cd analysis/wyoming && ./run_all.sh
```

Fetch the inputs listed in `analysis/wyoming/README.md` first. The run
takes about 3 minutes at B = 5,000 and exits nonzero unless the gate passes
and every deterministic manifest field matches exactly. From the repository
root: `bash analysis/wyoming/run_all.sh`.
