# WP1 — verification of the sixteen ACS line-number mappings

`Written: 2026-08-23` · `Branch: wp1/verify-line-numbers` ·
`Script: analysis/louisiana/code/exploratory/verify_line_numbers.R`

Closes `docs/STATUS.md` §6 LLM task 1. Discharges the standing warning in
`docs/wp1-audit-response.md` that "neither the audit nor the original work has
checked the line-number mappings for the reason stated, only that they
reproduce."

## What was checked, and what was deliberately not used as evidence

The claim under test is **not** "the pipeline reproduces CDC's published
Louisiana file". That was already established (57,368/57,368 values,
57,918/57,918 missingness cells) and it is not evidence about the mappings: a
compensating pair of offsets in an alternating line sequence would reproduce
and still be wrong.

The claim under test is: **each `EP_` variable's line set is the set of cells
the published ACS table shell says carries that substantive quantity.**

Method, in order, with the order load-bearing:

1. `scratch/step1-intent.md` — the sixteen variables and the numerator /
   denominator quantity each is supposed to represent, from the CDC/ATSDR
   SVI 2022 documentation data dictionary. Written before opening the code.
2. `scratch/step2-derived.md` — line numbers re-derived from the published
   shells, one justification per variable. Written before opening the code.
3. Only then `analysis/louisiana/code/01_build_estimates.R` was opened and
   diffed against step 2.

`scratch/` is git-ignored; both files are reproduced in substance below.

## The complication CDC's documentation introduces

CDC 2022 defines most `EP_` variables against **Data Profile (`DP`) and
Subject (`S`)** tables, not detailed `B`/`C` tables — its "SVI 2022 Updates"
section says the remapping was deliberate. But **ACS Variance Replicate Tables
exist only for detailed `B`/`C` tables**, so this pipeline must reconstruct
each `DP`/`S` percentage from the detailed table carrying the same universe and
the same cells. The object verified is therefore a three-step chain:

    EP_ variable  ->  CDC's DP/S field(s)  ->  equivalent detailed-table cells

Step 1 fixes the first arrow from CDC's dictionary; step 2 fixes the second
from the shells.

## Source cited for every row

All sixteen shells come from the single published 2018–2022 5-year shell file
(`Table ID|Line|Indent|Unique ID|Label|Title|Universe|Type`):

**`https://www2.census.gov/programs-surveys/acs/summary_file/2022/table-based-SF/documentation/ACS20225YR_Table_Shells.txt`**

fetched 2026-08-23, `last-modified: 2023-11-30`. Referred to below as
**[SHELL]**; the per-table extract is
`awk -F'|' '$1=="B27001" {print $2, $3, $5}'`.

**The shell `Line` and the VRT `ORDER` column are the same number.** Verified,
not assumed, three ways: (a) for all sixteen tables the shell's line count
equals the VRT's `ORDER` count exactly; (b) each VRT row carries its own
`TITLE`, and at every line the code indexes that `TITLE` is the shell's label;
(c) the shell's indent tree is arithmetically true of the VRT estimates — every
parent row equals the sum of its immediate children, for all 1,388 tracts, in
all fourteen tables that have a hierarchy (the other two, `B01003` and
`B26001`, are single-line tables).

Check (c) matters more than it looks. Several leaf labels are ambiguous on
their own: `B25106` has eight rows labelled `30 percent or more`, and the
income bracket lives only in the parent header. Check (c) turns the shell's
indentation into a fact about the numbers, which is what actually pins line 6
to the `Less than $20,000` bracket rather than to some other one.

## Per-variable result

`NUM` = numerator lines, `DEN` = denominator. "Derived" is step 2, written
blind; "code" is `01_build_estimates.R`.

| Variable | Table | Shell | Derived | Code | Agree? | Note |
|---|---|---|---|---|---|---|
| `EP_POV150` | `C17002` | [SHELL] | NUM 2,3,4,5 · DEN 1 | same | **yes** | Lines 2–5 are every ratio bracket strictly below 1.50; line 6 is `1.50 to 1.84`. Universe on line 1 is "Population for whom poverty status is determined" = CDC's `S1701_C01_001`. |
| `EP_UNEMP` | `B23025` | [SHELL] | NUM 5 · DEN **3** | same | **yes** | `Unemployed`(5) nests under `Civilian labor force:`(3), which nests under `In labor force:`(2). Denominator 3 is the only correct one — line 1 is population 16+, line 2 adds `Armed Forces`(6). This is the unemployment *rate*, CDC's `DP03_0009PE`. |
| `EP_HBURD` | `B25106` | [SHELL] | NUM 6,10,14,18,28,32,36,40 · DEN 1 | NUM same · DEN `B25003` 1 | **yes** ¹ | `30 percent or more` at bracket+3: owner brackets 3,7,11,15 → 6,10,14,18; renter block opens at 24, brackets 25,29,33,37 → 28,32,36,40. Excludes `$75,000 or more` (19, 41), `Zero or negative income` (23, 45), `No cash rent` (46). 8 rows = 4 brackets × 2 tenures, matching CDC's four non-tenure-split `S2503_C01_0{28,32,36,40}`. |
| `EP_NOHSDP` | `B15002` | [SHELL] | NUM 3–10, 20–27 · DEN 1 | same | **yes** | Male `No schooling completed`(3) through `12th grade, no diploma`(10); 11 is `High school graduate`. Female header is **19**, so the female run is +17, not +18. |
| `EP_UNINSUR` | `B27001` | [SHELL] | NUM 5,8,…,29 and 33,36,…,57 · DEN 1 | `seq(5,29,3)`, `seq(33,57,3)` · DEN 1 | **yes** | Nine 3-row age blocks per sex (`<age>:`, `With…`, `No health insurance coverage`). Male groups open at 3 → 5+3k, k=0..8. Female header is **30**; groups open at 31 → 33+3k. All ages, both sexes. See the alternating-sequence section. |
| `EP_AGE65` | `B01001` | [SHELL] | NUM 20–25, 44–49 · DEN 1 | NUM same · DEN `B01003` 1 | **yes** ¹ | Male 65+ is `65 and 66`(20) … `85 and over`(25); line 19 is `62 to 64`. Female offset +24. |
| `EP_AGE17` | `B01001` | [SHELL] | NUM 3–6, 27–30 · DEN 1 | NUM same · DEN `B01003` 1 | **yes** ¹ | Male under-18 is `Under 5`(3) … `15 to 17`(6); line 7 is `18 and 19 years`. Female +24. |
| `EP_DISABL` | `B18101` | [SHELL] | NUM 4,7,…,19 and 23,26,…,38 · DEN 1 | `seq(4,19,3)`, `seq(23,38,3)` · DEN 1 | **yes** | Six 3-row age blocks per sex (`<age>:`, `With a disability`, `No disability`). Male groups open at 3 → 4+3k, k=0..5. Female header is **21** (male occupies 2–20); groups open at 22 → 23+3k. The female offset here is **+19**, not the +28 pattern `B27001` uses — the two tables have different block counts, and getting one from the other by analogy would be wrong. See the alternating-sequence section. |
| `EP_SNGPNT` | `B11012` | [SHELL] | NUM 10, 15 · DEN 1 | NUM same (as two components) · DEN `B25003` 1 | **yes** ¹ | 10 = `Female householder, no spouse or partner present:` → `With children of the householder under 18 years`; 15 = male equivalent. Excludes `Living alone` (9, 14), `With relatives, no children…` (11, 16), `With only nonrelatives present` (12, 17). Split into two components because CDC rounds `DP02_0007PE` and `DP02_0011PE` separately before summing. |
| `EP_LIMENG` | `B16005` | [SHELL] | NUM 7,8,12,13,17,18,22,23,29,30,34,35,39,40,44,45 · DEN 1 | same | **yes** | Four language groups per nativity block, each a 5-row block; "less than well" = the last two rows of each. Native language headers 4,9,14,19; foreign-born block opens at **24** with `Speak only English` at 25 and language headers 26,31,36,41. Derived from the shell independently; identical to the sixteen cells CDC's dictionary names. |
| `EP_MINRTY` | `B03002` | [SHELL] | NUM line 1 − line 3 · DEN 1 | NUM same · DEN `B01003` 1 | **yes** ¹ | Line 3 is `Not Hispanic or Latino: White alone`. CDC's `E_MINRTY = DP05_0001 − DP05_0079` is total minus White-alone-not-Hispanic, so 1 − 3 is the equivalent. Summing the complement categories is algebraically identical; CDC says explicitly it subtracts, for a smaller MOE. |
| `EP_MUNIT` | `B25024` | [SHELL] | NUM 7,8,9 · DEN 1 | NUM 7 and 8:9 (two components) · DEN 1 | **yes** | `10 to 19`(7), `20 to 49`(8), `50 or more`(9); line 6 is `5 to 9`. The split is correct and load-bearing: it is exactly CDC's `DP04_0012` (10–19) and `DP04_0013` (20 or more), each rounded to 0.1 before summing. Denominator line 1, universe **Housing units** — not occupied — = `DP04_0001`. |
| `EP_MOBILE` | `B25024` | [SHELL] | NUM 10 · DEN 1 | same | **yes** | `Mobile home`(10); line 11 `Boat, RV, van, etc.` is excluded, matching `DP04_0014`. |
| `EP_CROWD` | `B25014` | [SHELL] | NUM 5,6,7,11,12,13 · DEN 1 | NUM c(5,11) and c(6,7,12,13) (two components) · DEN 1 | **yes** | More than 1.00 occupants per room, owner (5,6,7) and renter (11,12,13); line 4 is `0.51 to 1.00`. The split matches CDC's `DP04_0078` (1.01–1.50) and `DP04_0079` (1.51 or more), so three B-table rows per tenure collapse into two DP rows — and the code splits on exactly that seam. |
| `EP_NOVEH` | `B25044` | [SHELL] | NUM 3, 10 · DEN 1 | NUM same · DEN `B25003` 1 | **yes** ¹ | `No vehicle available` under owner (3) and renter (10). |
| `EP_GROUPQ` | `B26001` | [SHELL] | NUM 1 · DEN `B01003` 1 | same | **yes** | `B26001` is a one-line table, CDC's `B26001_001E`. Denominator is `E_TOTPOP`. |

**Sixteen of sixteen numerator line sets agree exactly with the blind
derivation. No line-number error was found.**

### ¹ The one class of difference, and why it is not a discrepancy

Six variables take their denominator from a **different table** than the one my
derivation named, always a same-universe cell:

| Variable | Derived denominator | Code denominator |
|---|---|---|
| `EP_HBURD` | `B25106` line 1 | `B25003` line 1 (`HH`) |
| `EP_SNGPNT` | `B11012` line 1 | `B25003` line 1 (`HH`) |
| `EP_NOVEH` | `B25044` line 1 | `B25003` line 1 (`HH`) |
| `EP_AGE65`, `EP_AGE17` | `B01001` line 1 | `B01003` line 1 (`TOTPOP`) |
| `EP_MINRTY` | `B03002` line 1 | `B01003` line 1 (`TOTPOP`) |

This is only defensible if the cells are numerically identical — and not just
in the point estimate, because the whole WP1 result runs on the eighty
replicates. Checked rather than argued:

```
B01003 L1 == B01001 L1   1,388 tracts x 81 slices,  0 differing cells
B01003 L1 == B03002 L1   1,388 tracts x 81 slices,  0 differing cells
B25003 L1 == B25106 L1   1,388 tracts x 81 slices,  0 differing cells
B25003 L1 == B25044 L1   1,388 tracts x 81 slices,  0 differing cells
B25003 L1 == B25014 L1   1,388 tracts x 81 slices,  0 differing cells
B25003 L1 == B11012 L1   1,388 tracts x 81 slices,  0 differing cells
```

Bit-identical in the point estimate and in every replicate. So the
substitution changes nothing, including the covariance structure the
simulation depends on. Recorded as a note, not a finding.

Also worth stating plainly: the code's denominator choices track **CDC's**
universes, which is the thing that matters. `EP_HBURD` over occupied housing
units is `S2503_C01_001`; `EP_SNGPNT` over households is `E_HH = DP02_0001`;
`EP_NOVEH` over occupied housing units is the `DP04_0058PE` base. Households
and occupied housing units are the same count by ACS definition, which is why
the identity above holds.

## The two alternating sequences — the compensating-error check

This is the reason the task exists. The worry is structural and correct in
form: in a 3-row cycle an offset moves *every* term of a sequence at once, and
if two such errors cancel, the total is unchanged and the pipeline still
reproduces.

**They cannot cancel here, and the reason is the sign structure.** In both
tables each 3-row cycle is (`<group>:` subtotal, category A, category B) with
A + B = subtotal, and both halves of the sequence enter the numerator
**additively, with the same sign**. There is no subtraction anywhere in either
mapping. So shifting a half never removes a contribution — it replaces each
term with a strictly different, and here strictly larger, one. The numerator
moves in one direction only, and a second offset cannot bring it back.

The identity that forecloses it, confirmed numerically on the Louisiana file:

```
B27001:  sum(With health insurance) + sum(No health insurance) = line 1 total = 4,543,264
B18101:  sum(With a disability)     + sum(No disability)       = line 1 total = 4,543,264
```

Because the two categories partition the total, shifting *both* halves by −1
turns "the uninsured" into "the insured" — the complement, not a rounding
wobble.

Louisiana state totals under the correct mapping and under every single-step
offset, from `verify_line_numbers.R`:

**`B27001` / `EP_UNINSUR`**, denominator line 1 = 4,543,264

| Line set | Numerator | Implied EP | × correct |
|---|---|---|---|
| **correct** 5–29 / 33–57 | 365,793 | **8.05%** | 1.000 |
| male −1 (4–28 / 33–57) | 2,133,134 | 46.95% | 5.832 |
| female −1 (5–29 / 32–56) | 2,410,130 | 53.05% | 6.589 |
| both −1 (4–28 / 32–56) | 4,177,471 | 91.95% | 11.420 |
| male +1 (6–30 / 33–57) | 4,515,362 | 99.39% | 12.344 |

**`B18101` / `EP_DISABL`**, denominator line 1 = 4,543,264

| Line set | Numerator | Implied EP | × correct |
|---|---|---|---|
| **correct** 4–19 / 23–38 | 717,912 | **15.80%** | 1.000 |
| male −1 (3–18 / 23–38) | 2,573,441 | 56.64% | 3.585 |
| female −1 (4–19 / 22–37) | 2,687,735 | 59.16% | 3.744 |
| both −1 (3–18 / 22–37) | 4,543,264 | 100.00% | 6.328 |
| female +1 (4–19 / 24–39) | 2,313,799 | 50.93% | 3.223 |

**Answer to the question as posed: no. An off-by-one in either half — or in
both — changes the reproduced total, by a factor of at least 3.2. The smallest
achievable perturbation is not small.** The "both −1" row for `B18101` is the
clearest case: it lands on exactly 100.00%, because summing all twelve
age-group subtotals reconstructs the table total.

Two further remarks, since the deliverable is about the *reason*, not the
answer:

- **The correct values are also substantively right.** Louisiana 2022 at
  8.05% uninsured and 15.80% with a disability are the published state-level
  magnitudes. Every offset variant lands between 47% and 100%, which would be
  visible to anyone who looked at the output once.
- **`B16005` carries the same hazard and was checked the same way.** It is a
  5-row cycle with a nativity-block break at line 24, and the task named only
  two sequences. Its sixteen lines were derived from the shell independently
  and match; they also match the sixteen cells CDC's own dictionary lists,
  which is an unusually strong second source, since `EP_LIMENG` is the one
  variable CDC still defines on a detailed table.
- **The only mapping with a subtraction is `EP_MINRTY`** (`B03002` line 1
  minus line 3), and a subtraction is where cancellation *could* live. It has
  two lines, not a sequence, and both were confirmed by `TITLE` (`Total:` and
  `White alone` under `Not Hispanic or Latino:`) and by the parent-sum check.

## What was not done, and why

- **`run_all.sh` was not rerun, and `EXPECTED-RESULTS.json` is unchanged.**
  No mapping was wrong, so no line in `01_build_estimates.R` changed, so
  nothing downstream could change. Rerunning would have been a null
  operation on an untouched pipeline. The reproduction gate stands where the
  2026-08-19 rerun left it: 57,368/57,368 and 57,918/57,918.
- **The state totals quoted above (8.05%, 15.80%, and the offset variants) are
  diagnostics, not results.** They trace to
  `analysis/louisiana/code/exploratory/verify_line_numbers.R` but are
  deliberately **not** added to `EXPECTED-RESULTS.json`, which is the pipeline
  manifest. They belong to this memo. Logged as such in `docs/STATUS.md` §7.
- **Nothing is marked unverified.** All sixteen shells were reachable; no
  variable fell back to "reproduces, therefore correct".

## Verdict

**All sixteen `EP_` line-number mappings in `01_build_estimates.R` are correct
against the published 2018–2022 5-year ACS table shells, verified line by line
without reliance on the fact that the pipeline reproduces CDC's file; the two
alternating sequences named as the leading compensating-error risk cannot
harbour one, because both halves of each enter additively and any off-by-one
changes the numerator by a factor of at least 3.2.**

This closes `docs/STATUS.md` §6 LLM task 1 and unblocks LLM task 4
(`svi-churn`), whose regression fixture would otherwise have frozen an
unverified mapping into the definition of correct.
