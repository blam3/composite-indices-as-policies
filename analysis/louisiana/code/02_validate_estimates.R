## ---------------------------------------------------------------------------
## 02_validate_estimates.R
## Check the reconstructed counts against CDC's published E_ values BEFORE any
## ranking. If this does not hit 100%, nothing downstream means anything.
## Components are summed back to variable level for comparison.
## ---------------------------------------------------------------------------
source(file.path(Sys.getenv("SVI_ROOT", ".."), "code", "00_config.R"))
suppressPackageStartupMessages(library(data.table))
source(file.path(SVI_ROOT, "code", "03_svi_pipeline.R"))
inp <- readRDS(file.path(DIR_WORK, "svi_inputs.rds"))
cdc <- fread(F_CDC, showProgress = FALSE, colClasses = list(character = "FIPS"))
setnames(cdc, names(cdc), sub("^﻿", "", names(cdc)))

keep <- match(cdc$FIPS, inp$fips)
stopifnot(!anyNA(keep))
cat(sprintf("CDC tracts: %d | VRT tracts: %d | dropped (water-only): %d\n\n",
            nrow(cdc), length(inp$fips), length(inp$fips) - nrow(cdc)))

chk <- function(lab, mine, theirs) {
  theirs <- as.numeric(theirs)
  ok <- is.finite(theirs) & theirs >= 0
  d <- mine[ok] - theirs[ok]
  cat(sprintf("%-8s n=%4d  exact=%4d (%6.2f%%)  maxabs=%7.0f\n",
              lab, sum(ok), sum(abs(d) < 1e-6), 100 * mean(abs(d) < 1e-6), max(abs(d))))
  sum(abs(d) < 1e-6) == sum(ok)
}

cat("--- denominators ---\n")
allok <- c(
  chk("TOTPOP", inp$extra$TOTPOP[keep, 1], cdc$E_TOTPOP),
  chk("HU",     inp$extra$HU[keep, 1],     cdc$E_HU),
  chk("HH",     inp$extra$HH[keep, 1],     cdc$E_HH))

cat("\n--- numerators (components summed back to variable level) ---\n")
for (v in SVI_VARS) {
  j <- which(inp$comp_var == v)
  mine <- if (length(j) == 1L) inp$NUM[keep, j, 1] else rowSums(inp$NUM[keep, j, 1, drop = FALSE])
  allok <- c(allok, chk(v, mine, cdc[[paste0("E_", v)]]))
}
cat(sprintf("\n===== %s: all %d checks exact =====\n",
            if (all(allok)) "PASS" else "FAIL", length(allok)))
if (!all(allok)) quit(status = 1)
