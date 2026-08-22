# Working agreement for LLM sessions in this repository

Read this before doing anything. It exists because this project has already
had one published claim retracted and three numbers corrected by an
independent audit. The corrections are in the history on purpose. Adding a
fourth is fine; adding one silently is not.

## Orientation, in order

1. `docs/STATUS.md` — where the program is. Section 0 is an update contract
   that binds you. Section 2 holds verified numbers you must not re-derive
   casually. Section 4 lists corrections owed to the program document.
2. `docs/program.md` — what the program is. Scope, theory, prior art.
3. The task you were given.

If your task touches WP1 numbers, also read
`docs/wp1-louisiana-findings.md` and `docs/wp1-audit-response.md`.

## Hard rules

- **R by default.** Python only for glue that R would make painful, and say
  so when you reach for it.
- **The reproduction gate is 100%.** `analysis/louisiana/code/04_validate_pipeline.R`
  must report 57,368/57,368 values and 57,918/57,918 missingness cells for
  Louisiana and exit nonzero otherwise. Never widen a tolerance to make a
  check pass. If it fails, the finding is that it fails.
- **Never commit anything under `data/`.** The raw ACS variance replicate
  tables and the CDC validation file are fetched, not versioned.
- **No p-values.** Every coefficient in this project is a descriptive
  association, reported with county-clustered CR1 standard errors and, where
  Monte Carlo draws enter, a draw-block bootstrap. Write "descriptive
  association", not "effect".
- **Every number that appears in prose must trace to a script and to
  `EXPECTED-RESULTS.json`.** If you compute a number you cannot point at,
  it goes in the STATUS changelog marked unverified — not in STATUS §2 and
  not in a paper draft.
- **Update `docs/STATUS.md` in the same commit that changes what it
  describes**, following its §0 contract. Append to the changelog; never
  edit an existing changelog entry.

## Failure protocol

Reporting that you could not do something is a **success state** in this
repository, and is strictly preferred to a workaround. If you cannot fetch
a source document, cannot verify a mapping, or cannot reproduce a number:
stop, write what you tried and where it failed, and hand back. Do not
substitute a proxy source, do not infer the answer from the fact that the
code happens to reproduce, and do not silently narrow scope.

## Known traps, all of which have already bitten this project once

- **Compensating errors in alternating ACS line sequences.** `B27001` uses
  `seq(5,29,3)` / `seq(33,57,3)` and `B18101` uses `seq(4,19,3)` /
  `seq(23,38,3)`. A paired offset error in a sequence like this reproduces
  the published totals and is still wrong. Reproduction is not evidence
  that a mapping is right.
- **Symmetric-difference double counting.** `sum(flip)` is the size of the
  symmetric difference between the published and resampled funded sets and
  counts every replacement twice. Divide it by the funded count and you
  roughly double the churn rate. Use `churn_metrics()`; report
  `expected_leavers`, `expected_entrants` and `expected_label_changes`
  separately.
- **Conditioning on a mediator.** Rank position sits between input
  precision and rank noise. Regressions that "hold rank position fixed"
  are close to conditioning on a mediator; the equalisation experiment in
  `09_why_flat.R` is what licenses the causal reading, not the regression.
- **`identical()` on a named matrix column vs an unnamed vector compares
  attributes** and returns FALSE when the values agree. That defect made
  the missingness half of the reproduction gate report a false failure for
  a day. Compare unnamed masks elementwise.
- **Independent-MOE simulation is optimistic, not conservative**, and the
  mechanism is *within*-tract covariance (numerator with its own
  denominator, and across sixteen variables measured on the same
  households). Removing cross-tract covariance changes essentially nothing.
  An earlier claim to the contrary is retracted.
- **SVI 2022 has sixteen inputs, not fifteen.** The program document
  describes the 2018 edition in places.

## Branch and commit conventions

One agent session, one branch, one pull request. Branch names:
`wp<N>/<short-slug>`, e.g. `wp1/verify-line-numbers`. Commit messages state
what changed and what it implies for a claim, e.g.

    wp1: verify 16 ACS line-number mappings against published shells

    Re-derived each variable's line set from the table shell before
    looking at the code. 15 of 16 agree. B27001's second sequence is
    off by one; it compensates and still reproduces. Fixed; gate still
    100%.

## What not to do without being asked

Do not start WP3 optimisation code. Do not build a MILP. Do not fit
anything to outcome data. Those are gated on two open decisions in
`docs/STATUS.md` §3 that only the researcher can close.
