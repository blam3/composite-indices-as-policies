# Data

**Nothing in this directory is version-controlled.** Fetch it.

## ACS 2018–2022 5-year Variance Replicate Tables

Summary level 140 (census tract). Louisiana is state FIPS `22`.

Base URL:
`https://www2.census.gov/programs-surveys/acs/replicate_estimates/2022/data/5-year/140/`

Sixteen tables are required:

```
B01001 B01003 B03002 B11012 B15002 B16005 B18101 B23025
B25003 B25014 B25024 B25044 B25106 B26001 B27001 C17002
```

Unpack into `data/raw/`.

Documentation (read the note on pseudo-estimates having no independent
meaning before interpreting any single replicate):
`https://www2.census.gov/programs-surveys/acs/replicate_estimates/2022/documentation/5-year/2018-2022_Variance_Replicate_Table_Documentation.pdf`

## CDC/ATSDR SVI 2022 validation target

`https://svi.cdc.gov/Documents/Data/2022/csv/states/Louisiana.csv`

Documentation:
`https://www.atsdr.cdc.gov/place-health/media/pdfs/2024/10/SVI2022Documentation.pdf`

## Fetching from a sandboxed LLM session

Anthropic's Cowork sandbox proxy blocks `census.gov` and `cdc.gov`;
`WebFetch` on the variance replicate directory returns `ROBOTS_DISALLOWED`.
The route that works is to drive a local Chrome to each file URL so the
downloads land in `~/Downloads`, then stage them into the session. Running
Claude Code locally on your own machine has no such restriction and is the
better surface for any task that needs these files.

GitHub, PyPI and npm are reachable from the sandbox; CRAN is not. Install R
and R packages from apt there: `r-base-core`, `r-cran-data.table`,
`r-cran-ggplot2`, `r-cran-dplyr`, `r-cran-gridextra`, `r-cran-jsonlite`.
Disable any `download.docker.com` apt source first or `apt-get update`
fails.
