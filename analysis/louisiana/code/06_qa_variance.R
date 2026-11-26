## QA: does the successive-difference-replication estimator applied to the 80
## replicates reproduce the standard error the Census Bureau publishes in the
## same file? If not, the whole uncertainty analysis is built on sand.
source(file.path(Sys.getenv("SVI_ROOT", ".."), "code", "00_config.R"))
suppressPackageStartupMessages(library(data.table))
VAL <- c("ESTIMATE", paste0("Var_Rep", 1:80))
chk <- function(tbl) {
  d <- fread(VRT_FILE(tbl),
             select = c("GEOID","ORDER","ESTIMATE","MOE","SE", paste0("Var_Rep",1:80)),
             showProgress = FALSE)
  d <- d[!is.na(ORDER)]
  reps <- as.matrix(d[, paste0("Var_Rep",1:80), with = FALSE])
  se_hat <- sqrt(pmax(0, (4/80) * rowSums((reps - d$ESTIMATE)^2)))
  ok <- is.finite(d$SE) & d$SE > 0
  rel <- abs(se_hat[ok] - d$SE[ok]) / d$SE[ok]
  cat(sprintf("%-8s n=%6d  median rel.err=%.2e  p99=%.2e  max=%.2e  (published SE is integer-rounded)\n",
              tbl, sum(ok), median(rel), quantile(rel, .99), max(rel)))
}
for (t in c("B01003","C17002","B23025","B25024","B26001","B03002")) chk(t)
