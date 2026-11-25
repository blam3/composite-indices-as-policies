# STATUS — Composite Indices as Policies, and Measures
 
**Living status document for the [research program](program.md).**

**Current verification:** [verification.md](verification.md) supersedes historical claims of ready-to-run infrastructure. The archived §2 numbers have not been rerun; subgroup-ratio discrepancies and unmanifested equalisation claims remain open. No empirical result was changed in the November cleanup.
 
`Last updated: 2026-11-25` · `Last verified against artifacts: 2026-11-25 (static artifact review only; no full-data rerun)` · `Program month: 0` · `Active workpackage: WP1`
 
---
 
## 0. Update contract — read this first if you are an LLM
 
This file is the single source of truth for *where the program is*. The program document is the source of truth for *what the program is*. Do not duplicate the program document here; point at it.
 
**When to update.** In the same turn you do any of the following, update this repository's `docs/STATUS.md`:
 
| Trigger | What counts |
|---|---|
| A workpackage changes state | not started → in progress → drafted → submitted → published, or blocked/abandoned |
| A number in §2 changes | any headline result is recomputed, corrected, or extended to new data |
| A prediction in the program document resolves | confirmed, refuted, or reframed — §4 exists for this |
| An open decision in §3 closes | record what was decided and why, then delete the open item |
| A new artifact is produced | code, figure, dataset, draft, or a new project doc — add it to §5 |
| A blocker appears or clears | especially data access, compute, or an unavailable dependency |
 
Reading this file is **not** a trigger. Neither is a conversation that produces no artifact and no resolved question.
 
**How to update.**
 
1. Bump `Last updated`. Bump `Last verified against artifacts` only if you actually re-ran or re-read the artifacts rather than trusting this file.
2. Edit §1–§6 freely — they describe the present and should never accumulate history.
3. **Append to §7 (Changelog). Never edit or delete an existing changelog entry.** It is the audit trail; a wrong past entry gets a correcting new entry, not a rewrite. Entries retired to `claude/STATUS-archive-2026-08.md` under rule 5 are moved verbatim and stay append-only there.
4. Keep §2 to verified numbers only. If a number came from a run you cannot point to in §5, it does not go in §2 — put it in §7 with a note that it is unverified.
5. Keep this file under roughly 2,500 words. If a section outgrows that, move the detail into its own project doc and leave a one-line pointer here.
6. Never write a status you have not checked. "Unknown" and "not started" are correct answers and are more useful than an optimistic guess.
**Invariants.** The four validation questions in §0 of the program document (differential prediction, decision stability, weight defensibility, transport) are fixed; this file tracks progress against them, it does not renegotiate them. If the program's scope genuinely changes, edit the program document and note the change here.
 
---
 
## 1. Where the program is
 
| WP | What it answers | Status | Blocking | Primary artifact |
|---|---|---|---|---|
| **WP1** Decision reliability | How much of the SVI ranking is survey noise, and is the noise distributed evenly? | **Analysis complete for one state and independently audited; paper not drafted** | nothing | `docs/wp1-louisiana-findings.md` |
| **WP2** Differential prediction | Does the index predict harm equally across groups and regions? | **Not started — gated** | tract-linked outcome data feasibility unknown | — |
| **WP3** Transported safe policy learning | Does a safety guarantee survive transport to an adopting jurisdiction? | **Not started; one derivation now owed before any code.** Objective, policy-class formalism and regret bound now taken from empirical welfare maximization (Kitagawa & Tetenov 2018); the safety constraint sits on top of it | see §4, items 1 and 9 | — |
| **WP4** Whose weights? | Do equal, outcome-optimal, participatory — and now GSCA-estimated — weights induce the same allocation? | **Not started; a fourth benchmark arm added** | WP3 outcome-optimal weights | — |
| **WP5** Composite vs reflective in AI evaluation | Are aggregate AI safety scores composites mistaken for reflective measures? | **Not started; written last by design** | WP1/WP3 results to cite | companion: `equitable-safety-measurement-statement.md`, `claude/project-ideas-equitable-safety-measurement.md` |
 
**One-line state.** WP1's empirical work is done, the reproduction is exact, and it has now survived an independent audit that corrected three claims and overturned one; the program's month-2 gate (outcome data) is still unspent and is the highest-value open question. The public GitHub repository now contains the code and archived outputs. November presentation/reproduction-tooling changes are recorded in the verification note; no full-data rerun was performed. Two adjacent literatures (components-based SEM; empirical welfare maximization) have now been assessed and placed; see §5.
 
---
 
## 2. Verified results — do not re-derive these
 
All from ACS 2018–2022 5-year Variance Replicate Tables, summary level 140, Louisiana (state FIPS 22), validated against the published CDC/ATSDR SVI 2022 Louisiana file. **Numbers below are from the 2026-08-19 post-audit rerun** and supersede the 2026-08-18 figures wherever they differ. Code in §5.
 
**Reproduction fidelity**
- **57,368 of 57,368** published values reproduce exactly — all `EP_`, `EPL_`, `SPL_`, `RPL_` fields for all **1,379** tracts — and **57,918 of 57,918** cells agree on missing-versus-present. Both halves are now enforced with a nonzero exit; the earlier validator computed the missingness check and neither recorded nor enforced it.
- The VRT files carry 1,388 tracts; CDC drops the 9 water-only tracts (code `9900xx`).
- **Three** CDC conventions had to be reverse-engineered, not four: SAS-style rounding half away from zero (decisive for the five computed-ratio variables), the `(min-rank − 1)/(n_valid − 1)` tie-low percentile rule, and re-quantisation between summation and ranking. The two-field Data Profile sums for `EP_SNGPNT`, `EP_MUNIT` and `EP_CROWD` **are** documented. In fact **11 of the 16** `EP_` variables are documented as read off already-rounded published `DP`/`S` percentage fields — so the claim that the index inherits Census display rounding is not an inference, it is the specification.
- The successive-difference-replication variance estimator reproduces the Census-published `SE` column exactly to integer rounding for every cell with SE ≥ 50.
**Decision reliability (B = 5,000 draws, replicate design)**
- Median SD of a tract's overall percentile: **0.0898**. Median 90% interval width: **29 percentile points**. 80.8% of tracts exceed a 20-point interval; 14.9% exceed 40 points.
- Top decile: 137 tracts funded; **expected leavers 34.2 (24.9% of the published list)**, expected entrants 34.2, total label changes 68.4. The 2026-08-18 figure of "68.4 (49.9%)" was the symmetric difference divided by the funded count and is **withdrawn**. 109 of 137 have a 90% interval crossing the cutoff; 99 have P(funded) < 0.90; 120 unfunded tracts have P(funded) > 0.10.
- Top quintile leaver rate 18.8%; top quartile 15.9%.
- No-covariance simulation ("independent MOE") matches the replicates at the median but understates SD by >25% for 14.9% of tracts and puts 5.0% of tracts in a >40-point interval where the replicates find 14.9%. **It is optimistic, not conservative.**
- **The mechanism was misattributed and is corrected.** Removing *cross-tract* covariance alone changes nothing (median SD 0.0897 vs 0.0898; >40-point fraction 15.4% vs 14.9%). The tail comes entirely from *within-tract* covariance — numerator with its own denominator, and across the sixteen variables measured on the same households.
- **Robustness.** Running the pipeline on the 80 published replicates with no Gaussian step gives median SD 0.0892 against the model's 0.0898 (ratio 1.006, cross-tract correlation 0.93). Relaxing the boundary clamps to the minimum a ratio needs *raises* the leaver rate from 24.9% to 25.4%; clamping fires less often in high-poverty tracts (0.76 Q5/Q1), so it is not manufacturing the subgroup null.
**Subgroup-conditional reliability** — all coefficients are descriptive Louisiana 2022 associations reported with county-clustered (CR1) standard errors and a draw-block bootstrap; no p-values are quoted.
- Input precision *is* regressive: SE ratios, highest- vs lowest-poverty quintile — GROUPQ 2.62, NOVEH 2.51, UNEMP 2.39, CROWD 2.38, POV150 2.22, NOHSDP 2.19, SNGPNT 1.92. `MINRTY` is flat (0.85).
- Rank noise is **not** regressive at the level of the overall percentile. Rank position alone explains R² = 0.59 of rank SD (inverted U, peaking mid-distribution). Conditional on distance to the cutoff, higher-poverty tracts flip *slightly less* (OR 0.88 per SD, clustered t = −2.5).
- **New, and now experimental rather than correlational.** Equalising every tract's input precision to the cross-tract median leaves the inverted-U shape intact (decile profiles correlate 0.93) — so the shape is mechanical — but cuts rank noise in the **top decile by 36%** and drops the top-decile leaver rate from 24.9% to **20.2%**. The published funded set carries **1.57× the rank noise** it would carry under equal input precision. About a fifth of the churn in the funded set is attributable to unequal input precision.
- Partial correlation between input imprecision and rank SD, holding rank position fixed: **0.485** (an association; the adjustment is close to conditioning on a mediator).
**The WP1 claim, as it now stands.** The percentile-ranking step launders heterogeneous input precision into near-homogeneous rank noise. Two tracts at the same published percentile are treated identically by every program using the index, but one's position rests on estimates carrying two to three times the sampling error of the other's — and the index publishes no uncertainty on `RPL_THEMES` at all. The equalisation experiment puts a number on the allocation consequence: a fifth of top-decile churn.
 
---
 
## 3. Open decisions
 
| # | Decision | Why it matters | Owner |
|---|---|---|---|
| 1 | Which threshold program anchors WP3's identification (NMTC, LIHTC QCT, CDBG-DR MID, or none) | Without a sharp eligibility threshold, WP3 is a targeting problem with a welfare functional, not causal policy learning. The program document says do not blur this. | researcher |
| 2 | Whether WP2 proceeds, on the month-2 gate | If tract-linked outcome data is infeasible, the fallback is WP1 + WP3-as-theory + WP5 — still coherent, decided deliberately rather than discovered at month 6 | researcher |
| 3 | Second state for the WP1 replication, and whether the paper is one-state or multi-state | Affects framing: a single state is a case study, several is a claim about the index. The prompt pack proposes Wyoming (FIPS 56) on the coarse-rank-spacing argument. **New input:** the EWM regret bound scales as √(VC(Π)/n), which argues for a multi-state or national target on statistical rather than rhetorical grounds — illustrative scaling only, not a §2 number. The choice is still open. | researcher |
| 4 | Whether the Data Profile rounding finding is a footnote or a section | Now stronger than when first raised: it is documented CDC practice for 11 of 16 inputs, not an inference. That makes it citable and harder to wave away. | researcher |
 
---
 
## 4. Corrections owed to the program document
 
Recorded here rather than silently edited into `docs/program.md`, so the change is visible.
 
1. **§6.4(ii) needs restating on the rank scale.** The measurement-error contribution was posed as `Pr(w'X̂ ≥ τ | w'X = s) = Φ((s−τ)/σ_g(s))` with `σ_g` varying by protected group. That is correct on the percentage scale and the magnitudes are large (§2). But SVI's threshold is applied on the **rank** scale, where the percentile transform substantially neutralises the group-varying part of σ and replaces it with a position-varying part — now shown experimentally, not just by regression. **This one-page derivation is owed before any WP3 optimisation code exists.**
2. **§4's predicted finding was refuted.** "Flip rates are highest in poor and minority tracts" does not hold in Louisiana at the overall-index level. The replacement claim (§2) is stronger and is still a statement about differential measurement precision with an allocation consequence.
3. **§4's headline should be the churn number, not the subgroup number — and the corrected churn number.** "A quarter of the funded list falls off if you rerun the survey" is the sentence a county emergency manager acts on. The earlier "half" was arithmetically wrong.
4. **One risk in §10 is retired.** "Composite-indicator literature has already done the sensitivity analysis" — OECD Step 7 covers weight and normalisation choices, not input sampling error propagated through a rank, and none of it uses variance replicates. Differentiation holds.
5. **§6.4(ii)'s error-aware objective is strengthened, not weakened.** Down-weighting high-MOE indicators now has empirical teeth: GROUPQ and NOVEH carry 2.5× the sampling error in exactly the tracts the index is meant to find, while MINRTY's SE is flat — and all three are unit-weighted. The equalisation experiment quantifies what that costs at the decision.
6. **§4 says fifteen SVI inputs; SVI 2022 has sixteen.** The program document is describing the 2018 edition. Stale-plan correction; the code follows the 2022 specification and `n_svi_inputs` is now asserted in the results manifest.
7. **A retraction.** The 2026-08-18 claim that cross-tract covariance generates the tail of badly-determined tracts is **false** (§2). The operative conclusion — independent-MOE simulation is optimistic, not conservative — survives, with within-tract covariance as the mechanism.
8. **§1.1's invariance claim is too strong and is narrowed.** "For pure composites the standard test is not hard, it is undefined" holds for metric and scalar invariance, which are statements about loadings and intercepts. It does not hold generally: Henseler, Ringle & Sarstedt's MICOM procedure defines compositional invariance for composite models, and it is testable. What makes it uninformative for SVI is that CDC fixes every weight at unity by decree, so compositional invariance is satisfied by construction. MICOM Step 3 (equality of composite means and variances across groups) is not vacuous and is runnable on the existing pipeline. Revised claim: scalar invariance undefined; compositional invariance defined but trivial under decreed weights; differential prediction and decision stability remain the operative analogues.
9. **§6.3's policy class has a psychometric precedent.** Cho & Hwang (2024, *Psychometrika*) introduce convex GSCA, whose components carry non-negative weights summing to one, motivated by producing interpretable composite indexes. This is the same constraint set, arrived at independently. Cite it when introducing Π; it forecloses the "you chose the simplex for tractability" objection.
---
 
## 5. Artifacts and provenance
 
**Presentation and verification artifacts (2026-11-25)**

- `docs/case-study.md`: reader-facing findings traced to the manifest.
- `docs/verification.md`: verification scope, limits, and unresolved discrepancies.
- `scripts/check_inputs.py`: input staging preflight and current-file fingerprints.
- `scripts/compare_results.py`: exact/tolerant manifest comparison.
- `tests/test_reproduction_tools.py` and `tests/check_pipeline.R`: failure and boundary checks.

**Project documents**
 
| Path | Role |
|---|---|
| `docs/program.md` | The program. Scope, theory, prior art, risk register, sequencing. |
| `docs/wp1-louisiana-findings.md` | WP1 results in full, with method detail and source links. Revised 2026-08-19. |
| `docs/wp1-audit-response.md` | Item-by-item response to the independent audit; what changed and why. |
| `claude/cip-github-workflow.md` | Repository plan and exact git/gh commands; the branch-per-agent-session review convention. |
| `claude/cip-prompt-pack-next-steps.md` | Engineered prompts for the five §6 LLM tasks, with routing, acceptance criteria and grading rubric. |
| `claude/cip-components-sem-and-welfare-maximization.md` | Components-based SEM (PLS-SEM, GSCA) and empirical welfare maximization, assessed against WP3/WP4. **Status checked 2026-08-19: delivered as a downloadable file in the source conversation, not present in the project.** Import it before citing it from here. |
| `claude/STATUS-archive-2026-08.md` | Retired changelog entries (2026-08-18 and the first 2026-08-19 entry), moved verbatim under §0 rule 5. |
| `equitable-safety-measurement-statement.md` | The AI-safety framing WP5 returns to. |
| `claude/project-ideas-equitable-safety-measurement.md` | Idea tier list for the AI-side program; WP5 is its intellectual sibling. |
| `docs/wp1-line-number-verification.md` | The sixteen ACS line-number mappings checked against the published 2018–2022 5-year table shells, blind-derived before the code was opened. Closes §6 LLM task 1. New 2026-08-23. |
| `docs/STATUS.md` | This file. |
 
**Code** — `svi-wp1-audit-revised.tar.gz`, delivered 2026-08-19 (supersedes `svi-wp1-louisiana-code.tar.gz`, 2026-08-18). R, ~18 min end to end on one core at B = 5,000. **The code is now committed under `analysis/louisiana/code/`; the earlier tarball is historical provenance.**
 
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
 
The six simulation designs: `replicate` (all covariance), `within_tract` (cross-tract removed), `no_cov` (all removed), `replicate_minclamp` (boundary sensitivity), and the matched EP-level pair `ep_actual` / `ep_equalised` (the precision-equalisation experiment).
 
`03_svi_pipeline.R` takes an arbitrary component specification, so swapping any of them is a one-line change. This is the seed of the `svi-churn` package the program calls for.
 
**Data** — 16 ACS 2018–2022 5-year VRT files, summary level 140, state 22: `B01001 B01003 B03002 B11012 B15002 B16005 B18101 B23025 B25003 B25014 B25024 B25044 B25106 B26001 B27001 C17002`, from `https://www2.census.gov/programs-surveys/acs/replicate_estimates/2022/data/5-year/140/`. Validation target: CDC/ATSDR SVI 2022 Louisiana, `https://svi.cdc.gov/Documents/Data/2022/csv/states/Louisiana.csv`.
 
**Environment gotcha for LLM sessions.** Cowork's sandbox proxy blocks `census.gov` and `cdc.gov`; `WebFetch` on the VRT directory returns `ROBOTS_DISALLOWED`. The route that worked: drive the user's Chrome to each file URL (downloads land in `~/Downloads`), then `device_stage_files` into the session. GitHub, PyPI and npm are reachable; CRAN is not — install R and R packages from `apt` (`r-base-core`, `r-cran-data.table`, `r-cran-ggplot2`, `r-cran-dplyr`, `r-cran-gridextra`, `r-cran-jsonlite`). Disable any `download.docker.com` apt source first or `apt-get update` fails. **This is why tasks touching census.gov, cdc.gov or CRAN are routed to Claude Code running locally rather than to Cowork.**
 
**Verification script (not in the run_all chain)** — `analysis/louisiana/code/exploratory/verify_line_numbers.R`, added 2026-08-23. Checks the line-number mappings against the published table shells four ways: shell line count vs VRT `ORDER` count; shell indent tree vs VRT arithmetic (every parent row = sum of its children, all 1,388 tracts); the `TITLE` the VRT itself carries at every indexed line; and the compensating-offset arithmetic for `B27001` and `B18101`. Exits nonzero on any failure. It needs the shell file, which it fetches to `data/raw/` if absent, so it is kept out of `run_all.sh`.

**Other outputs** — `svi_decision_reliability.png` (four-panel figure), `tract_reliability_with_covariates.csv`, `tract_decision_reliability.csv` (all six designs), `EXPECTED-RESULTS.json`.
 
---
 
## 6. Next steps
 
**For the researcher** — things requiring judgment, access, or a decision no agent should make.
 
1. **Complete a fresh full-data rerun.** The public repository exists. Use `data/README.md` and the repaired runner, retain input fingerprints, and resolve the discrepancies in `docs/verification.md`.
2. **Spend the OpenFEMA afternoon.** Check the actual geographic resolution of Individual Assistance registrations and verified loss. This is the month-2 gate (open decision #2) and the highest-value unspent hour in the plan.
3. **Read Spielman et al. (2020) and the Rufat–CDC exchange in full, in that order**, noting where each side's argument would be settled by a differential-prediction analysis neither ran. Not yet done.
4. **Pick the WP3 anchor programme** (open decision #1).
5. **Decide whether the Data Profile rounding finding is a footnote or a section** (open decision #4) — it is now stronger than when the question was first posed.
6. **Import `claude/cip-components-sem-and-welfare-maximization.md` into the project** (§5), or decide it stays a local file. §4 items 8–9 and §6 task 6 depend on it.
**For an LLM session** — executable now, with acceptance criteria. **Engineered prompts for tasks 1–5, with surface routing and a grading rubric, are in `claude/cip-prompt-pack-next-steps.md`. Run them one task per session, one branch, one pull request; do not one-shot them.**
 
1. ~~**Verify the sixteen ACS line-number mappings for the reason stated, not merely that they reproduce.**~~ **Done 2026-08-23** — `docs/wp1-line-number-verification.md`, branch `wp1/verify-line-numbers`. All sixteen numerator line sets agree with a derivation made blind from the published shells; six denominators are taken from a same-universe cell in a different table and were shown bit-identical across all 1,388 tracts and all 81 slices. No mapping was wrong, so no code changed and `EXPECTED-RESULTS.json` is untouched. The named compensating-error risk is foreclosed structurally, not empirically: both halves of each alternating sequence enter additively, so any off-by-one moves the numerator by a factor of at least 3.2. **Task 4 is unblocked.**
2. **Write the rank-scale measurement-error derivation** (§4, item 1). One page. Acceptance: an explicit expression for the realised assignment probability as a function of rank position, with the group effect entering only through the distribution of group membership over rank; states clearly what is lost relative to the raw-scale version. It can now cite the equalisation experiment as the empirical counterpart. **Amended 2026-08-19: fold the EWM welfare functional and its notation in from the start** — retrofitting it into a finished derivation is more work than writing it in. Amend Prompt 2 before running it. **Do this before any WP3 code.**
3. **Replicate WP1 on a second state.** The code is state-agnostic — change the FIPS and the file list. Prefer a state with far fewer tracts, where rank spacing is coarser and the rank-position mechanism should bite harder. Acceptance: exact reproduction against that state's published CDC file (values *and* missingness; the bar is 100%), plus the §2 reliability numbers recomputed. Note that a clean second state is *not* a check on the line-number mappings — a compensating offset is a property of the code and compensates identically in every state.
4. **Turn `03_svi_pipeline.R` into `svi-churn`.** Package skeleton, one exported function taking a composite specification and returning leaver/entrant/label-change probabilities, tests that assert exact reproduction of the Louisiana file as a regression test. Acceptance: `R CMD check` clean. **Amended 2026-08-19: add weight-space perturbation as the package's second axis** — input-error churn and weight churn are the same computation with a different perturbation, which is what makes `svi-churn` a tool for composite indices generally rather than for ACS sampling error specifically. In scope for Prompt 4. ~~**Blocked by task 1.**~~ **Unblocked 2026-08-23** — the mappings are verified, so the regression fixture can be frozen against them.
5. **Draft the WP1 paper.** Lead with the corrected churn number, follow with precision-laundering and the equalisation experiment. Target *Natural Hazards* or *Annals of the AAG* to land inside the Rufat/CDC exchange. Do not draft before step 3 unless the researcher has decided the paper is single-state (open decision #3).
6. **Run MICOM Step 3 on the existing Louisiana pipeline** (new, 2026-08-19; no prompt in the pack yet). Equality of composite means and variances across regions is defined for composite models and is not made vacuous by CDC's decreed unit weights — Steps 1 and 2 are. Acceptance: the comparison run across a stated regional partition of Louisiana, with the §4 item 8 framing stated up front so the result is not mis-sold as scalar invariance. Needs no outcome data, so it is not gated behind decision #2.
**Explicitly not next.** Do not start WP3 optimisation code, do not build a MILP, and do not fit anything to outcome data until decisions #1 and #2 close.
 
---
 
## 7. Changelog
 
*Append only. Never edit or delete an entry — correct a wrong entry with a new one. Entries before 2026-08-19 15:00 have been moved verbatim to `claude/STATUS-archive-2026-08.md` under §0 rule 5; that file is append-only too.*
 
**2026-08-19 — Program infrastructure specified: public repository plan and an engineered prompt pack for the §6 LLM tasks. No empirical claim changed.**
Two new project docs, both listed in §5. `claude/cip-github-workflow.md` specifies a public monorepo (`composite-indices-as-policies`) holding the analysis, the future `svi-churn` package and the program documents, with a bootstrap script, the exact `git`/`gh` commands, a repository `CLAUDE.md` encoding the hard rules and the six traps that have already bitten this project, and the convention that every agent session gets its own branch and pull request so model output is reviewed as a diff rather than as prose. `claude/cip-prompt-pack-next-steps.md` supplies engineered prompts for all five §6 LLM tasks.
 
Three things the prompt pack established that this file did not previously record, each now amended into §5 or §6. **A dependency:** task 1 blocks task 4, because the package's regression fixture would otherwise freeze a possibly-wrong line-number mapping into the definition of correct. **A limit:** a clean second-state replication is not a check on the line-number mappings, since a compensating offset is a property of the code and compensates identically in every state. **A routing rule:** tasks needing census.gov, cdc.gov or CRAN cannot run in the Cowork sandbox and go to Claude Code running locally.
 
Also recorded as a live risk: the WP1 code exists only as a tarball on the researcher's machine. Standing up the repository is now §6's first researcher item.
 
**2026-08-19 — Two adjacent literatures assessed; one §1.1 claim narrowed; EWM promoted to load-bearing. No empirical claim changed.**
New project doc `claude/cip-components-sem-and-welfare-maximization.md`. Components-based SEM (PLS-SEM, GSCA) is a competing answer to WP3's weight question, not an alternative measurement model, and cannot route around the outcome-data gate, use the SDR variance structure, or model the rank step. Verdict: GSCA enters WP4 as a fourth benchmark arm; PLS-SEM is declined on reputational grounds. Empirical welfare maximization (Kitagawa & Tetenov 2018) is the foundation of safe policy learning rather than an alternative — it supplies WP3's objective, policy-class formalism and VC-based regret bound, and the safety constraint sits on top because the incumbent is real, the assignment is deterministic, and utilitarian averaging is indifferent to who is helped. Three new no-outcome-data experiments logged (MICOM Step 3 across regions; weight-space decision stability as `svi-churn`'s second axis; EWM notation folded into the owed rank-scale derivation). Bears on open decision #3: the EWM regret bound scales as √(VC/n), which favours a multi-state or national target on statistical rather than rhetorical grounds — illustrative scaling only, not a §2 number.
 
**2026-08-19 — Housekeeping: these edits transcribed from the source conversation; changelog archived; one status claim checked rather than copied.**
The two §4 items, the changelog entry above and the two operational notes were drafted in the conversation "Modeling social vulnerability with components-based SEM", which had no write access to the project and left the exact text to be pasted. Applied here verbatim except where noted. The operational notes landed as amendments to §6 LLM tasks 2 and 4, and MICOM Step 3 was added as §6 LLM task 6 (it has no prompt in the pack yet, so tasks 1–5 remain the pack's scope).
 
Two departures from a literal paste, both under §0 rule 6. **First**, `claude/cip-components-sem-and-welfare-maximization.md` is listed in §5 with its status checked rather than assumed: it was delivered as a downloadable file in that conversation and is *not* in the project's document list as of this update, so §4 items 8–9 and §6 task 6 currently cite a document a future session cannot open. Importing it is now §6 researcher item 6. **Second**, §7's standing housekeeping note is discharged: the 2026-08-18 entry and the first 2026-08-19 entry were moved verbatim to `claude/STATUS-archive-2026-08.md`, per §0 rule 5, and §0 rule 3 was extended to say that archived entries stay append-only. That leaves this file at roughly 4,200 words against §0's ~2,500-word guideline. §7 is no longer what overruns it — §2 is. The next structural move, for whoever updates this next, is to point §2 at `claude/wp1-svi-reproduction-louisiana-findings.md` for the method detail and keep only the headline numbers here.

**2026-08-23 — The sixteen ACS line-number mappings are verified against the published table shells. No mapping was wrong; no number in §2 changes.**
§6 LLM task 1, the one flagged as "the single most likely remaining silent error in the project", is closed. New artifact `docs/wp1-line-number-verification.md` and new script `analysis/louisiana/code/exploratory/verify_line_numbers.R`, both in §5; branch `wp1/verify-line-numbers`.

Method, with the order load-bearing: the sixteen variables' intended numerator and denominator quantities were written down from the CDC/ATSDR SVI 2022 data dictionary, then the line numbers were re-derived from the published 2018–2022 5-year table shells (`ACS20225YR_Table_Shells.txt`), and only then was `01_build_estimates.R` opened and diffed. Nothing was accepted on the grounds that the pipeline reproduces.

**Result: all sixteen numerator line sets agree exactly with the blind derivation.** One class of difference, recorded as a note rather than a finding: six variables (`EP_HBURD`, `EP_SNGPNT`, `EP_NOVEH` on `B25003` line 1; `EP_AGE65`, `EP_AGE17`, `EP_MINRTY` on `B01003` line 1) take their denominator from a same-universe cell in a *different* table than the derivation named. Those cells were checked and are bit-identical to the in-table alternative across all 1,388 tracts and all 81 slices — point estimate and every replicate — so the substitution cannot move the simulation's covariance structure either.

**The compensating-error risk is foreclosed structurally, which is a stronger result than "we looked and it was fine".** In both `B27001` and `B18101` each 3-row cycle is (subtotal, category A, category B) with A + B = subtotal, and both halves of the sequence enter the numerator additively with the same sign. No subtraction appears anywhere in either mapping, so an offset cannot cancel another — it can only move the numerator in one direction. Louisiana totals: `EP_UNINSUR` 8.05% correct against 46.95%–99.39% for every single-step offset; `EP_DISABL` 15.80% correct against 50.93%–100.00%. The smallest achievable perturbation is ×3.2. `B16005` carries the same 5-row hazard, was not named in the task, and was checked the same way; it agrees, and independently matches the sixteen cells CDC's own dictionary lists.

Three supporting checks, all in the new script and all exiting nonzero on failure: the shell line count equals the VRT `ORDER` count for all sixteen tables; the shell's indent tree is arithmetically true of the VRT estimates (every parent row equals the sum of its immediate children, all 1,388 tracts, fourteen hierarchical tables); and the `TITLE` the VRT itself carries at every indexed line is the shell's label. The second matters most — `B25106` has eight rows labelled `30 percent or more` and the income bracket lives only in the parent header, so the indent check is what actually pins line 6 to `Less than $20,000`.

**`run_all.sh` was not rerun and `EXPECTED-RESULTS.json` is unchanged**, because no line of `01_build_estimates.R` changed and nothing downstream could. The reproduction gate stands where the 2026-08-19 rerun left it. **The state totals quoted above are diagnostics, not results**: they trace to the committed script but are deliberately not added to the manifest, which is the pipeline's, and they are logged here rather than promoted to §2.

One incidental defect fixed while doing this. `.gitignore` anchored `data/raw/*` at the repository root, but `00_config.R` puts `DIR_RAW` at `analysis/<state>/data/raw/140`, so the 177 MB of VRT files and the CDC validation file a session must fetch were **not** ignored — a session that staged them and ran `git add -A` would have committed them, against the hard rule in `CLAUDE.md`. Added `**/data/raw/*`, `**/data/derived/*` and the pipeline's `work/` and `outputs-rerun/` directories.

One defect noted and *not* fixed, because it is CDC's document and not ours: the SVI 2022 data dictionary's `EP_MINRTY` cell reads `100.0 - DP05_0019PE`, which is the under-18 percent. The `E_MINRTY` row (`DP05_0001E - DP05_0079E`) and the footnote both make the intended quantity unambiguous, and this pipeline follows the intended one.


**2026-11-25 — Presentation and reproduction-entry repairs; no scientific result changed.**

Authorized direct commits by the researcher for employer presentation. Rewrote
README and input layout, repaired runner/Makefile paths and missing-reference
handling, replaced nonexistent checksum verification with explicitly scoped
current-file fingerprints, and added comparison/boundary checks. Repaired the
truncated findings landing page while preserving its prior contents verbatim.
New case study uses only manifest-traceable values. R and source data were not
available in the cleanup environment; no full-data rerun is claimed. The GROUPQ
and NOVEH ratios differ between historical prose and manifest; equalisation
headlines lack direct manifest fields. Both are recorded as unresolved in
`docs/verification.md`; no choice of numbers or baseline change was made.
