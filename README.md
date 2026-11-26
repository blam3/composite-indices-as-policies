# Composite Indices as Policies

**How reliable are the scores used to allocate public resources?**

The Social Vulnerability Index (SVI) is calculated for each census tract in the United 
States, and quantifies how susceptible a community is to stressors and public health 
emergencies. The SVI has been used to guide and allocate funding across 
federal, state, and local programs, including disaster recovery, public health, and 
municipal support.

**This project studies how sampling uncertainty in the American Community Survey
data propagates through the CDC/ATSDR Social Vulnerability Index and
changes which census tracts qualify for funding under hypothetical allocation thresholds.**
It connects measurement error to decisions that an index could induce.

**Methods:** R; public-data reconstruction; variance replicates; Monte Carlo
simulation; uncertainty propagation; descriptive subgroup analysis

![Louisiana decision reliability, archived analysis](analysis/louisiana/results/svi_decision_reliability.png)

## Case study: Louisiana

The committed Louisiana analysis reports:

| Check or result | Archived value | Source in the results manifest |
|---|---:|---|
| Published SVI values reproduced exactly | 57,368 / 57,368 | `deterministic.reproduction` |
| Missing/present cells matched | 57,918 / 57,918 | `deterministic.reproduction` |
| Census tracts in the CDC comparison | 1,379 | `deterministic.meta.n_tracts_cdc` |
| Expected leavers from the published top decile | 34.17 of 137 (24.94%) | `monte_carlo.decisions_replicate.top_decile` |
| Median 90% rank-interval width | 29.25 percentile points | `monte_carlo.rank_stability.replicate` |

[Case study and interpretation](docs/case-study.md) ·
[Machine-readable reference](analysis/louisiana/results/EXPECTED-RESULTS.json) ·
[Tract-level results](analysis/louisiana/results/tract_decision_reliability.csv)

These are **archived results**. The allocation is a hypothetical
rank-threshold rule. The simulation does not establish that actual grants were
misallocated, estimate benefits of alternative policies, or identify causal
relationships between tract characteristics and outcomes.

## Reproduce the analysis

Requirements: **R**, **Python 3**, and `unzip`; R packages `data.table`,
`ggplot2`, `dplyr`, `gridExtra`, and `jsonlite` (`splines` ships with R).
The archived reference records R 4.3.3; no complete historical dependency lock
is available. Compatibility with other R/package versions must be checked.

```bash
git clone https://github.com/blam3/composite-indices-as-policies.git
cd composite-indices-as-policies
Rscript -e 'install.packages(c("data.table", "ggplot2", "dplyr", "gridExtra", "jsonlite"), repos="https://cloud.r-project.org")'
# Download and stage the inputs as described in data/README.md.
bash analysis/louisiana/run_all.sh
```

[Exact input layout and official sources](data/README.md). Because raw input files aren't included in the repository, you have to download them yourself. The pipeline script verifies your software packages and input columns, records digital fingerprints (SHA-256 hashes) of your local files, runs the analysis, and checks your results against the archived reference. Keep in mind that these file fingerprints only log the data you used today; since the original file checksums weren't saved, they can't prove your downloaded files match the exact versions from the initial run.

To pass verification, your local run must reproduce 100% of the published values and missing-data patterns. Specifically, deterministic outputs must match the reference within a 1e-9 absolute tolerance, and Monte Carlo simulation outputs must fall within a 2% relative tolerance (using the exact same random seed and draw counts). If any check fails, the script exits with an error. All newly generated files are ignored by Git, so your local run will never overwrite the saved reference results.

## Lightweight checks

```bash
make check
```

CI parses R files, exercises the pure ranking function on small boundary cases,
checks the comparison tools, and rejects committed raw data. It does **not**
rerun the full ACS analysis. See [verification status](docs/verification.md)
for current limits and unresolved documentation discrepancies.

## Scope and project status

| Work | Status |
|---|---|
| Louisiana SVI reconstruction and uncertainty analysis | Code and archived outputs available; earlier AI-assisted audit documented |
| Portable reproduction tooling | Repaired paths and input preflight; full-data rerun still required |
| Reusable `svi-churn` package | Planned; not implemented |
| Outcome validation, transported policy guarantees, participatory weights | Research roadmap; not completed |
| Applications to aggregate AI evaluation scores | Proposed extension; not an established result |

The [program document](docs/program.md) is an evolving research proposal;
[STATUS](docs/STATUS.md) distinguishes completed work and open decisions.

## Repository map

- `analysis/louisiana/code/`: reconstruction, simulations, analysis, figure generation
- `analysis/louisiana/results/`: committed reference manifest, figure, tract outputs
- `analysis/louisiana/run_all.sh`: analysis entry point
- `scripts/`: input fingerprinting and manifest comparison (Python standard library)
- `tests/`: ranking boundary checks and reproduction-tool failure checks
- `docs/`: case study, audit history, verification notes, and future research

## License

Research repository maintained by Brendan Lam. The historical
[audit response](docs/wp1-audit-response.md) records Codex and Claude assistance. Research conclusions should be
reviewed independently before use in policy.

Code: [MIT](LICENSE). Prose and figures: [CC BY 4.0](LICENSE-docs).
Citation metadata: [CITATION.cff](CITATION.cff).
