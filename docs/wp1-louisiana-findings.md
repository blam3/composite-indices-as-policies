# WP1, first pass: reproducing CDC/ATSDR SVI 2022 for Louisiana and measuring how much of the ranking is survey noise

Brendan Lam · 18 August 2026 · **revised 19 August 2026 after independent audit**

Companion to `composite-indices-as-policies-research-program.md` (§4, WP1)

> **Revision note.** An independent audit (Codex, 19 August 2026) checked this
> work against the code and the source documentation. The reproduction claim
> survived unchanged. Three claims did not, and are corrected below: the
> headline churn number was double-counted, the "undocumented conventions"
> claim was partly wrong, and the attribution of the tail dispersion to
> *cross-tract* covariance was unidentified — and, once the missing design was
> run, turned out to be **false**. Every change is itemised in
> `AUDIT-RESPONSE.md`. Numbers below are from the 19 August rerun.

---

## What was done

The research program's §12 item 1 says: *pull the ACS 5-year variance replicate tables for one state and reproduce the CDC SVI pipeline end to end. You cannot critique a construction you have not built.* That is now done, for Louisiana, ACS 2018–2022, SVI 2022.

Sixteen tract-level [ACS 5-year Variance Replicate Tables](https://www.census.gov/programs-surveys/acs/data/variance-tables.html) (summary level 140, state FIPS 22) supply every SVI input plus 80 replicate estimates of each. The published [CDC/ATSDR SVI 2022 Louisiana file](https://www.atsdr.cdc.gov/place-health/php/svi/svi-data-documentation-download.html) is the reproduction target.

**The reproduction is exact.** All 16 estimated percentages, all 16 percentile ranks, all four theme sums and ranks, and the overall sum and rank — **57,368 of 57,368 values match CDC's published file to the last published digit, for all 1,379 tracts.** The VRT files cover 1,388 tracts; CDC drops the nine water-only tracts (tract code 9900xx).

The exactness gate now checks two things, not one: every published value matches,
**and** the missing/present pattern matches cell for cell (57,918 of 57,918). The
earlier validator computed the missingness check and then neither recorded nor
enforced it — a validator defect the audit caught, not a reproduction failure.

That number is worth more than it looks. Getting to it required recovering three
conventions that CDC does not document, described next. A note on the plan: §4 of
the research program specifies **fifteen** SVI inputs. SVI 2022 has **sixteen**;
the program document is describing the 2018 edition. The code follows the 2022
specification. This is a stale-plan correction, recorded here and in the STATUS
changelog rather than left implicit.

---

## What CDC documents, and what it leaves to you

The earlier version of this write-up claimed four *undocumented* conventions. The
audit checked that against the [SVI 2022 documentation](https://www.atsdr.cdc.gov/place-health/media/pdfs/2024/10/SVI2022Documentation.pdf)
and it is wrong. The correction turns out to strengthen the substantive point
rather than weaken it, which is the pleasant kind of being wrong.

**What is documented.** The 2022 data dictionary gives a source expression for
every `EP_` variable, and eleven of the sixteen are read off *already-published,
already-rounded* percentage fields from the ACS Data Profile and Subject tables:

| Form | Variables | Documented expression |
|---|---|---|
| Single published percentage | `UNEMP`, `NOHSDP`, `UNINSUR`, `AGE65`, `DISABL`, `MOBILE`, `NOVEH` | e.g. `EP_UNEMP = DP03_0009PE` |
| One minus a published percentage | `MINRTY` | `100.0 - DP05_0019PE` |
| **Sum of two published percentages** | `SNGPNT`, `MUNIT`, `CROWD` | `DP02_0007PE + DP02_0011PE`, `DP04_0012PE + DP04_0013PE`, `DP04_0078PE + DP04_0079PE` |
| Computed ratio | `POV150`, `HBURD`, `AGE17`, `LIMENG`, `GROUPQ` | e.g. `(E_POV150 / S1701_C01_001E) * 100` |

So the "double rounding" of `SNGPNT`, `MUNIT` and `CROWD` is not a secret — it
is written down. What I had reported as a discovery about CDC's workflow ("CDC
*appears* to be reading percentages off the Data Profiles") is simply what the
documentation says it does, for eleven of the sixteen inputs. The speculation
comes out; the fact stays, and is now citable.

**What is not documented, and had to be recovered:**

1. **Rounding to one decimal before ranking, half away from zero.** Implied for
   the eleven Data-Profile-sourced variables (a published `PE` field is already
   one-decimal), but stated nowhere for the five computed ratios — and it is
   decisive. Ranking the unrounded percentages reproduces only 17–53% of the
   published percentile ranks depending on the variable; ranking the rounded ones
   reproduces essentially all. R's `round()` uses banker's rounding and gets the
   last digit wrong on a handful of tracts per variable; SAS's `ROUND` (half away
   from zero) is exact.
2. **The percentile-rank formula.** The documentation says only "percent rank
   with 4 significant digits." The rule that reproduces the file is
   `(min-rank − 1) / (n_valid − 1)`, computed over tracts with a valid value,
   ties taking the minimum rank — SAS `PROC RANK` with `TIES=LOW`. Three other
   plausible conventions match 4–15% of values.
3. **Re-quantisation between summation and ranking.** Summing two one-decimal
   numbers in binary floating point produces values that print identically but do
   not compare as equal (`0.1 + 0.2 ≠ 0.3`), silently breaking the ties that rule
   2 is supposed to create. Without re-rounding after each summation the
   reproduction stalls at 99.98% — eleven values across the `RPL_` columns, off by
   ≤ 0.0008. Not consequential for anyone's funding, but it is the difference
   between "close" and "exact," and exactness is what lets the rest of the
   analysis attribute every discrepancy to the thing being studied rather than to
   my arithmetic.

**The consequence, which is the part that matters and is now better supported.**
The published index is *documented* to be a function of the Census Bureau's
display-rounded output rather than of the underlying counts. Two tracts whose
true percentages differ by 0.04 points are forced into a tie; a tract at 12.45%
is treated as 12.5% while its neighbour at 12.44% is treated as 12.4%. A
composite whose value depends on which published table you happened to read it
from is not measuring a property of the place — and here that is not an
inference from an arithmetic pattern, it is the specification.

**One substantive construction defect, noticed and not previously reported.**
`EP_HBURD` counts households paying 30%+ of income on housing among the four
income brackets under \$75,000, and excludes the "zero or negative income" and
"no cash rent" categories from the numerator while leaving them in the
denominator. This reproduces CDC exactly, so it is certainly what CDC does. It is
also perverse: households with zero or negative income are, substantively, the
most housing-cost-burdened households there are. Worth a sentence in the paper.

---

## How much of the ranking is survey noise?

**Design.** For each of B = 5,000 draws, the whole pipeline — component percentages, rounding, sixteen percentile rankings, four theme sums, four theme rankings, total, final ranking — is recomputed. Draws come from the variance replicates:

$$X_b = X_0 + \frac{2}{\sqrt{80}}\sum_{r=1}^{80} z_{br}\,(X_r - X_0), \qquad z_{br}\sim N(0,1)$$

A single draw of $z_b$ multiplies every component's deviation vector for every tract at once, so the joint structure survives: across variables within a tract (shared universes, shared households, shared sample cases) *and across tracts* (replicate $r$ is a common perturbation of the whole sample). By construction $\operatorname{Var}(X_b) = \frac{4}{80}\sum_r (X_r - X_0)^2$, the successive-difference-replication variance the Census Bureau publishes — verified against the `SE` column in the same files (exact to the published integer rounding for every cell with SE ≥ 50).

**These results are conditional on a Gaussian covariance model.** The variance
replicate tables supply a *variance* estimator; the Census Bureau's
[documentation](https://www2.census.gov/programs-surveys/acs/replicate_estimates/2022/documentation/5-year/2018-2022_Variance_Replicate_Table_Documentation.pdf)
is explicit that the pseudo-estimates are constructed to support SDR variance
calculation and have no independent meaning. A Gaussian combination of the
deviations is a defensible model with the right second moment, not the sampling
distribution. Two checks bound how much that assumption is doing:

- **Model-free.** Running the pipeline on the 80 published replicates themselves,
  with no Gaussian step at all, gives a median rank SD of **0.0892** against the
  Gaussian model's **0.0898** (ratio 1.006; correlation across tracts 0.93). The
  Gaussian step reproduces the replicate spread rather than manufacturing it.
- **Boundary treatment.** Gaussian draws of small counts go negative. Across the
  131,005,000 simulated numerator cells, 3,681,011 (2.81%) were floored at zero,
  15,596 denominator cells were floored, and 43,042 numerators were capped at
  their denominator; at least one tract lost a valid percentile in 1,272 of the
  5,000 draws (retained draws per tract range 4,460–5,000). Relaxing the clamps to
  the minimum a ratio needs (denominator floor only) *raises* the median SD from
  0.0898 to 0.0910 and the top-decile leaver rate from 24.9% to 25.4%: the clamps
  are mildly conservative, not inflationary. Clamping is also **less** frequent in
  high-poverty tracts (ratio 0.76, Q5 vs Q1), so it cannot be manufacturing the
  subgroup null.

**Three comparison designs, not one.** The earlier version contrasted the
replicate design with a single "independent" alternative and attributed the
difference to cross-tract covariance. That was not identified — the alternative
removed every source of covariance at once. Three designs now separate them:

| Design | Numerator/denominator and cross-variable covariance | Cross-tract covariance |
|---|---|---|
| `replicate` | preserved | preserved |
| `within_tract` (one $z$ per tract per draw) | preserved | **removed** |
| `no_cov` (independent components, matched marginal SEs) | removed | removed |

**Results, replicate design, Louisiana, overall SVI percentile (`RPL_THEMES`):**

| | |
|---|---|
| Median SD of a tract's percentile | 0.0898 |
| Median width of the 90% interval | **29 percentile points** |
| Tracts whose 90% interval spans >20 points | 1,103 (80.8%) |
| Tracts whose 90% interval spans >40 points | 204 (14.9%) |

**At the decision — and this table was wrong before.** The earlier version reported
`sum(flip)`, the expected number of *changed labels*, as though it were the number
of funded tracts leaving the list. It is the size of the symmetric difference: it
counts each replacement twice, once as a departure and once as an arrival. Under a
fixed-count programme leavers and entrants are near-equal by construction, so
dividing label changes by the number of funded tracts roughly doubles the true
churn rate. The three quantities, separated:

| Funded set | Tracts funded | **Expected leavers** | Expected entrants | Total label changes | P(funded) < 0.90 | Unfunded with P(funded) > 0.10 |
|---|---|---|---|---|---|---|
| Top decile | 137 | **34.2 (24.9%)** | 34.2 | 68.4 | 99 | 120 |
| Top quintile | 273 | **51.2 (18.8%)** | 51.2 | 102.4 | 163 | 155 |
| Top quartile | 342 | **54.4 (15.9%)** | 54.1 | 108.5 | 180 | 172 |

The defensible headline is therefore *a quarter of the published Louisiana top
decile would fall off the list if the same survey were rerun* — about 34 of 137
tracts, with 34 different tracts taking their place, and 68 changed labels in
total. That is a smaller number than the one I published on 18 August and it is
still a large number: 109 of the 137 funded tracts have a 90% interval crossing
the cutoff, 99 have P(funded) < 0.90, and 120 tracts that receive nothing would be
funded at least 10% of the time.

**Where the extra dispersion comes from — the previous attribution was false.**
The 18 August version said the tail of badly-determined tracts was generated by
*cross-tract* covariance. Running the design that isolates it refutes that:

| | median rank SD | tracts with a >40-point interval |
|---|---|---|
| `replicate` | 0.0898 | 14.9% |
| `within_tract` (cross-tract covariance removed) | 0.0897 | 15.4% |
| `no_cov` (all covariance removed) | 0.0873 | 5.0% |

Removing cross-tract covariance changes essentially nothing (per-tract SD ratio:
median 1.00, p10 0.98, p90 1.02). Removing *within-tract* covariance — between a
numerator and its own denominator, and across the sixteen variables measured on
the same households — is what collapses the tail from 15% to 5%. The operative
conclusion survives and is if anything cleaner: **independent-MOE simulation is
not conservative here, it is optimistic**, understating a tract's rank SD by more
than 25% for 14.9% of tracts. But it is optimistic because it throws away the
correlation *inside* a tract, not because it throws away correlation *between*
tracts. The sentence "because SVI is a rank, the cross-tract part matters" is
retracted.

---

## The subgroup prediction did not replicate — and the reason is more interesting

§4 of the program predicted, from [Spielman, Folch & Nagle (2014)](https://pmc.ncbi.nlm.nih.gov/articles/PMC4232960/), that decision-flip rates would be highest in poor and minority tracts: *"reliability is itself non-invariant across subgroups, and the direction of the non-invariance is regressive."* In Louisiana, at the level of the overall SVI percentile, **that is not what happens.**

**The input half of the prediction holds, strongly.** Standard errors of the sixteen estimated percentages are systematically larger in high-poverty tracts:

| Variable | SE ratio, highest- vs lowest-poverty quintile |
|---|---|
| GROUPQ | 3.09 |
| NOVEH | 2.93 |
| UNEMP | 2.39 |
| CROWD | 2.38 |
| POV150 | 2.22 |
| NOHSDP | 2.19 |
| SNGPNT | 1.92 |

A tract-level imprecision index (mean standardised SE across the sixteen) rises 0.18 SD per SD of poverty rate and 0.07 SD per SD of minority share, and falls 0.15 SD per SD of log population. Spielman et al. transfer cleanly to the SVI inputs.

**A note on inference, which the audit was right to demand.** Every coefficient in
this section is a **descriptive association for Louisiana in 2022**, not an
inferential claim. The 18 August version reported p-values from
`glm(..., weights = 5000)` and from OLS, both of which assume independence twice
over: that a tract's flip rate arises from 5,000 independent Bernoulli trials
(it does not — every tract in a draw shares one $z_b$), and that tracts are
independent of each other (they are not — the program document already flags
spatial dependence for WP2 and WP1 did not apply the same standard). Two
replacements are now reported alongside every model: **county-clustered (CR1)**
standard errors, which run 1.3–2.1× the naive ones, and a **draw-block bootstrap**
over 50 blocks of 100 draws, which isolates the Monte Carlo component and shows it
to be an order of magnitude smaller than the clustering correction. The argument
below rests on signs and magnitudes, not on significance.

**The rank half does not hold.** Regress the SD of a tract's overall percentile on
poverty, minority share, education and population: R² = 0.025, and the poverty
coefficient is 0.00008 with a county-clustered SE of 0.0012 — indistinguishable
from zero on any standard. Conditional on distance to the top-decile cutoff,
higher-poverty tracts flip *slightly less* (OR 0.88 per SD; clustered t = −2.5).

**Why: an experiment, not a regression.** The 18 August version explained this by
conditioning on published rank position with a spline and observing that the
subgroup coefficients collapse. That is over-adjustment — rank position is itself
partly a consequence of poverty — and it is a causal story told with a regression.
The claim is now tested directly. Two matched simulations perturb the sixteen
percentages: one gives each tract its own EP-level standard errors, the other
rescales every tract's SE to the cross-tract *median* for that variable, so input
precision is equal by construction and nothing else changes.

| Decile of published percentile | Rank SD, actual precision | Rank SD, precision equalised | Ratio |
|---|---|---|---|
| Bottom | 0.0363 | 0.0389 | 1.07 |
| Median | 0.1128 | 0.0996 | 0.88 |
| Top | 0.0530 | 0.0339 | **0.64** |

The inverted U survives equalisation intact — the two decile profiles correlate at
0.93 and the peak moves by one decile — so **the shape is mechanical**: a tract at
the median has hundreds of neighbours within reach to swap with, a tract at either
extreme has few. Rank position alone explains R² = 0.59 of the variation in rank
SD.

But equalisation moves the *level*, and it moves it most where the money is. The
published top decile carries **1.57× the rank noise it would carry if its inputs
were measured as precisely as the median tract's**, and the top-decile leaver rate
falls from 24.9% to 20.2% under equal precision. Roughly a fifth of the churn in
the funded set is attributable to unequal input precision, concentrated in exactly
the tracts the index exists to find.

The regressive input noise is still there and still propagates — the partial
correlation between input imprecision and rank SD, holding rank position fixed, is
0.485, though that adjustment is itself close to conditioning on a mediator and
should be read as an association. The percentile transform does not remove the
unequal precision. It **hides** it.

**That is the finding, and it is a better one than the one I predicted.** The claim is not "the index is less reliable for the poor." It is:

> The percentile-ranking step launders heterogeneous input precision into near-homogeneous rank noise. Two tracts sitting at the same published SVI percentile are treated identically by every program that uses the index, but one tract's position rests on estimates carrying two to three times the sampling error of the other's. The index publishes no uncertainty at all on `RPL_THEMES`, so nothing downstream can tell the two apart.

This is a statement about differential measurement precision with a direct allocation consequence, it requires no latent variable, and it is the honest analogue of DIF for a composite — just not the one I expected to write.

---

## What this changes upstream

**§6.4(ii) of the program needs restating.** The measurement-error contribution was posed as: the realized assignment probability is $\Pr(w'\hat X \ge \tau \mid w'X = s) = \Phi((s-\tau)/\sigma_g(s))$ with $\sigma_g$ varying by protected group, so the effective rule differs by subgroup even when the nominal rule is identical. On the raw percentage scale that is right and the magnitudes are large. But SVI's threshold is applied on the **rank** scale, and the percentile transform substantially neutralises the group-varying part of $\sigma$, replacing it with a position-varying part. The characterisation still has content — it is just that $\sigma$ indexes *rank position*, not group, and the group effect enters only through where groups sit in the distribution. Worth writing the one-page derivation on the rank scale before building any of WP3 on the raw-scale version.

**The error-aware objective in §6.4(ii) survives intact and gets easier to motivate.** Down-weighting high-MOE indicators is still the right move, and the SE ratios above give it teeth: GROUPQ and NOVEH carry two to three times the sampling error in exactly the tracts the index is meant to find, and both are unit-weighted alongside MINRTY, whose SE is *flat* across the poverty distribution. That is a defensible, substantive reason for unequal weights that an agency can be told out loud.

**WP1's headline should be the churn number, not the subgroup number** — the corrected one. "A quarter of the funded list falls off if you rerun the survey" is the county-emergency-manager sentence. The precision-laundering result is the psychometric contribution and belongs in the same paper, but it is the second paragraph.

**One risk in the register is now retired.** "Composite-indicator literature has already done the sensitivity analysis" — the OECD Step 7 material is about weight and normalisation choices, not about input sampling error propagated through a rank, and none of it uses variance replicates. The differentiation holds.

---

## Reproducing this

```
work/01_build_estimates.R      VRT files -> [tract x component x 81] numerators and denominators
work/02_validate_estimates.R   numerators/denominators vs CDC's published E_ values
work/03_svi_pipeline.R         the CDC aggregation rule as a pure function
work/04_validate_pipeline.R    full pipeline vs CDC's published EP_/EPL_/SPL_/RPL_
work/05_replicate_simulation.R B = 5,000 draws, six designs + the 80-replicate check
work/06_qa_variance.R          SDR estimator vs the published SE column
work/07_decision_reliability.R leavers, entrants, label changes, P(funded)
work/08_subgroup_reliability.R subgroup-conditional reliability
work/09_why_flat.R             the precision-equalisation experiment
work/10_figure.R               the four-panel figure
```

Runtime is about eighteen minutes end to end on one core, 1,388 tracts (six simulation designs at B = 5,000). The pipeline function in `03` takes an arbitrary component specification, so swapping the variable list, the denominators, the weights or the aggregation rule is a one-line change — which is the beginning of the `svi-churn` package the program calls for.

**Data.** ACS 2018–2022 5-Year Variance Replicate Tables, summary level 140, state 22: `B01001 B01003 B03002 B11012 B15002 B16005 B18101 B23025 B25003 B25014 B25024 B25044 B25106 B26001 B27001 C17002`, from `https://www2.census.gov/programs-surveys/acs/replicate_estimates/2022/data/5-year/140/`. Validation target: CDC/ATSDR SVI 2022, Louisiana, census tracts.

---

## Next

0. **Check the sixteen line-number mappings for the reason stated, not merely that they reproduce.** Neither the original work nor the audit did this. `01_build_estimates.R` hard-codes ACS table `ORDER` values for every variable; a compensating pair of errors in an alternating sequence — `B27001`'s `seq(5,29,3)`/`seq(33,57,3)` no-insurance lines, `B18101`'s `seq(4,19,3)`/`seq(23,38,3)` disability lines — would reproduce and still be wrong. This is the single most likely remaining silent error in the project and it is an hour's work against the table shells.
1. **Repeat on a second state with different geography** — the rank-position story predicts the inverted U is universal, and the flip rates should scale with the number of tracts. A state with far fewer tracts (and so coarser rank spacing) is the sharper test. This is cheap now; the code is state-agnostic.
2. **Write the rank-scale measurement-error page** (§6.4(ii), restated). That is the seed of the WP3 theory contribution and it should be written before any optimisation code exists.
3. **Check OpenFEMA's geographic resolution.** Still the highest-value hour in the plan, and still unspent.
