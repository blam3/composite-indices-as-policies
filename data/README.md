# Obtain and stage the Louisiana inputs

Download the **ACS 2018–2022 5-year Variance Replicate Tables**, summary level
140 (census tract), Louisiana state FIPS `22`, from the
[official Census directory](https://www2.census.gov/programs-surveys/acs/replicate_estimates/2022/data/5-year/140/).
For each table below, obtain its Louisiana CSV (possibly inside an archive).
The analysis reads these extracted filenames:

```text
analysis/louisiana/data/raw/140/B01001_22.csv
analysis/louisiana/data/raw/140/B01003_22.csv
analysis/louisiana/data/raw/140/B03002_22.csv
analysis/louisiana/data/raw/140/B11012_22.csv
analysis/louisiana/data/raw/140/B15002_22.csv
analysis/louisiana/data/raw/140/B16005_22.csv
analysis/louisiana/data/raw/140/B18101_22.csv
analysis/louisiana/data/raw/140/B23025_22.csv
analysis/louisiana/data/raw/140/B25003_22.csv
analysis/louisiana/data/raw/140/B25014_22.csv
analysis/louisiana/data/raw/140/B25024_22.csv
analysis/louisiana/data/raw/140/B25044_22.csv
analysis/louisiana/data/raw/140/B25106_22.csv
analysis/louisiana/data/raw/140/B26001_22.csv
analysis/louisiana/data/raw/140/B27001_22.csv
analysis/louisiana/data/raw/140/C17002_22.csv
analysis/louisiana/data/raw/Louisiana.csv
```

The final file is the
[CDC/ATSDR SVI 2022 Louisiana validation target](https://svi.cdc.gov/Documents/Data/2022/csv/states/Louisiana.csv).
Preserve the official columns and values. Do not substitute a newer SVI edition
or Census vintage. Verify the vintage and geography against the source before
running; a filename alone does not establish provenance.

From the repository root:

```bash
mkdir -p analysis/louisiana/data/raw/140
# Place the files above in this layout, then:
python3 scripts/check_inputs.py analysis/louisiana
bash analysis/louisiana/run_all.sh
```

Archives placed directly in `analysis/louisiana/data/raw/` are optionally
unpacked there by the runner. Check their extracted layout against the list
above; arbitrary nested archive layouts are not automatically normalized.

Input fingerprints are recorded at
`analysis/louisiana/outputs-rerun/INPUT-FINGERPRINTS.json`. These describe the
current staged files, not an independently supplied historical checksum set.
No source-data download or full reproduction was performed during the November
2026 presentation cleanup. The baseline numerical results remain unchanged.

Rerun intermediates go to `analysis/louisiana/work/`; new outputs go to
`analysis/louisiana/outputs-rerun/`. All three directories are ignored by Git.
Do not commit downloaded data.

## Source documentation

- [Census variance replicate documentation](https://www2.census.gov/programs-surveys/acs/replicate_estimates/2022/documentation/5-year/2018-2022_Variance_Replicate_Table_Documentation.pdf)
- [SVI 2022 documentation](https://www.atsdr.cdc.gov/place-health/media/pdfs/2024/10/SVI2022Documentation.pdf)

The variance replicates are survey-design pseudo-estimates, not independent
samples of true tract conditions. Interpret the Gaussian simulation conditional
on its covariance and boundary assumptions.
