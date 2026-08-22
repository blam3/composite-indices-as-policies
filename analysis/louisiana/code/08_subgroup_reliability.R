## ---------------------------------------------------------------------------
## 08_subgroup_reliability.R
## Is reliability itself non-invariant across subgroups, and if so in which
## direction?
##
## Two outcomes, deliberately separated:
##   (A) sd_rpl -- the SD of a tract's overall SVI percentile across draws. A
##       pure measurement-precision quantity, not confounded by where the tract
##       sits relative to a funding cutoff.
##   (B) flip_10 -- probability the top-decile funding decision changes. Here
##       proximity to the cutoff dominates, so it is modelled WITH a flexible
##       control for distance to the threshold.
##
## REVISED 2026-08-19 in response to the independent audit (item 5).
##
## The previous version reported independence-based p-values from
## `glm(..., weights = B)` and from OLS. Both are wrong here, for two separate
## reasons, and the audit was right to refuse them:
##
##   (i)  DESIGN dependence. `weights = B` asserts that a tract's flip rate comes
##        from B independent Bernoulli trials. It does not: every tract in a draw
##        shares the same z_b, so the effective information is far below B x n.
##        Replaced with a DRAW-BLOCK BOOTSTRAP -- refit the model on flip rates
##        computed from disjoint blocks of draws, and take the between-block
##        spread as the standard error.
##   (ii) SPATIAL dependence. Tracts are not independent observations. The
##        program document already flagged this for WP2 ("naive SEs will be badly
##        optimistic") and WP1 did not apply the same standard. Added
##        COUNTY-CLUSTERED (CR1) standard errors for every model here.
##
## Neither fix licenses a causal claim. These remain DESCRIPTIVE ASSOCIATIONS IN
## ONE STATE IN ONE VINTAGE. The argument in the write-up rests on the sign and
## magnitude of the coefficients, not on their p-values, and the prose now says
## so.
## ---------------------------------------------------------------------------
source(file.path(Sys.getenv("SVI_ROOT", ".."), "code", "00_config.R"))
suppressPackageStartupMessages({library(data.table); library(splines)})
s    <- readRDS(file.path(DIR_WORK, "sim.rds"))
relL <- readRDS(file.path(DIR_WORK, "reliability.rds"))
rel  <- relL$res[design == "replicate"]
d    <- merge(rel, s$cdc, by = "FIPS")
d    <- d[is.finite(rpl0) & E_TOTPOP > 0 & AREA_SQMI > 0]

d[, `:=`(
  pov       = EP_POV150,
  minority  = EP_MINRTY,
  nohs      = EP_NOHSDP,
  log_pop   = log(E_TOTPOP),
  log_dens  = log(E_TOTPOP / AREA_SQMI),
  dist_tau  = abs(rpl0 - 0.90)
)]
z <- function(x) (x - mean(x)) / sd(x)
hdr <- function(x) cat("\n", strrep("=", 78), "\n", x, "\n", strrep("=", 78), "\n", sep = "")

## ---------------------------------------------------------------------------
## CR1 cluster-robust covariance for lm and glm, hand-rolled so the audit bundle
## keeps its declared dependency list (no `sandwich`).
##   V = (X'WX)^-1 [ G/(G-1) * (n-1)/(n-k) * sum_g s_g s_g' ] (X'WX)^-1
## with s_g the sum of the score contributions in cluster g.
## ---------------------------------------------------------------------------
cluster_se <- function(fit, cluster) {
  X  <- model.matrix(fit)
  n  <- nrow(X); k <- ncol(X)
  cl <- factor(cluster[seq_len(n)])
  if (inherits(fit, "glm")) {
    w  <- if (is.null(fit$prior.weights)) rep(1, n) else as.numeric(fit$prior.weights)
    mu <- as.numeric(fitted(fit))
    U  <- (w * (as.numeric(fit$y) - mu)) * X            # canonical-link score
    bread <- solve(crossprod(X, (w * mu * (1 - mu)) * X))
  } else {
    U  <- as.numeric(residuals(fit)) * X
    bread <- solve(crossprod(X))
  }
  S <- rowsum(U, cl)
  G <- nrow(S)
  meat <- crossprod(S) * (G / (G - 1)) * ((n - 1) / (n - k))
  sqrt(diag(bread %*% meat %*% bread))
}

report <- function(fit, cluster, drop = "^ns\\(") {
  co  <- summary(fit)$coefficients
  cse <- cluster_se(fit, cluster)
  tab <- cbind(estimate = co[, 1], se_naive = co[, 2], se_cluster = cse,
               t_cluster = co[, 1] / cse, ratio = cse / co[, 2])
  tab <- tab[!grepl(drop, rownames(tab)), , drop = FALSE]
  print(round(tab, 5))
  invisible(tab)
}

hdr("A. IS MEASUREMENT PRECISION EQUALLY DISTRIBUTED? (outcome: SD of RPL_THEMES)")
cat("\nUnivariate: mean SD of the overall percentile by quintile of each characteristic\n")
for (v in c("pov","minority","nohs","log_dens","log_pop")) {
  q <- cut(d[[v]], quantile(d[[v]], 0:5/5), include.lowest = TRUE, labels = 1:5)
  m <- tapply(d$sd_rpl, q, mean)
  cat(sprintf("  %-9s Q1=%.4f Q2=%.4f Q3=%.4f Q4=%.4f Q5=%.4f   Q5/Q1=%.2f\n",
              v, m[1], m[2], m[3], m[4], m[5], m[5]/m[1]))
}
fit <- lm(sd_rpl ~ z(pov) + z(minority) + z(nohs) + z(log_pop) + z(log_dens), data = d)
cat("\nOLS, all standardised (coefficient = change in SD per 1 SD of predictor).\n")
cat("`se_cluster` clusters on county; `ratio` shows how much the naive SE understates.\n")
tabA <- report(fit, d$COUNTY)
cat(sprintf("\nR^2 = %.3f   residual SD = %.4f   n = %d   counties = %d\n",
            summary(fit)$r.squared, sigma(fit), nobs(fit), uniqueN(d$COUNTY)))
cat("For scale: the median tract SD is", sprintf("%.4f", median(d$sd_rpl)),
    "percentile-rank units.\n")

hdr("B. DO EQUALLY MARGINAL TRACTS FLIP AT EQUAL RATES? (outcome: top-decile flip)")
cat("\nQuasi-binomial GLM with a natural-spline control for |published percentile - 0.90|.\n")
cat("Coefficients are DESCRIPTIVE. Three standard errors are shown so the reader can\n")
cat("see how much of the apparent precision was an artefact of assuming independence.\n")
g <- glm(flip_10 ~ ns(dist_tau, 5) + z(pov) + z(minority) + z(nohs) + z(log_pop) + z(log_dens),
         family = quasibinomial(), weights = rep(s$B, nrow(d)), data = d)
tabg <- report(g, d$COUNTY)

## --- draw-block bootstrap: the design-based standard error ------------------
## Recompute each tract's flip rate inside disjoint blocks of draws, refit, and
## take the between-block spread. This is the only SE here that respects the
## fact that all tracts in a draw share one z_b.
M   <- s$sim_rep$rpl
idx <- match(d$FIPS, s$fips)
a0  <- d$rpl0 >= 0.90
K   <- max(2L, min(50L, s$B %/% 50L))        # blocks of >= 50 draws where possible
blk <- split(seq_len(s$B), cut(seq_len(s$B), K, labels = FALSE))
form <- flip_10 ~ ns(dist_tau, 5) + z(pov) + z(minority) + z(nohs) + z(log_pop) + z(log_dens)
boot <- vapply(blk, function(ix) {
  fb <- colMeans(sweep(M[ix, idx, drop = FALSE] >= 0.90, 2, a0, `!=`), na.rm = TRUE)
  fb[!is.finite(fb)] <- d$flip_10[!is.finite(fb)]   # tract retained no draw in this block
  dd <- copy(d)
  dd[, `:=`(flip_10 = fb, .bw = length(ix))]        # weight as a column: glm looks in `data`
  gg <- suppressWarnings(glm(form, family = quasibinomial(), weights = .bw, data = dd))
  coef(gg)
}, numeric(length(coef(g))))
boot_se <- apply(boot, 1, sd) / sqrt(K)
keepc <- !grepl("^ns\\(", names(coef(g)))
cat(sprintf("\nDraw-block bootstrap (%d blocks of %d draws):\n", K, s$B %/% K))
print(round(cbind(estimate     = coef(g)[keepc],
                  se_naive     = summary(g)$coefficients[keepc, 2],
                  se_cluster   = tabg[, "se_cluster"],
                  se_drawblock = boot_se[keepc]), 5))
cat("\nThe three standard errors answer different questions and are NOT interchangeable.\n")
cat("  se_naive     assumes B independent Bernoulli trials per tract and independent\n")
cat("               tracts. Both are false; it is the smallest and the least defensible.\n")
cat("  se_drawblock is the MONTE CARLO component only -- how much the coefficient would\n")
cat("               move if the simulation were rerun. It is small, which is the useful\n")
cat("               news: the estimates are not simulation artefacts.\n")
cat("  se_cluster   allows tracts within a county to be dependent. It is the largest and\n")
cat("               is the one to quote, and it still understates spatial dependence that\n")
cat("               crosses county lines.\n")
cat("\nOdds ratios per 1 SD (point estimates; treat as descriptive):\n")
print(round(exp(coef(g)[keepc][-1]), 4))

cat("\nAmong the 200 tracts closest to the top-decile cutoff:\n")
n200 <- d[order(dist_tau)][1:200]
for (v in c("pov","minority","log_dens")) {
  hi <- n200[[v]] > median(n200[[v]])
  cat(sprintf("  %-9s above-median %.3f  vs below-median %.3f  (mean flip rate)\n",
              v, mean(n200$flip_10[hi]), mean(n200$flip_10[!hi])))
}

hdr("C. WHERE THE FUNDING DECISION IS LEAST SECURE")
top <- d[rpl0 >= 0.90][order(p_fund_10)]
cat("\nFunded tracts (published top decile) with the weakest claim to their status:\n")
print(top[1:12, .(FIPS, COUNTY, rpl0, p_fund = p_fund_10, sd = round(sd_rpl,3),
                  lo90 = round(lo90,3), hi90 = round(hi90,3), pov = EP_POV150, minrty = EP_MINRTY)])
out <- d[rpl0 < 0.90][order(-p_fund_10)]
cat("\nUnfunded tracts most often funded across draws:\n")
print(out[1:12, .(FIPS, COUNTY, rpl0, p_fund = p_fund_10, sd = round(sd_rpl,3),
                  lo90 = round(lo90,3), hi90 = round(hi90,3), pov = EP_POV150, minrty = EP_MINRTY)])
fwrite(d, file.path(DIR_OUT, "tract_reliability_with_covariates.csv"))
saveRDS(list(boot_se = boot_se, cluster_tab_A = tabA, cluster_tab_B = tabg, K = K),
        file.path(DIR_WORK, "inference.rds"))
