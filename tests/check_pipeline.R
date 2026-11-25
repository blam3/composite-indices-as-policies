# Small scientific boundary checks; do not replace the full Louisiana gate.
source("analysis/louisiana/code/03_svi_pipeline.R")
stopifnot(isTRUE(all.equal(round_sas(c(-1.25, 1.25), 1), c(-1.3, 1.3))))
stopifnot(isTRUE(all.equal(pctrank(c(1, 1, 2, NA)), c(0, 0, 1, NA))))
stopifnot(all(is.na(pctrank(c(1, NA)))))
num <- matrix(rep(1:4, length(SVI_VARS)), nrow=4,
              dimnames=list(NULL, SVI_VARS))
den <- matrix(10, nrow=4, ncol=length(SVI_VARS))
result <- svi_pipeline(num, den, SVI_VARS)
stopifnot(isTRUE(all.equal(result$RPL_THEMES, round(c(0, 1/3, 2/3, 1), 4))))
den[2, 1] <- 0
result <- svi_pipeline(num, den, SVI_VARS)
stopifnot(is.na(result$EP[2, 1]), is.na(result$RPL_THEMES[2]))
cat("Pipeline boundary checks passed (rounding, ties, missingness, ranking).\n")
