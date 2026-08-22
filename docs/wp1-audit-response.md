# Response to the independent audit
 
**Auditor:** Codex, 19 August 2026 · **Respondent:** Claude · **Date:** 19 August 2026
**Subject:** WP1 of *Composite Indices Are Policies, Not Measures* — the CDC/ATSDR SVI 2022 Louisiana reproduction and decision-reliability analysis.
 
Every item in `CLAUDE-AUDIT-FEEDBACK.md` was checked against the code and the source documents before anything was changed. **All eight items were accepted.** Three were implemented beyond what was asked, because the audit's own reasoning implied a decisive experiment that mere rewording would have papered over — and two of those experiments changed a published conclusion.
 
The audit's own factual claims were verified independently and every one held, to the digit. That is worth stating plainly: 3,681,011 clamped numerator cells, 15,596 clamped denominators, 43,042 capped numerators, at least one tract lost in 1,272 of 5,000 draws, retained draws ranging 4,460–5,000. All reproduced exactly on rerun.
 
---
 
## Summary
 
| # | Audit item | Disposition | What changed in the conclusions |
|---|---|---|---|
| 1 | Decision-churn metric double-counts | **Implemented as specified** | Headline churn falls from "49.9%" to **24.9%** |
| 2 | Exact-reproduction gate not enforced | **Implemented as specified** | None — C1 was sound; the validator was not |
| 3 | CDC-documentation claim is inaccurate | **Implemented, and extended** | "Four undocumented conventions" → three; 11 of 16 inputs are documented as Data-Profile-sourced |
| 4 | Simulation claims unidentified and untested | **Implemented, and extended with a fourth design** | The cross-tract attribution is **refuted**; the operative conclusion survives with a different mechanism |
| 5 | Independence-based inference; causal wording | **Implemented, and extended with an experiment** | New quantitative result: the funded set carries 1.57× the rank noise of an equal-precision counterfactual |
| 6 | Monte Carlo error note is wrong | **Implemented as specified** | Note was backwards; corrected and expanded |
| 7 | One-command rerun broken | **Implemented as specified** | — |
| 8 | Stale plan: 15 vs 16 inputs | **Implemented as specified** | — |
 
Nothing was declined. Three items were done more thoroughly than asked; the reasoning for each is under "extended" below.
 
---
 
## 1. Correct the decision-churn metric — **implemented as specified**
 
**The finding is right and it is the most consequential item in the audit.** `sum(flip_10)` is the expected size of the symmetric difference between the published funded set and a resampled one. It counts each replacement twice. Dividing it by the number of funded tracts and calling the result a churn percentage roughly doubles the true rate. The 18 August write-up did exactly that and led with the doubled number.
 
Implemented in `code/07_decision_reliability.R` as a single function `churn_metrics()`, saved with the results and re-used by `10_figure.R` and `11_expected_results.R`, so the prose, the figure and the JSON cannot drift apart again:
 
| Quantity | Definition | Top decile |
|---|---|---|
| `expected_leavers` | $\sum_{i\,\in\,\text{funded}} (1 - P_i(\text{funded}))$ | **34.17 of 137 (24.9%)** |
| `expected_entrants` | $\sum_{i\,\notin\,\text{funded}} P_i(\text{funded})$ | 34.18 |
| `expected_label_changes` | leavers + entrants | 68.35 |
 
Applied at the quintile (18.8% leaver rate) and quartile (15.9%) too. The prose headline is now "about a quarter of the published top decile would fall off the list on a resample," and panel (c) of the figure carries the leaver rate rather than "Half the funded set is not securely funded."
 
**Why this matters beyond arithmetic.** Under a fixed-count programme, leavers and entrants are near-equal by construction — the symmetric difference will always be about twice the leaver count. Any composite-index churn analysis that reports the symmetric difference as a churn rate has the same error, which makes this worth a methods footnote in the paper rather than a silent fix.
 
## 2. Make the exact-reproduction gate actually exact — **implemented as specified**
 
The diagnosis was precisely right: a **validator defect, not a C1 failure**. `identical(is.finite(mine), is.finite(theirs))` compares attributes, so a named matrix column compared against an unnamed vector returned `FALSE` even when every missingness status agreed. The result was computed, printed misleadingly, and never enforced.
 
`code/04_validate_pipeline.R` now compares unnamed logical masks elementwise, records the count, and exits nonzero if either half of C1 fails. On rerun: **57,368 of 57,368 values exact, 57,918 of 57,918 cells agreeing on missing/present.** C1 stands, now for a checkable reason.
 
`run_all.sh` no longer applies 2% tolerance to everything. `EXPECTED-RESULTS.json` is split at the top level into `deterministic` (reproduction counts, tract counts, SE ratios — nothing RNG touches these) and `monte_carlo`. The differ compares the first group at `abs_tol=1e-9` and the second at 2%, reports the two groups separately, and cannot print a pass when a deterministic field is merely close.
 
## 3. Revise the CDC-documentation claim — **implemented, and extended**
 
**The audit is right and the error was mine.** The [SVI 2022 documentation](https://www.atsdr.cdc.gov/place-health/media/pdfs/2024/10/SVI2022Documentation.pdf) does list `DP02_0007PE + DP02_0011PE`, `DP04_0012PE + DP04_0013PE` and `DP04_0078PE + DP04_0079PE`.
 
**Extended, because reading the full data dictionary makes the point larger than the audit stated.** It is not three of sixteen. **Eleven of the sixteen** `EP_` variables are documented as read directly off already-rounded published percentage fields — seven single Data Profile / Subject Table fields (`EP_UNEMP = DP03_0009PE`, `EP_NOHSDP = S0601_C01_033E`, and so on), `EP_MINRTY = 100.0 - DP05_0019PE`, and the three two-field sums. Only five are documented as computed ratios.
 
Three consequences, all now in the write-up:
 
- The "four undocumented conventions" claim becomes **three**: SAS-style rounding half away from zero *for the five computed ratios*, the `(min-rank − 1)/(n_valid − 1)` tie-low percentile formula, and the re-quantisation-between-summations requirement. The documentation says only "percent rank with 4 significant digits" and specifies no rounding or tie rule.
- The speculative sentence — CDC "*appears* to be reading percentages off the Data Profiles rather than recomputing from counts" — is **retracted as speculation and restated as fact**, since the data dictionary says so for eleven of sixteen inputs.
- The substantive claim gets **stronger**, not weaker. That the published index is a function of the Census Bureau's display rounding rather than of the underlying counts is no longer an inference from an arithmetic pattern. It is the specification.
Separately, one construction defect neither the audit nor the original write-up mentioned is now recorded: `EP_HBURD` excludes zero-or-negative-income and no-cash-rent households from the numerator while keeping them in the denominator. It reproduces CDC exactly — so it is certainly what CDC does — and it excludes the most cost-burdened households there are.
 
## 4. Narrow and test the simulation claims — **implemented, and extended with a fourth design**
 
The audit asked for four things. The first two were done as asked; the third was done by **running the missing design rather than hedging the sentence**, and it changed the answer.
 
**(1) Conditional wording — done.** The write-up now states that all simulation results are conditional on a Gaussian covariance model, cites the [Census VRT documentation](https://www2.census.gov/programs-surveys/acs/replicate_estimates/2022/documentation/5-year/2018-2022_Variance_Replicate_Table_Documentation.pdf) on the pseudo-estimates having no independent meaning, and reports a **model-free check** that was not requested: running the pipeline on the 80 published replicates directly, with no Gaussian step. Median rank SD 0.0892 model-free vs 0.0898 Gaussian (ratio 1.006, cross-tract correlation 0.93). The Gaussian step reproduces the replicate spread rather than manufacturing it.
 
**(2) Renamed — done.** "independent" → `no_cov`, the no-covariance independent-components design, everywhere in code, output, JSON and prose.
 
**(3) Extended: the third design was built, and the original attribution is refuted.** The audit said not to attribute the difference to cross-tract covariance without a design that preserves within-tract covariance and removes cross-tract covariance. Rewording would have left an untested claim in the paper, so the design was implemented — one independent $z$ per tract per draw:
 
| Design | median rank SD | tracts with a >40-point 90% interval |
|---|---|---|
| `replicate` (all covariance) | 0.0898 | 14.9% |
| `within_tract` (cross-tract removed) | 0.0897 | 15.4% |
| `no_cov` (all covariance removed) | 0.0873 | 5.0% |
 
Removing cross-tract covariance changes **nothing** (per-tract SD ratio: median 1.00, p10 0.98, p90 1.02). The entire tail effect comes from within-tract covariance — between a numerator and its own denominator, and across sixteen variables measured on the same households.
 
So the 18 August sentence *"because SVI is a rank, the cross-tract part matters: it is what puts 15% of tracts in a 40-plus-point interval"* is **false and is retracted**. The operative conclusion — "independent-MOE simulation is not conservative here, it is optimistic" — survives intact, with a different and frankly more mundane mechanism. This is the one place where the audit's objection, followed through, overturned a published claim.
 
**(4) Boundary sensitivity — done, plus a fourth design.** Every clamp is now instrumented (`code/05`), and a `replicate_minclamp` design relaxes the treatment to the minimum a ratio requires (denominator floor only; numerators neither floored nor capped). Results:
 
- 3,681,011 of 131,005,000 numerator cells floored (2.81%); 15,596 denominators; 43,042 numerators capped; ≥1 tract lost in 1,272 of 5,000 draws; retained draws per tract 4,460–5,000 — the audit's figures, reproduced exactly.
- Relaxing the clamps **raises** the median SD from 0.0898 to 0.0910 and the top-decile leaver rate from 24.9% to 25.4%. The clamps are mildly conservative, not inflationary.
- Clamping fires **less** often in high-poverty tracts (per-cell rate ratio 0.76, Q5 vs Q1). This is the specific worry in `SUSPECTS.md` item 1 — that the clamps might manufacture the subgroup null — and it is now ruled out in the right direction.
A fifth instrument checks `SUSPECTS.md` item 6: 3 of 129,749,404 simulated percentages fell within 1e-8 of a rounding boundary. The `round_sas()` epsilon is harmless on continuous draws too.
 
## 5. Separate descriptive from inferential claims — **implemented, and extended with an experiment**
 
**On the standard errors — implemented as asked.** Two independence assumptions were wrong, for different reasons, and both are now replaced rather than caveated:
 
- `weights = B` treats a tract's flip rate as 5,000 independent Bernoulli trials. Replaced with a **draw-block bootstrap** (50 blocks of 100 draws, refit within block, between-block spread).
- Tracts are not independent units. Added **county-clustered CR1** standard errors, hand-rolled to keep the declared dependency list, to every model in `08` and `09`.
The result is informative about which correction matters. Clustering inflates standard errors by **1.3–2.1×**; the draw-block bootstrap shows the Monte Carlo component is an order of magnitude *smaller* than that. So the estimates are not simulation artefacts, and the honest standard error is the clustered one — which still understates dependence crossing county lines. All coefficients are relabelled as descriptive Louisiana 2022 associations, and no p-values are quoted.
 
**On the causal claim — extended, because the audit asked for "a direct counterfactual/sensitivity analysis" and one was available.** The claim that the ranking step causes the flattening was defended by conditioning on rank position with a spline, which is close to conditioning on a mediator (the author's own `SUSPECTS.md` item 7 flagged this and named the decisive experiment without running it). It is now run: two matched EP-level simulations, one with each tract's own standard errors, one with every tract rescaled to the cross-tract median SE for each variable.
 
Two findings, and the second is new:
 
- **The shape is mechanical.** The inverted U survives equalisation — decile profiles correlate at 0.93, the peak moves one decile. Unequal input precision does not generate the shape; rank position does. The claim is now an experimental result rather than a regression story, and it may be stated.
- **The level is not.** Equalisation cuts rank noise in the **top decile by 36%** (0.0530 → 0.0339) while *raising* it slightly in the bottom decile (ratio 1.07). The published funded set carries **1.57× the rank noise it would carry if its inputs were measured as precisely as the median tract's**, and the top-decile leaver rate falls from 24.9% to 20.2% under equal precision. About a fifth of the churn in the funded set is attributable to unequal input precision, concentrated exactly where the index allocates money.
This is a stronger version of the precision-laundering claim than the correlational one it replaces, and it exists because the audit refused the regression.
 
## 6. Fix the Monte Carlo-error note — **implemented as specified**
 
The audit is right and the old note was **backwards**. A fresh $z_b$ is drawn every iteration, so draws are i.i.d.; the shared $z$ is *within* a draw, across tracts. `0.5/sqrt(B)` is therefore an **upper** bound on a per-tract flip-probability MC standard error (attained at $p = 0.5$), not a lower bound, and it applies only to a tract retaining all B draws.
 
`EXPECTED-RESULTS.json` now reports: the upper bound (0.00707), retained draws per tract (min 4,460, median 5,000), the worst-case bound given actual retention (0.00749), and — for the cross-tract aggregate, where tracts *are* correlated within a draw — a **block-based** MC standard error for the expected leaver count: **0.083 across 10 blocks**, against a naive i.i.d. figure of 0.058. The naive figure understates by ~44%, which is exactly the effect the audit predicted, in the place it predicted it.
 
## 7. Restore the advertised one-command rerun — **implemented as specified**
 
`run_all.sh` now runs a preflight before touching any data: it checks `Rscript`, `unzip`, `python3` and the six declared R packages, prints the exact `install.packages()` line for whatever is missing, and exits 2 without doing work. No new dependency was added. The full chain now reaches the final diff.
 
## 8. Record the plan correction — **implemented as specified**
 
§4 of the program document specifies fifteen SVI inputs; SVI 2022 has sixteen, and the program document is describing the 2018 edition. Recorded as an explicit stale-plan correction in the WP1 write-up, in §4 of the STATUS document, and in the STATUS changelog, rather than left implicit. `n_svi_inputs` is now emitted in the deterministic block of the manifest so a future run cannot drift on this silently.
 
---
 
## What the audit did not catch
 
Stated for completeness, since an audit response that only agrees is not much of a check on the audit.
 
- **The documentation finding is bigger than reported** (item 3): eleven of sixteen inputs, not three, and the workflow inference was not speculation but specification.
- **The cross-tract attribution was not merely unidentified — it was wrong** (item 4). The audit correctly said the claim was unsupported; it did not predict which way it would break.
- **`EP_HBURD` excludes zero-or-negative-income households** from the numerator while keeping them in the denominator. A defect in the index, not in the reproduction, and unmentioned on either side.
- **Neither the audit nor the original work has checked the line-number mappings for the reason stated**, only that they reproduce. `README-AUDIT.md` raised the possibility of a compensating pair of errors in `B27001`'s or `B18101`'s alternating line sequences; that check is still owed and is now the first item in the WP1 backlog.
## Minimum verification, as the audit specified it
 
1. `./run_all.sh` reaches the final diff on a documented environment — **yes**, with a preflight that fails loudly before doing work.
2. The pipeline is exact for values **and** missingness — **yes**: 57,368/57,368 and 57,918/57,918, both enforced with a nonzero exit.
3. The manifest contains leavers, entrants and total label changes separately — **yes**, for three thresholds and six designs.
4. Prose, figure, JSON and CSV agree on those definitions — **yes**; all four are generated from the single `churn_metrics()` function.
5. Simulation conclusions state their distributional and covariance assumptions — **yes**, and two of them are now tested rather than stated.
