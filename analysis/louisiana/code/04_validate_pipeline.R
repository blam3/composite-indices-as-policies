source(file.path(Sys.getenv("SVI_ROOT", ".."), "code", "00_config.R"))
suppressPackageStartupMessages(library(data.table))
source(file.path(SVI_ROOT, "code", "03_svi_pipeline.R"))
inp <- readRDS(file.path(DIR_WORK, "svi_inputs.rds"))
cdc <- fread(F_CDC, showProgress = FALSE,
             colClasses = list(character = "FIPS"))
setnames(cdc, names(cdc), sub("^﻿", "", names(cdc)))
keep <- match(cdc$FIPS, inp$fips)
r <- svi_pipeline(inp$NUM[keep, , 1], inp$DEN[keep, , 1], inp$comp_var)

res <- list()
## AUDIT 2026-08-19 (independent audit, item 2): the previous version computed
## `na_ok <- identical(is.finite(mine), is.finite(theirs))` and neither recorded
## nor enforced it. `identical()` also compares attributes, so a named matrix
## column compared against an unnamed vector reported FALSE even when every
## missingness status agreed. Compare the raw logical masks elementwise, record
## the count, and make the script fail loudly if anything is off.
cmp <- function(lab, mine, theirs) {
  theirs <- as.numeric(theirs); theirs[theirs == -999] <- NA_real_
  fm <- unname(as.vector(is.finite(mine)))
  ft <- unname(as.vector(is.finite(theirs)))
  stopifnot(length(fm) == length(ft))
  n_missing_match <- sum(fm == ft)
  na_ok <- n_missing_match == length(fm)
  b <- fm & ft
  ex <- sum(abs(mine[b] - theirs[b]) < 1e-9)
  res[[lab]] <<- c(n = sum(b), exact = ex,
                   n_cells = length(fm), missing_match = n_missing_match)
  cat(sprintf("%-12s n=%4d  exact=%4d (%6.2f%%)  maxabs=%.6f  missingness %d/%d %s\n",
              lab, sum(b), ex, 100*ex/sum(b), max(abs(mine[b] - theirs[b])),
              n_missing_match, length(fm), if (na_ok) "OK" else "MISMATCH"))
}
cat("--- EP: the 16 estimated percentages ---\n")
for (v in SVI_VARS) cmp(paste0("EP_", v), r$EP[, v], cdc[[paste0("EP_", v)]])
cat("\n--- EPL: percentile ranks ---\n")
for (v in SVI_VARS) cmp(paste0("EPL_", v), r$EPL[, v], cdc[[paste0("EPL_", v)]])
cat("\n--- theme sums and ranks ---\n")
for (i in 1:4) {
  cmp(sprintf("SPL_THEME%d", i), r$SPL[, i], cdc[[sprintf("SPL_THEME%d", i)]])
  cmp(sprintf("RPL_THEME%d", i), r$RPL[, i], cdc[[sprintf("RPL_THEME%d", i)]])
}
cmp("SPL_THEMES", r$SPL_THEMES, cdc$SPL_THEMES)
cmp("RPL_THEMES", r$RPL_THEMES, cdc$RPL_THEMES)

M <- do.call(rbind, res)
values_ok    <- sum(M[, "exact"]) == sum(M[, "n"])
missing_ok   <- sum(M[, "missing_match"]) == sum(M[, "n_cells"])
cat(sprintf("\n===== OVERALL: %d of %d compared values reproduced exactly (%.4f%%) =====\n",
            sum(M[, "exact"]), sum(M[, "n"]), 100 * sum(M[, "exact"]) / sum(M[, "n"])))
cat(sprintf("===== MISSINGNESS: %d of %d cells agree on missing/present (%.4f%%) =====\n",
            sum(M[, "missing_match"]), sum(M[, "n_cells"]),
            100 * sum(M[, "missing_match"]) / sum(M[, "n_cells"])))

saveRDS(list(cdc_fips = cdc$FIPS, keep = keep, ref = r,
             values_compared = sum(M[, "n"]), values_exact = sum(M[, "exact"]),
             cells_compared  = sum(M[, "n_cells"]),
             missingness_match = sum(M[, "missing_match"]),
             values_ok = values_ok, missing_ok = missing_ok),
        file.path(DIR_WORK, "reference_run.rds"))

## AUDIT item 2: C1 is an exactness claim. Fail nonzero if either half of it fails.
if (!values_ok || !missing_ok) {
  cat("\n*** C1 FAILED: the reproduction is not exact. ***\n")
  if (!values_ok)  cat("    value mismatches:      ", sum(M[,"n"]) - sum(M[,"exact"]), "\n")
  if (!missing_ok) cat("    missingness mismatches:", sum(M[,"n_cells"]) - sum(M[,"missing_match"]), "\n")
  quit(status = 1L)
}
cat("===== C1 PASS: values exact AND missingness pattern identical =====\n")
