# Composite Indices Are Policies, Not Measures
 
### A research program on validating, repairing, and transporting allocation scores — with a return route to LLM safety evaluation
 
Drafted 2026-08-18. Companion to `equitable-safety-measurement-statement.md` and `project-ideas-equitable-safety-measurement.md`.
 
---
 
## 0. One-paragraph statement
 
Social vulnerability indices, environmental justice screens, deprivation scores, and area-level need measures are treated as if they measured a latent trait of a place. They do not. They are **composites** in Bollen and Bauldry's sense — weighted sums whose coefficients are conveniences, not structural effects — and they exist to induce an allocation. Once you say that plainly, the validation questions become well-posed: not "do the items hang together" (there is no latent variable for them to hang from) but *does the score predict the harm it is meant to proxy, equally across the groups it sorts; is the resulting ranking stable given the survey error in its inputs; do its weights encode a defensible normative position; and does any guarantee established in the jurisdiction that built it survive transport to the jurisdiction that adopts it.* This program answers those four questions for a real index, then supplies a constructive alternative: learn the weights directly as a **safety-constrained allocation policy**, provably no worse than the incumbent for any protected subgroup, with an explicit account of how that guarantee degrades under distribution shift. The same reframe applies, without modification, to aggregate LLM safety scores — which are also composites, also mistaken for reflective measures, and also used to gate a decision.
 
---
 
## 1. The measurement-theoretic reframe
 
### 1.1 What kind of object is a vulnerability index?
 
Bollen and Bauldry ([2011, *Psychological Methods*](https://pmc.ncbi.nlm.nih.gov/articles/PMC3889475/); [DOI](https://doi.org/10.1037/a0024448)) distinguish four things psychologists habitually conflate:
 
| Type | Direction | Do items need conceptual unity? | Error term? |
|---|---|---|---|
| Effect (reflective) indicators | latent → item | yes | yes |
| Causal indicators | item → latent | yes | yes |
| **Composite (formative) indicators** | **items → exact linear combination** | **no** | **no** |
| Covariates | control variables | n/a | n/a |
 
CDC/ATSDR's SVI sums fifteen percentile-ranked ACS variables and re-percentiles the total. There is no disturbance term, no conceptual unity requirement, and no latent variable that the items are indicators *of*. The construct is *defined by the aggregation rule*. This is the third row.
 
Two consequences that matter for how you spend your time:
 
1. **Internal consistency is not a weak form of evidence here — it is a category error.** Cronbach's alpha, dimensionality checks, and factor structure are questions about the second row. Running them on a composite produces numbers that mean nothing, which is why the SVI literature's periodic PCA teardowns have never landed as decisively as they should.
2. **Measurement invariance in its standard form has no referent.** Configural/metric/scalar invariance are statements about loadings and intercepts linking a latent variable to indicators. With no latent variable, there is nothing to constrain. Your instinct that "testing invariance in formative and network models is less straightforward" is correct but understates it: for pure composites the standard test is not hard, it is undefined.
This is *good news for the project*. It means the honest analogues — differential prediction, decision stability, weight transport — are underexplored precisely because everyone reaches for the reflective toolkit first and either produces uninterpretable output or gives up.
 
### 1.2 Why not a network model
 
Your network instinct is tracking something real: deprivations are mutually reinforcing, and a Gaussian graphical model would show it. But psychometric network models presume individual-level dynamic interaction among symptoms or attributes. SVI's inputs are *tract-level ACS aggregates* — percentages, not persons. A partial correlation network over tract percentages is a description of ecological covariance, and reading its edges causally imports an ecological inference you cannot cash out. The object you actually want is a structural causal model over neighborhood attributes: same graph, better-defined semantics, and it is the formalism you already work in. Keep the network intuition as substantive motivation for why the outcome model needs interaction terms; do not make it the measurement model.
 
### 1.3 The reframe
 
> An index that ranks tracts and funds the top decile is a policy $\pi(x) = \mathbb{1}\{w'x \ge \tau\}$. Constructing an index is policy learning under an interpretability constraint.
 
Everything below follows from taking that literally.
 
---
 
## 2. Prior art you must not rediscover
 
The composite-indicator methodology literature is substantial and balkanized away from psychometrics. Read these before writing a line of code.
 
**Composite indicator methodology**
- OECD/JRC, [*Handbook on Constructing Composite Indicators: Methodology and User Guide*](https://www.oecd.org/en/publications/handbook-on-constructing-composite-indicators-methodology-and-user-guide_9789264043466-en.html) (Nardo, Saisana, Saltelli, Tarantola, Hoffmann, Giovannini, 2008). [Full PDF](https://knowledge4policy.ec.europa.eu/sites/default/files/jrc47008_handbook_final.pdf). Step 7 is uncertainty and sensitivity analysis — it already covers a chunk of the rank-stability idea. Cite it, do not reinvent it.
- Alkire & Foster's multidimensional poverty measurement work established robustness-to-weighting as standard practice in development measurement; check the current [OPHI methodological notes](https://ophi.org.uk/) before claiming novelty on weight sensitivity.
**Social vulnerability index critique**
- Spielman, Tuccillo, Folch, Schweikert, Davies, Wood & Tate (2020), [Evaluating social vulnerability indicators](https://link.springer.com/article/10.1007/s11069-019-03820-z), *Natural Hazards*. Shows SoVI is internally inconsistent — the same place, same data, different SoVI-based measurements give strikingly different answers — and, crucially, **theoretically misaligned**: increases in unemployment sometimes *decrease* measured vulnerability. Note that second finding; §5 fixes it with a sign constraint.
- Rufat, Tate, Emrich & Antolini (2019), [How Valid Are Social Vulnerability Models?](https://shs.hal.science/halshs-02485376/file/Rufat_2019_How_Valid_Are_Social_Vulnerability_Models.pdf), *Annals of the AAG*. Construct validation against Hurricane Sandy outcomes. Indices explained assistance applications reasonably and property loss poorly; weighted and profile configurations outperformed the standard indices.
- The published dispute is a gift: CDC's GRASP team replied ([Flanagan et al., 2021](https://pmc.ncbi.nlm.nih.gov/articles/PMC11611389/)), Rufat et al. answered ([*Validation Must Precede Promotion*](https://www.tandfonline.com/doi/full/10.1080/24694452.2020.1857221)). A live, on-record methodological fight between the index's authors and its critics is a ready-made framing device for a paper and a talk.
**Input data uncertainty**
- Spielman, Folch & Nagle (2014), [Patterns and causes of uncertainty in the American Community Survey](https://pmc.ncbi.nlm.nih.gov/articles/PMC4232960/), *Applied Geography*. Tract-level ACS margins of error average ~75% larger than the 2000 long form, and **uncertainty is systematically higher in low-income and central-city tracts**. This is the load-bearing fact for §4.
- Spielman & Folch (2015), [Reducing uncertainty through data-driven regionalization](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0115626), *PLOS ONE*, for the scale of what is at stake (~$450B/yr in federal allocation) and for the standard remedy you will be arguing is insufficient.
**Policy learning under safety and fairness constraints**
- Ben-Michael, Greiner, Imai & Jiang (2025), [Safe Policy Learning through Extrapolation](https://arxiv.org/abs/2109.11679), *JASA* 120(551):1386–1399. The template. Existing policy is *deterministic*, so there is no overlap and standard policy learning does not apply; they partially identify expected utility and maximize worst-case, yielding a policy with a statistical guarantee that limits the probability of doing worse than the incumbent.
- Jia, Ben-Michael & Imai, [Bayesian Safe Policy Learning with Chance Constrained Optimization](https://arxiv.org/abs/2307.08840). Introduces **ACRisk** — conditional risk computed for covariate-defined subgroups, then averaged. This is the object you want for group-wise safety, and it was developed for a score built by aggregating decision tables, which is structurally what SVI is.
- Viviano & Bradic (2024), [Fair Policy Targeting](https://arxiv.org/abs/2005.12395), *JASA* 119(545):730–743. "First do no harm": restrict to the Pareto set, then choose the fairest element, rather than imposing fairness constraints that can harm everyone. Mixed-integer linear program formulation — directly reusable.
- Athey & Wager (2021), *Policy Learning With Observational Data*, *Econometrica* 89(1):133–161, and Kitagawa & Tetenov (2018), *Who Should Be Treated?*, *Econometrica* 86(2):591–616, for regret bounds over constrained policy classes.
**Transportability and distribution-free inference**
- Bareinboim & Pearl (2016), [Causal inference and the data-fusion problem](https://doi.org/10.1073/pnas.1510507113), *PNAS* 113(27):7345–7352 — selection diagrams, S-admissibility, transport formulas.
- Tibshirani, Barber, Candès & Ramdas (2019), [Conformal Prediction Under Covariate Shift](https://arxiv.org/abs/1904.06019), NeurIPS — weighted conformal, the inferential layer for §6.
**The bridge to AI**
- Jacobs & Wallach (2021), [Measurement and Fairness](https://arxiv.org/abs/1912.05511), FAccT. The canonical statement that fairness harms often *are* construct-operationalization mismatches. Your contribution is the next move they did not make: distinguishing reflective from composite operationalizations and showing the validity evidence differs by type.
- Obermeyer, Powers, Vogeli & Mullainathan (2019), [Dissecting racial bias in an algorithm used to manage the health of populations](https://www.science.org/doi/10.1126/science.aax2342), *Science* 366(6464):447–453. The reference case of a construct (health need) operationalized as a proxy (cost) that dissolves for Black patients.
---
 
## 3. Program architecture
 
Five workpackages. WP1 is the credibility-establishing fast shipment; WP3 is the theoretical centerpiece; WP5 is the return route to your primary target market.
 
```
WP1 (6-8 wks) ──► WP2 (8-10 wks) ──► WP3 (4-6 mo, theory-first) ──► WP4 (parallel, 6 wks)
Decision            Differential          Transported safe            Whose weights?
reliability         prediction            policy learning             (participatory)
     │                    │                       │                        │
     └────────────────────┴───────────┬───────────┴────────────────────────┘
                                      ▼
                          WP5 (6-8 wks) — Position paper:
                          composite vs. reflective in AI evaluation
```
 
---
 
## 4. WP1 — Decision reliability: how much of the ranking is survey noise?
 
**Ship this first.** It is cheap, it requires no outcome data, it survives every objection in your critique because it never posits a latent variable, and it produces one figure a county emergency manager understands in five seconds.
 
**Question.** SVI ranks tracts by percentile and programs fund the top decile or quartile. ACS inputs carry published margins of error. How many tracts change decile under resampling within those MOEs — and is that churn concentrated in the tracts the index is most supposed to protect?
 
**Method.**
1. Pull ACS 5-year variance replicate estimates (not just published MOEs — replicates preserve covariance across variables, which naïve independent-MOE simulation destroys).
2. Monte Carlo: draw $B = 5{,}000$ replicate realizations of the fifteen SVI inputs per tract; recompute the full SVI pipeline (percentile rank each variable → sum within theme → percentile rank theme → sum themes → percentile rank overall) on each draw.
3. Report per tract: posterior probability of landing in the funded set; expected rank displacement; and the **decision-flip rate** — proportion of draws changing the tract's funded/not-funded status at each of several plausible thresholds.
4. Regress flip probability on tract characteristics. The prediction, from Spielman/Folch/Nagle, is that **flip rates are highest in poor and minority tracts** — the exact places where allocation error is least tolerable.
**The finding this is designed to produce.** Not "the index is noisy," which is a shrug, but *"reliability is itself non-invariant across subgroups, and the direction of the non-invariance is regressive."* That is a psychometric statement about differential measurement precision with a direct allocation consequence, and it is the honest analogue of DIF for a composite. As far as I can tell nobody has framed the SVI uncertainty literature this way.
 
**Deliverable.** Short paper plus `svi-churn`, an R/Python package taking any composite specification (variable list, normalization, weights, aggregation) and returning decision-flip probabilities. Tools get adopted; critiques get cited once.
 
**Risk.** Low. Main threat is that the composite-indicator uncertainty/sensitivity literature (OECD Step 7; Tate's sensitivity work) has partially covered rank instability. Differentiate on three axes: variance replicates rather than independent MOE simulation; *decision* flips rather than rank correlation; and the subgroup-conditional reliability framing, which is yours.
 
---
 
## 5. WP2 — Differential prediction, not measurement invariance
 
**Question.** Does the index predict the harm it is meant to proxy equally well, with the same intercept and slope, across the subgroups and regions it sorts?
 
**Framework.** This is the Cleary (1968) differential prediction model from selection psychology, imported wholesale. For outcome $Y$, index $S$, group $G$:
 
$$Y = \beta_0 + \beta_1 S + \beta_2 G + \beta_3 (S \times G) + \varepsilon$$
 
Intercept differences ($\beta_2 \ne 0$) mean the index systematically under- or over-states need for a group at a fixed score. Slope differences ($\beta_3 \ne 0$) mean the score has different meaning-per-unit across groups. Neither requires a latent variable. Both are exactly what "does a fixed score carry the same meaning across subgroups" should mean for a composite.
 
Extend to (a) region as the grouping variable, testing whether a nationally-fit index is differentially predictive urban/rural, which bears directly on transport; (b) theme-level decomposition, following Rufat et al.'s pillar analysis; (c) spatial error structure — tract outcomes are autocorrelated and naïve SEs will be badly optimistic.
 
**Outcome candidates, honestly ranked.** This is the actual bottleneck of the whole program, not the method.
 
| Outcome | Source | Notes |
|---|---|---|
| FEMA Individual Assistance registrations, verified loss | [OpenFEMA](https://www.fema.gov/about/openfema/data-sets) | Public; Rufat et al. established the pipeline post-Sandy. Geography is coarser than tract in places — check before committing. |
| Heat-related ED visits | CDC Environmental Public Health Tracking; state HCUP SEDD | County-level free; tract-level requires state DUA. Timeline risk. |
| Excess mortality, disaster period | CDC WONDER + NCHS | County-level, suppression on small counts. |
| Post-disaster displacement | USPS change-of-address, Census Household Pulse | Underused, tract-adjacent. |
| CDC PLACES health estimates | CDC | **Avoid as outcome.** These are model-based small-area estimates built partly from the same ACS inputs — circularity risk. |
 
**Deliverable.** Paper: *"Differential prediction is the right validity question for allocation composites."* Positions you inside the Rufat/CDC dispute with a framework neither side used.
 
**Risk.** Reviewers in geography will not know the Cleary model and reviewers in psychometrics will not know SVI. Write the bridge explicitly; that translation is itself part of the contribution.
 
---
 
## 6. WP3 — The sharpened idea: transported safe policy learning for allocation indices
 
This is the centerpiece and the thing that is genuinely open. Work it out on paper before touching data.
 
### 6.1 Why "equity-aware optimization when fitting the measurement model" was the right instinct, wrongly located
 
Your original framing put the fairness constraint inside the estimation of a measurement model. But there is no measurement model to constrain — the composite has no parameters with structural meaning. Move the constraint to where the decision is: **optimize the allocation directly, over the class of interpretable index rules, subject to a safety constraint defined relative to the incumbent index.** The policy class *is* the class of composite indices. That is what makes this different from generic policy learning, where the learned rule is a black box that no county council will adopt.
 
### 6.2 Setup
 
Tracts $i = 1, \dots, n$. Observed indicator vector $\hat{X}_i \in \mathbb{R}^p$ (ACS estimates), true values $X_i$, with $\hat{X}_i = X_i + \eta_i$, $\text{Var}(\eta_i)$ **known and heteroskedastic** from the variance replicates — this is unusually good measurement-error information and you should exploit it rather than assume it away.
 
Incumbent policy (CDC SVI, equal weights, unit-weighted theme sums, percentile threshold):
$$\pi_0(\hat{x}) = \mathbb{1}\{\text{rank}(\mathbf{1}'\hat{x}) \ge \tau_0\}$$
 
Policy class — interpretable index rules:
$$\Pi = \Big\{ \pi_{w,\tau}(\hat{x}) = \mathbb{1}\{w'\hat{x} \ge \tau\} : w \in \Delta^{p-1},\ w_j \ge 0,\ \|w\|_0 \le k \Big\}$$
 
The three constraints on $w$ are doing real work. $w \in \Delta^{p-1}$ keeps scores comparable to the incumbent. $w_j \ge 0$ is the **monotonicity constraint that directly repairs the pathology Spielman et al. documented** — under a sign-constrained index, an increase in unemployment can never decrease measured vulnerability, which is not true of PCA-derived SoVI. $\|w\|_0 \le k$ keeps the index explainable to a city council. Each is defensible on substantive grounds, not just regularization.
 
### 6.3 The optimization
 
Let $Y_i(a)$ be the potential outcome under allocation $a \in \{0,1\}$, welfare $V(\pi) = \mathbb{E}[Y(\pi(\hat{X}))]$, and $V_g(\pi)$ the same restricted to protected group $g \in \mathcal{G}$ (defined by tract racial composition, rurality, tribal land status, language isolation — whatever the sponsoring agency's equity framework names).
 
$$
\begin{aligned}
\max_{\pi \in \Pi} \quad & \hat{V}(\pi) \\
\text{s.t.} \quad & \textstyle\sum_i \pi(\hat{X}_i) \le B && \text{(capacity)} \\
& \Pr\big( V_g(\pi) < V_g(\pi_0) - \epsilon \big) \le \alpha \quad \forall g \in \mathcal{G} && \text{(group-wise safety)}
\end{aligned}
$$
 
The safety constraint is the Jia–Ben-Michael–Imai ACRisk formulation with the incumbent as reference. In plain terms: **provably no worse than the current index for any protected group, at 95% confidence, and better on average.** That framing is the entire political case. No agency adopts a new index on a promise of average improvement. "Cannot make anyone worse off, with a stated confidence level" is adoptable, and it is the actual content of "first do no harm" as Viviano and Bradic formalize it.
 
### 6.4 Three identification problems, in increasing order of novelty
 
**(i) No overlap — the incumbent is deterministic.** Every tract's treatment is a known function of $\hat{X}$; there is no propensity variation to exploit. This is precisely the Ben-Michael et al. problem and their partial-identification-plus-maximin-regret machinery transfers. Where a program has a *sharp eligibility threshold* on ACS variables — New Markets Tax Credit low-income community designation, LIHTC Qualified Census Tracts, CDBG-DR "most impacted and distressed" designations — you get an RD for local identification at the boundary, and there is existing work on [safe policy learning under regression discontinuity](https://arxiv.org/abs/2208.13323) to build on. **Recommend anchoring the empirical work on one such threshold program.** It converts an untestable extrapolation into a design.
 
**(ii) Measurement error in the running variable of a deterministic rule.** The policy must be implementable on *observed* ACS estimates, so you optimize $\pi(\hat{X})$; but welfare is a function of true need $X$. The gap is not a nuisance — the error variance is systematically larger in poor and minority tracts, so the *effective allocation rule differs by subgroup even when the nominal rule is identical*. Formally, the realized assignment probability for a tract with true score $s$ is $\Pr(w'\hat{X} \ge \tau \mid w'X = s) = \Phi\big((s - \tau)/\sigma_g(s)\big)$, and $\sigma_g$ varies by group. Two contributions here:
- A characterization of how differential reliability distorts a threshold allocation, with the direction and magnitude signed. This is DIF's true analogue for composites and it is a *statement about decisions*, not scores.
- An error-aware objective: choose $w$ to maximize welfare *net of* the misallocation induced by measurement error, which will systematically down-weight high-MOE indicators. That is a novel and substantively motivated reason to weight indicators unequally, and it will produce weights an agency can defend.
I have not seen this treated anywhere. It is the most distinctively psychometric contribution in the program and it exists only because you refused the reflective framing.
 
**(iii) Transport of the safety guarantee.** The novel theory, and the thing worth spending months on.
 
> A policy $\hat\pi$ carries the guarantee $\Pr(V_g(\hat\pi) \ge V_g(\pi_0) - \epsilon) \ge 1 - \alpha$ *in the source population* $S = 0$. Under what conditions on the selection diagram does a guarantee of the same form hold in target population $S = 1$, and at what level $\alpha^*$?
 
Decompose into the two failure modes, because they have different remedies:
 
- **Covariate shift only** (no $S$-node into $Y$; the conditional outcome model transports). Then $V_g^{(1)}(\pi)$ is identified by reweighting on the minimal S-admissible set $Z$, and the guarantee transports with a degraded level $\alpha^*$ that depends on the effective sample size after weighting. Deliverable: a closed-form or bootstrap-calibrated map from estimated weight variability to $\alpha^*$.
- **Outcome-model shift** ($S \to Y$). The guarantee does not transport at all and the honest output is a bound. State the bound and the assumptions that would restore point identification.
- **Positivity failure.** The target contains covariate regions the source never sampled — a coastal-hazard-calibrated index adopted by an inland wildfire county. The correct answer is a partial identification region and an explicit **"the certificate is vacuous here"** map. Making that limitation the headline feature rather than a buried caveat is what separates audit-grade work from a blog post, and it is the same discipline your LLM deployment-gap idea rests on.
**Deliverable: a transport-adjusted safety certificate.** For a given target jurisdiction: the achievable guarantee level $\alpha^*$, the reweighted welfare estimate, and the tract set where positivity fails. This is a legible artifact an agency, a foundation program officer, or a conformity assessor can act on.
 
### 6.5 Inference
 
Weighted conformal (Tibshirani et al. 2019) supplies distribution-free finite-sample coverage under estimated shift weights, giving a group-conditional upper bound on harm rate without distributional assumptions. Consistent with the advice in your project notes: keep conformal as machinery, lead with transportability. It is a strong second paragraph and a weak first sentence.
 
---
 
## 7. WP4 — Whose construct? Participatory weight elicitation
 
The weights *are* the construct definition. So elicit them three ways and compare the induced allocations.
 
1. **Equal weights** — status quo, encoding the unstated claim that all fifteen indicators contribute identically.
2. **Outcome-optimal weights** — from WP3, encoding "vulnerability is whatever predicts harm."
3. **Participatory weights** — elicited from affected residents and frontline service providers via conjoint analysis or constrained budget allocation, encoding "vulnerability is what the affected population says it is."
Report the pairwise overlap of the funded set (Jaccard on the top decile), the rank correlation, and which indicator families drive the divergence.
 
**If the three allocations disagree substantially, the disagreement is the result** — it makes visible a normative choice currently hidden inside an unweighted sum, which is exactly the "according to the people they affect" criterion you raised, operationalized. If they agree, that is a robustness finding worth having and it costs you six weeks.
 
**Feasibility caveat.** A real participatory elicitation needs IRB, recruitment, and compensation. A defensible cheaper version: elicit from a panel of practitioners (emergency managers, community health workers, housing counselors) rather than residents, and label it as such. Do not call practitioner weights participatory.
 
---
 
## 8. WP5 — The return route: composite vs. reflective in AI evaluation
 
This is why the detour pays even if the vulnerability papers never place.
 
**The claim.** Most aggregate AI safety and capability scores are composites, not reflective measures. A HELM-style mean over subscores, a weighted refusal rate, a benchmark-suite average — these are defined by their aggregation rule. There is no latent "safety" trait generating item responses. The current wave of "apply psychometrics to evals" work is committing exactly the category error you caught in the index literature, but with more confidence, because the psychometric vocabulary makes it feel rigorous. Fitting an IRT model to a benchmark aggregate presumes the reflective structure that is at issue.
 
**The paper.** Three moves:
 
1. **A diagnostic.** When is a benchmark aggregate reflective and when is it a composite? Concrete criteria: is there a substantive theory generating item responses from a common cause; would dropping an item change the construct's meaning (composite) or merely its precision (reflective); do the items need conceptual unity. Apply it to a handful of named, widely-cited safety benchmarks.
2. **The right validity evidence for composites.** Differential prediction (does the aggregate predict downstream harm equally across user subgroups); decision stability (does the release/gate decision flip under resampling of items, judges, prompts — the eval analogue of WP1's decision-flip rate); weight transparency (whose normative weights are encoded in the aggregation, and were they defended).
3. **The policy reframe.** A safety score that gates a deployment decision is a scoring rule inducing a policy. So the WP3 apparatus applies to the *release decision*: is the new model's deployment policy provably no worse than the incumbent model's, for every user subgroup, and does that guarantee transport from the evaluation population to the deployment population?
Move 3 is where your two documents converge. It is the same theorem, and it makes the vulnerability work and the LLM work one program rather than two.
 
**Venue.** NeurIPS position track, FAccT, or an EvalEval-style workshop. This is also the paper that reads best to an AI safety hiring committee, because it arrives at their literature with a correction they are not positioned to make.
 
---
 
## 9. Sequencing and timeline
 
| Months | Workpackage | Output |
|---|---|---|
| 0–2 | WP1 | Paper + `svi-churn` package. Establishes credibility, needs no outcome data. |
| 1–2 | Literature + data reconnaissance | Confirm outcome data feasibility *before* committing to WP2. Identify the threshold program for WP3. |
| 2–5 | WP2 | Differential prediction paper. |
| 3–9 | WP3 (theory first, then empirics) | Transported safe policy learning. The flagship. |
| 5–7 | WP4 (parallel) | Weight-elicitation comparison; folds into WP3 as a section or stands alone. |
| 8–10 | WP5 | Position paper. Written last so it can cite your own empirical work. |
 
**Gate at month 2.** If tract-linked outcome data proves infeasible within the timeline, WP2 and the empirical half of WP3 collapse. In that case pivot to: WP1 + WP3-as-theory-paper + WP5, which is still a coherent and publishable program and still demonstrates every skill you want demonstrated. Decide this deliberately at month 2 rather than discovering it at month 6.
 
---
 
## 10. Honest risk register
 
| Risk | Severity | Mitigation |
|---|---|---|
| **Tract-linked outcome data unavailable or too coarse** | High — kills WP2 and half of WP3 | Month-2 gate. Start with OpenFEMA IA where the pipeline is established. Have the theory-only fallback ready. |
| **No credible intervention with identification** | High — without one this is prediction, not policy learning | Anchor on a sharp-threshold program (NMTC, QCT, CDBG-DR MID) rather than SVI-as-such. Or state plainly that v1 is a targeting problem with a welfare functional, and reserve causal claims. Do not blur this. |
| Positivity violations dominate the transport analysis | Medium | This is the feature, not the bug — but only if you say so up front and report bounds rather than extrapolating. |
| Composite-indicator literature has already done the sensitivity analysis | Medium | Read OECD Step 7 and Tate's sensitivity work first. Differentiate on decision flips, variance replicates, and subgroup-conditional reliability. |
| Reviewers reject the composite framing as "just PCA critique" | Medium | Lead with Bollen & Bauldry's taxonomy explicitly. The claim is not that SVI is a bad reflective measure; it is that it is not a reflective measure and the field has been asking the wrong questions. |
| MILP does not scale to $n \approx 85{,}000$ tracts | Low–Medium | Viviano & Bradic show LP sequences for discrete covariates; percentile-ranked inputs are effectively discrete. Prototype at state scale. |
| Community backlash for "optimizing" who gets help | Real, and reputational | WP4 is partly the answer. Frame throughout as *auditing and constraining* the existing rule, never as replacing human judgment. Publish the safety constraint before the optimization results. |
 
---
 
## 11. Venues and portfolio positioning
 
**Methods audiences.** NCME and IMPS (measurement invariance and differential prediction people will immediately grasp WP1 and WP2 and be startled by the application); JSM; *Psychological Methods* or *Multivariate Behavioral Research* for the composite-validation framework.
 
**Policy and applied audiences.** APPAM (where think tanks recruit); *Journal of Policy Analysis and Management*; *Natural Hazards* or *Annals of the AAG* for the index-specific papers, which puts you directly into the Rufat/CDC exchange.
 
**CS and AI audiences.** EAAMO — the single best fit for public-sector allocation work and a smaller, more attentive room than FAccT; FAccT and AIES; NeurIPS Datasets & Benchmarks or position track for WP5.
 
**Employer legibility.**
- *AI safety and wellness team*: WP5 is the artifact, WP3 is the depth behind it.
- *Data equity and fairness team*: WP2 and WP4 are directly on-mission; WP1 is the demo.
- *Public-sector or think tank (Urban, Mathematica, Chapin Hall, RAND, MDRC)*: WP1 and WP3 are the whole job description.
The dual positioning holds because the machinery is framing-agnostic. Build WP3 so that the case study can be swapped — vulnerability index today, LLM release gate tomorrow — without rebuilding the method. That hedge costs nothing.
 
---
 
## 12. What to do this week
 
1. Pull the ACS 5-year variance replicate tables for one state and reproduce the CDC SVI pipeline end to end. You cannot critique a construction you have not built.
2. Read Spielman et al. (2020) and the Rufat–CDC exchange in full, in that order. Note where each side's argument would be settled by a differential-prediction analysis neither ran.
3. Read Ben-Michael et al. (2025) §3–4 and Jia, Ben-Michael & Imai's ACRisk definition. Write down, in one page, what changes when the deterministic incumbent policy's running variable is measured with known heteroskedastic error. That page is the seed of the WP3 theory contribution.
4. Spend one afternoon checking OpenFEMA's actual geographic resolution. The month-2 gate is really this question, and finding the answer early is worth more than any other single hour in this plan.
---
 
## Sources
 
**Measurement theory**
- Bollen, K. A., & Bauldry, S. (2011). Three Cs in measurement models: Causal indicators, composite indicators, and covariates. *Psychological Methods*, 16(3), 265–284. https://doi.org/10.1037/a0024448 · [Open access](https://pmc.ncbi.nlm.nih.gov/articles/PMC3889475/)
- Jacobs, A. Z., & Wallach, H. (2021). Measurement and Fairness. *FAccT '21*, 375–385. https://doi.org/10.1145/3442188.3445901 · [arXiv](https://arxiv.org/abs/1912.05511)
**Composite indicators**
- OECD/EU/JRC (2008). *Handbook on Constructing Composite Indicators: Methodology and User Guide*. https://doi.org/10.1787/9789264043466-en · [PDF](https://knowledge4policy.ec.europa.eu/sites/default/files/jrc47008_handbook_final.pdf)
**Social vulnerability indices**
- Spielman, S. E., Tuccillo, J., Folch, D. C., Schweikert, A., Davies, R., Wood, N., & Tate, E. (2020). Evaluating social vulnerability indicators. *Natural Hazards*, 100(1), 417–436. https://doi.org/10.1007/s11069-019-03820-z
- Rufat, S., Tate, E., Emrich, C. T., & Antolini, F. (2019). How Valid Are Social Vulnerability Models? *Annals of the AAG*, 109(4), 1131–1153. https://doi.org/10.1080/24694452.2018.1535887 · [PDF](https://shs.hal.science/halshs-02485376/file/Rufat_2019_How_Valid_Are_Social_Vulnerability_Models.pdf)
- Flanagan, B., Hallisey, E., Sharpe, J. D., Mertzlufft, C. E., & Grossman, M. (2021). On the Validity of Validation. *Annals of the AAG*, 111(4). https://doi.org/10.1080/24694452.2020.1857220 · [Open access](https://pmc.ncbi.nlm.nih.gov/articles/PMC11611389/)
- Rufat, S., Tate, E., Emrich, C. T., & Antolini, F. (2021). Answer to the CDC: Validation Must Precede Promotion. *Annals of the AAG*, 111(4). https://doi.org/10.1080/24694452.2020.1857221
- CDC/ATSDR SVI documentation and publication list: https://www.atsdr.cdc.gov/place-health/php/svi/
**ACS uncertainty**
- Spielman, S. E., Folch, D., & Nagle, N. (2014). Patterns and causes of uncertainty in the American Community Survey. *Applied Geography*, 46, 147–157. https://doi.org/10.1016/j.apgeog.2013.11.002 · [Open access](https://pmc.ncbi.nlm.nih.gov/articles/PMC4232960/)
- Spielman, S. E., & Folch, D. C. (2015). Reducing Uncertainty in the ACS through Data-Driven Regionalization. *PLOS ONE*, 10(2). https://doi.org/10.1371/journal.pone.0115626
**Policy learning**
- Ben-Michael, E., Greiner, D. J., Imai, K., & Jiang, Z. (2025). Safe Policy Learning through Extrapolation. *JASA*, 120(551), 1386–1399. https://doi.org/10.1080/01621459.2025.2489135 · [arXiv](https://arxiv.org/abs/2109.11679)
- Jia, Z., Ben-Michael, E., & Imai, K. Bayesian Safe Policy Learning with Chance Constrained Optimization. https://arxiv.org/abs/2307.08840
- Viviano, D., & Bradic, J. (2024). Fair Policy Targeting. *JASA*, 119(545), 730–743. https://doi.org/10.1080/01621459.2022.2142591 · [arXiv](https://arxiv.org/abs/2005.12395)
- Safe Policy Learning under Regression Discontinuity. https://arxiv.org/abs/2208.13323
**Transportability and inference**
- Bareinboim, E., & Pearl, J. (2016). Causal inference and the data-fusion problem. *PNAS*, 113(27), 7345–7352. https://doi.org/10.1073/pnas.1510507113
- Tibshirani, R. J., Barber, R. F., Candès, E. J., & Ramdas, A. (2019). Conformal Prediction Under Covariate Shift. *NeurIPS*. https://arxiv.org/abs/1904.06019
**Reference case**
- Obermeyer, Z., Powers, B., Vogeli, C., & Mullainathan, S. (2019). Dissecting racial bias in an algorithm used to manage the health of populations. *Science*, 366(6464), 447–453. https://doi.org/10.1126/science.aax2342
