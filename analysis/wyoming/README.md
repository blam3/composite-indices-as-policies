# WP1 — Wyoming, SVI 2022 / ACS 2018–2022

Second-state replication of `analysis/louisiana/`. **Only `code/00_config.R`
is a real file here.** Every other script, and `run_all.sh`, is a symlink to
the Louisiana copy, so the two states cannot drift apart. The config differs
from Louisiana's in two lines:

```
STATE_FIPS <- "56"
STATE_NAME <- "Wyoming"
```

Inputs (fetched, not versioned; checksums in `INPUT-CHECKSUMS.sha256`):

- `data/raw/<table>_56.csv.zip` × 16 from
  `https://www2.census.gov/programs-surveys/acs/replicate_estimates/2022/data/5-year/140/`
- `data/raw/Wyoming.csv` from
  `https://svi.cdc.gov/Documents/Data/2022/csv/states/Wyoming.csv`

Run with `./run_all.sh` (about 3 minutes at B = 5,000). Results are in
`results/`, and the write-up is `docs/wp1-wyoming-findings.md`.
