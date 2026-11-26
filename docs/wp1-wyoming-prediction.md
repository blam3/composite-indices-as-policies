# WP1 Wyoming replication — prediction, written before the chain ran

Committed on branch `wp1/wyoming-replication` **before** any Wyoming VRT file
was fetched or any pipeline script was run on Wyoming. The only Wyoming data
seen at this point was the published CDC/ATSDR SVI 2022 Wyoming file, inspected
for tract count and missingness only. Louisiana figures in brackets are from
`analysis/louisiana/results/EXPECTED-RESULTS.json`.

## What the CDC file showed

160 tracts, 23 counties, no `99xx` water-only tracts. One tract has zero
population and is `-999` in every field; no other cell is missing. 159 tracts
carry a valid `RPL_THEMES`. Louisiana had per-variable partial missingness
(12–14 tracts per field), Wyoming has none, so Wyoming exercises the
zero-denominator exclusion convention only trivially.

## Mechanism argument

To first order, rank SD in percentile units is a tract's sampling error
relative to the cross-tract spread of the inputs; it does not depend on n.
Wyoming tracts are similar in size to Louisiana's (~3,600 vs ~3,350
people), so input SEs should be similar. Where Wyoming should differ is a
narrower spread and large near-zero tie clumps on MINRTY, LIMENG and GROUPQ,
which should push rank noise up modestly. Percentile spacing is 1/158 ≈ 0.006
vs 0.0007 — still small next to an SD of ~0.09. **Prediction: a modest
increase driven by tie clumps and narrower spread, not by n.**

## Numbers

| Quantity | Prediction | Louisiana |
|---|---|---|
| Gate values / missingness cells | 6,678/6,678 and 6,720/6,720, pass (~75% confident) | 57,368 / 57,918 |
| VRT tracts / dropped | 160 / 0 | 1,388 / 9 |
| Median rank SD (replicate) | 0.10 (0.085–0.125) | 0.0898 |
| Median 90% interval width | 32 pts (27–40) | 29 |
| Share >20-pt interval | ~82% | 80.8% |
| Share >40-pt interval | ~20% | 14.9% |
| Funded at decile / quintile / quartile | 16 / 32 / 40 (unless cutoff ties) | 137 / 273 / 342 |
| Leaver rate, decile | 28% (20–38%), ~4.5 of 16 | 24.9% |
| Leaver rate, quintile / quartile | ~20% / ~17% | 18.8% / 15.9% |
| Ordering decile > quintile > quartile | holds (high confidence) | holds |
| within_tract vs replicate | ≈ equal (cross-tract null, high confidence) | 0.0897 vs 0.0898 |
| no_cov | matches median, understates >40-pt tail by ~1/3 | 5.0% vs 14.9% |
| minclamp | slightly above replicate | 0.0910 |
| 80-replicate check | ratio ~1.0, correlation ~0.9 | 1.006, 0.93 |
| SE ratio Q5/Q1, POV150 / UNEMP / NOHSDP | each > 1.5 | 2.22 / 2.39 / 2.19 |
| SE ratio Q5/Q1, MINRTY | 1.1–1.6 (not flat; Wind River tracts sit mid-range) | 0.85 |
| SE ratio Q5/Q1, GROUPQ | unpredictable (dorms, prisons) | 3.09 |
| R² of rank position on rank SD | > 0.59, point 0.65 | 0.59 |
| Partial cor(imprecision, rank SD \| position) | < 0.485, point 0.35 | 0.485 |
| Equalisation decile-profile correlation | ≥ 0.85 | 0.93 |
| Top-decile noise, actual / equalised | 1.4× (1.2–1.8) | 1.57× |
| Top-decile leaver drop under equalisation | ~5 points | 24.9% → 20.2% |
| Flip GLM poverty OR | clustered SE ~3× Louisiana's; sign not a test | 0.88 |

"Rank-position mechanism bites harder" is operationalised as the R² and
partial-correlation rows above jointly moving in the stated direction.
Confidence in that direction: ~55%; the mechanism argument says n should not
matter to first order, so a null would not be a surprise.

## Not testable by the chain

STATUS §6 LLM task 3 also predicts that the smooth normal approximation to
the flip probability, Φ((r−τ)/ς(r)), should visibly fail near tie clumps. No
script in the chain computes that approximation, so this half of the
pre-registered prediction is recorded as **untested**.
