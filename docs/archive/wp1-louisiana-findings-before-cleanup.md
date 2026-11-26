hurn` package the program calls for.
 
**Data.** ACS 2018–2022 5-Year Variance Replicate Tables, summary level 140, state 22: `B01001 B01003 B03002 B11012 B15002 B16005 B18101 B23025 B25003 B25014 B25024 B25044 B25106 B26001 B27001 C17002`, from `https://www2.census.gov/programs-surveys/acs/replicate_estimates/2022/data/5-year/140/`. Validation target: CDC/ATSDR SVI 2022, Louisiana, census tracts.
 
---
 
## Next
 
0. **Check the sixteen line-number mappings for the reason stated, not merely that they reproduce.** Neither the original work nor the audit did this. `01_build_estimates.R` hard-codes ACS table `ORDER` values for every variable; a compensating pair of errors in an alternating sequence — `B27001`'s `seq(5,29,3)`/`seq(33,57,3)` no-insurance lines, `B18101`'s `seq(4,19,3)`/`seq(23,38,3)` disability lines — would reproduce and still be wrong. This is the single most likely remaining silent error in the project and it is an hour's work against the table shells.
1. **Repeat on a second state with different geography** — the rank-position story predicts the inverted U is universal, and the flip rates should scale with the number of tracts. A state with far fewer tracts (and so coarser rank spacing) is the sharper test. This is cheap now; the code is state-agnostic.
2. **Write the rank-scale measurement-error page** (§6.4(ii), restated). That is the seed of the WP3 theory contribution and it should be written before any optimisation code exists.
3. **Check OpenFEMA's geographic resolution.** Still the highest-value hour in the plan, and still unspent.
