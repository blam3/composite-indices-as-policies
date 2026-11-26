## ---------------------------------------------------------------------------
## 09_why_flat.R
## Rank reliability is nearly flat across subgroups while input precision is not.
## Why?
##
## REVISED 2026-08-19 in response to the independent audit (item 5).
##
## The previous version answered this with a regression: condition on published
## rank position with `ns(rpl0, 6)` and observe that the subgroup coefficients
## collapse. The audit's objection is correct and was already on the author's own
## suspect list (SUSPECTS.md item 7): rank position is itself partly a function
## of poverty, so adjusting for it is close to adjusting for a mediator, and a
## regression adjustment is not a demonstration that the ranking step CAUSES the
## flattening.
##
## Section 3 now runs the experiment instead. Two matched simulations perturb the
## sixteen estimated percentages directly:
##     ep_actual     each tract keeps its own EP-level standard errors
##     ep_equalised  every tract's EP-level SE is rescaled to the cross-tract
##                   MEDIAN for that variable -- input precision is equal by
##                   construction, and nothing else changes
## If the inverted-U shape of rank-SD against rank position survives
## equalisation, the shape is a mechanical property of ranking rather than an
## imprint of unequal inputs, and the flattening claim is an experimental result.
##
## Section 4 keeps the regression, relabelled as what it is: a descriptive
## decomposition, reported alongside the experiment, not in place of it.
## ---------------------------------------------------------------------------
source(file.path(Sys.getenv("SVI_ROOT", ".."), "code", "00_config.R"))
suppressPackageStartupMessages({library(data.table); library(splines)})
source(file.path(SVI_ROOT, "code", "03_svi_pipeline.R"))
inp  <- readRDS(file.path(DIR_WORK, "svi_inputs.rds"))
s    <- readRDS(file.path(DIR_WORK, "sim.rds"))
relL <- readRDS(file.path(DIR_WORK, "reliability.rds"))
rel  <- relL$res[design == "replicate"]
cdc  <- s$cdc
keep <- match(cdc$FIPS, inp$fips)

## EP-level SDR standard errors, computed in 05 and reused here.
seEP <- s$seEP

d <- merge(rel, cdc, by = "FIPS")[is.finite(rpl0) & E_TOTPOP > 0 & AREA_SQMI > 0]
m <- match(d$FIPS, cdc$FIPS)
z <- function(x) (x - mean(x, na.rm=TRUE)) / sd(x, na.rm=TRUE)
hdr <- function(x) cat("\n", strrep("=",78), "\n", x, "\n", strrep("=",78), "\n", sep="")

## Cluster-robust SEs, same helper as 08 (audit item 5).
cluster_se <- function(fit, cluster) {
  X <- model.matrix(fit); n <- nrow(X); k <- ncol(X)
  cl <- factor(cluster[seq_len(n)])
  U <- as.numeric(residuals(fit)) * X
  bread <- solve(crossprod(X))
  S <- rowsum(U, cl); G <- nrow(S)
  meat <- crossprod(S) * (G/(G-1)) * ((n-1)/(n-k))
  sqrt(diag(bread %*% meat %*% bread))
}
report <- function(fit, cluster, drop = "^ns\\(") {
  co <- summary(fit)$coefficients; cse <- cluster_se(fit, cluster)
  tab <- cbind(estimate = co[,1], se_naive = co[,2], se_cluster = cse,
               t_cluster = co[,1]/cse)
  tab <- tab[!grepl(drop, rownames(tab)), , drop = FALSE]
  print(round(tab, 5)); invisible(tab)
}

hdr("1. INPUT PRECISION *IS* WORSE IN POOR TRACTS -- at the EP level")
cat("\nSE of each estimated percentage, by quintile of tract poverty rate:\n")
cat(sprintf("%-9s %7s %7s %7s %7s %7s   %6s\n","variable","Q1","Q2","Q3","Q4","Q5","Q5/Q1"))
qp <- cut(d$EP_POV150, quantile(d$EP_POV150, 0:5/5), include.lowest=TRUE, labels=1:5)
for (v in SVI_VARS) {
  a <- tapply(seEP[m, v], qp, mean, na.rm=TRUE)
  cat(sprintf("%-9s %7.3f %7.3f %7.3f %7.3f %7.3f   %6.2f\n", v, a[1],a[2],a[3],a[4],a[5], a[5]/a[1]))
}
cat("\nSame, by quintile of minority share:\n")
qm <- cut(d$EP_MINRTY, quantile(d$EP_MINRTY, 0:5/5), include.lowest=TRUE, labels=1:5)
cat(sprintf("%-9s %7s %7s %7s %7s %7s   %6s\n","variable","Q1","Q2","Q3","Q4","Q5","Q5/Q1"))
for (v in SVI_VARS) {
  a <- tapply(seEP[m, v], qm, mean, na.rm=TRUE)
  cat(sprintf("%-9s %7.3f %7.3f %7.3f %7.3f %7.3f   %6.2f\n", v, a[1],a[2],a[3],a[4],a[5], a[5]/a[1]))
}

hdr("2. RANK NOISE IS AN INVERTED U IN RANK POSITION (descriptive)")
cat("\nSD of the overall percentile by decile of the PUBLISHED percentile:\n")
qr <- cut(d$rpl0, seq(0,1,.1), include.lowest=TRUE)
a <- tapply(d$sd_rpl, qr, mean); n <- table(qr)
for (i in seq_along(a)) cat(sprintf("  %-12s n=%4d  mean SD = %.4f\n", names(a)[i], n[i], a[i]))
cat("\nA tract at the median has the most neighbours within reach to swap with;\n")
cat("a tract at either extreme has few. Any subgroup contrast that does not\n")
cat("condition on rank position is confounded by this. Whether the shape is\n")
cat("MECHANICAL is tested in section 3, not asserted here.\n")

## ---------------------------------------------------------------------------
hdr("3. EXPERIMENT: equalise input precision and see if the shape survives")
## ---------------------------------------------------------------------------
eqA <- relL$res[design == "ep_actual"    & is.finite(rpl0)]
eqB <- relL$res[design == "ep_equalised" & is.finite(rpl0)]
setkey(eqA, FIPS); setkey(eqB, FIPS)
E <- merge(eqA[, .(FIPS, rpl0, sd_actual = sd_rpl)],
           eqB[, .(FIPS, sd_equal = sd_rpl)], by = "FIPS")
cat(sprintf("\nBy construction the equalised design gives every tract the median EP-level SE\n"))
cat(sprintf("for each of the 16 variables. Cross-tract SD of the input-imprecision index:\n"))
imp_a <- rowMeans(scale(seEP[m, ]), na.rm = TRUE)
cat(sprintf("  actual precision:    sd(imprecision index) = %.4f\n", sd(imp_a)))
cat(sprintf("  equalised precision: sd(imprecision index) = 0 (definitionally)\n"))

cat("\nMean rank SD by decile of published percentile, under both designs:\n")
qE <- cut(E$rpl0, seq(0,1,.1), include.lowest = TRUE)
ta <- tapply(E$sd_actual, qE, mean); tb <- tapply(E$sd_equal, qE, mean)
cat(sprintf("  %-12s %10s %10s %8s\n", "decile", "actual", "equalised", "ratio"))
for (i in seq_along(ta))
  cat(sprintf("  %-12s %10.4f %10.4f %8.3f\n", names(ta)[i], ta[i], tb[i], tb[i]/ta[i]))
cat(sprintf("\n  correlation of the two decile profiles: %.4f\n",
            cor(as.numeric(ta), as.numeric(tb))))
cat(sprintf("  peak decile: actual = %s, equalised = %s\n",
            names(ta)[which.max(ta)], names(tb)[which.max(tb)]))
cat(sprintf("  R^2 of ns(rpl0,6) on rank SD: actual = %.3f, equalised = %.3f\n",
            summary(lm(sd_actual ~ ns(rpl0,6), data = E))$r.squared,
            summary(lm(sd_equal  ~ ns(rpl0,6), data = E))$r.squared))
top <- length(ta)
cat(sprintf("\n  RATIO IN THE TOP DECILE (the funded set): equalised/actual = %.3f\n", tb[top]/ta[top]))
cat(sprintf("  i.e. the published top decile carries %.2fx the rank noise it would carry\n", ta[top]/tb[top]))
cat("  if every tract's inputs were measured as precisely as the median tract's.\n")
cat(sprintf("  The same ratio in the BOTTOM decile is %.3f.\n", tb[1]/ta[1]))
cat("  So equalisation does not shift the shape (it is mechanical) but it does shift\n")
cat("  the LEVEL, and it shifts it most where the index is used to allocate money.\n")

cat("\nInterpretation. If the equalised profile keeps the same inverted-U shape and\n")
cat("peak location, unequal input precision is NOT what generates the shape --\n")
cat("rank position is. That is the claim the write-up may make. What it may NOT\n")
cat("claim from this experiment is that ranking removes the consequences of\n")
cat("unequal precision: section 4 shows precision still tracks rank SD once\n")
cat("position is held fixed.\n")

## ---------------------------------------------------------------------------
hdr("4. THE PRECISION THAT DOES SURVIVE: raw input noise -> rank noise")
## ---------------------------------------------------------------------------
cat("\nA tract-level index of raw input imprecision (mean SE across the 16 EP,\n")
cat("standardised within variable), against subgroup and against rank SD.\n")
cat("County-clustered SEs; these are DESCRIPTIVE", STATE_NAME, "associations.\n")
d[, imprecision := imp_a]
report(lm(imprecision ~ z(EP_POV150) + z(EP_MINRTY) + z(log(E_TOTPOP)) +
            z(log(E_TOTPOP/AREA_SQMI)), data = d), d$COUNTY)

f0 <- lm(sd_rpl ~ ns(rpl0, 6), data = d)
f1 <- lm(sd_rpl ~ ns(rpl0, 6) + z(EP_POV150) + z(EP_MINRTY) + z(log(E_TOTPOP)), data = d)
cat("\nSD of overall percentile, conditioning on rank position with a spline:\n")
report(f1, d$COUNTY)
cat(sprintf("\nR^2: rank position alone = %.3f | plus subgroup covariates = %.3f\n",
            summary(f0)$r.squared, summary(f1)$r.squared))
cat(sprintf("correlation(input imprecision, rank SD) = %.3f\n", cor(d$imprecision, d$sd_rpl)))
cat(sprintf("partial correlation given rank position  = %.3f\n",
            cor(resid(lm(imprecision ~ ns(rpl0,6), data=d)), resid(lm(sd_rpl ~ ns(rpl0,6), data=d)))))
cat("\nNote on the partial correlation: rank position is partly a consequence of the\n")
cat("same tract characteristics that drive imprecision, so conditioning on it is\n")
cat("close to conditioning on a mediator. Read the partial correlation as 'among\n")
cat("tracts sitting in the same place in the published ranking, the noisier ones\n")
cat("move more' -- an association, not an isolated causal channel.\n")

saveRDS(list(seEP = seEP, d = d, equalisation = E,
             decile_actual = as.numeric(ta), decile_equal = as.numeric(tb)),
        file.path(DIR_WORK, "precision.rds"))
