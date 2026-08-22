## ---------------------------------------------------------------------------
## 07_decision_reliability.R -- WP1 results.
##  (1) How much of the SVI ranking is survey noise?
##  (2) What does that do to the funding decision?
##
## REVISED 2026-08-19 in response to the independent audit (items 1 and 4).
##
## AUDIT ITEM 1, the substantive correction. The previous version reported
## `sum(flip)` as "expected churn: N of M funded tracts change status per draw."
## That is wrong. `sum(flip)` is the expected size of the SYMMETRIC DIFFERENCE
## between the published funded set and the resampled one -- it counts each
## replacement twice, once as a departure and once as an arrival. Three distinct
## quantities are now computed and named separately:
##
##   expected_leavers       sum over published-funded tracts of P(not funded)
##                          -- how much of the published list falls off
##   expected_entrants      sum over published-unfunded tracts of P(funded)
##                          -- how many newcomers take their place
##   expected_label_changes leavers + entrants; the symmetric difference; the
##                          quantity previously mislabelled
##
## Under a fixed-count programme leavers and entrants are near-equal by
## construction, so the honest headline is the LEAVER rate: what share of the
## published top decile would not be on the list if the survey were rerun.
## ---------------------------------------------------------------------------
source(file.path(Sys.getenv("SVI_ROOT", ".."), "code", "00_config.R"))
suppressPackageStartupMessages({library(data.table)})
s <- readRDS(file.path(DIR_WORK, "sim.rds"))
B <- s$B; rpl0 <- s$rpl0; nt <- length(rpl0)
THRESH <- c(0.90, 0.80, 0.75)                    # top decile / quintile / quartile

DESIGNS <- list(
  replicate          = s$sim_rep,   # shared z: within-tract AND cross-tract covariance
  within_tract       = s$sim_wit,   # per-tract z: within-tract covariance only
  no_cov             = s$sim_ind,   # independent components: no covariance at all
  replicate_minclamp = s$sim_mcl,   # boundary-treatment sensitivity
  ep_actual          = s$sim_epa,   # EP-level control for the equalisation experiment
  ep_equalised       = s$sim_epq    # EP-level, input precision equalised across tracts
)

summarise_design <- function(sim, label) {
  M <- sim$rpl                                    # [B x tract]
  sd_rpl <- apply(M, 2, sd, na.rm = TRUE)
  q <- apply(M, 2, quantile, probs = c(.05, .50, .95), na.rm = TRUE)
  disp <- colMeans(abs(sweep(M, 2, rpl0)), na.rm = TRUE)
  out <- data.table(FIPS = s$fips, rpl0 = rpl0, sd_rpl = sd_rpl,
                    lo90 = q[1, ], med = q[2, ], hi90 = q[3, ],
                    mean_abs_disp = disp,
                    retained = colSums(is.finite(M)))
  for (tau in THRESH) {
    fund_b <- M >= tau
    a0 <- rpl0 >= tau
    k <- round(100 * (1 - tau))
    out[[sprintf("p_fund_%02d", k)]] <- colMeans(fund_b, na.rm = TRUE)
    ## per-tract probability that this tract's OWN label differs from published
    out[[sprintf("flip_%02d",   k)]] <- colMeans(sweep(fund_b, 2, a0, `!=`), na.rm = TRUE)
  }
  out[, design := label][]
}

res <- rbindlist(Map(summarise_design, DESIGNS, names(DESIGNS)))
fwrite(res, file.path(DIR_OUT, "tract_decision_reliability.csv"))

## ---------------------------------------------------------------------------
## AUDIT ITEM 1: the three churn quantities, computed once, used everywhere.
## `churn_metrics` is saved with the results and re-used by 10_figure.R and
## 11_expected_results.R so that the prose, the figure and the JSON cannot drift
## apart again.
## ---------------------------------------------------------------------------
churn_metrics <- function(dt, tau) {
  k  <- round(100 * (1 - tau))
  p  <- dt[[sprintf("p_fund_%02d", k)]]
  fl <- dt[[sprintf("flip_%02d",   k)]]
  a0 <- dt$rpl0 >= tau
  list(
    tau                    = tau,
    n_funded               = sum(a0),
    expected_leavers       = sum(1 - p[a0]),
    leaver_rate            = sum(1 - p[a0]) / sum(a0),
    expected_entrants      = sum(p[!a0]),
    expected_label_changes = sum(fl),
    mean_flip              = mean(fl),
    funded_p_lt_090        = sum(a0 & p < .90),
    unfunded_p_gt_010      = sum(!a0 & p > .10),
    funded_interval_crosses= sum(a0 & dt$lo90 < tau)
  )
}

hdr <- function(x) cat("\n", strrep("=", 78), "\n", x, "\n", strrep("=", 78), "\n", sep = "")

hdr("1. RANK STABILITY OF THE OVERALL SVI (RPL_THEMES)")
for (d in names(DESIGNS)) {
  x <- res[design == d & is.finite(rpl0)]
  cat(sprintf("\n[%s design]\n", d))
  cat(sprintf("  median SD of the overall percentile           : %.4f\n", median(x$sd_rpl)))
  cat(sprintf("  median width of the 90%% interval on percentile: %.4f\n", median(x$hi90 - x$lo90)))
  cat(sprintf("  median |displacement| in percentile points     : %.2f\n", 100*median(x$mean_abs_disp)))
  cat(sprintf("  tracts whose 90%% interval spans >20 percentile points: %d (%.1f%%)\n",
              sum(x$hi90 - x$lo90 > .20), 100*mean(x$hi90 - x$lo90 > .20)))
  cat(sprintf("  tracts whose 90%% interval spans >40 percentile points: %d (%.1f%%)\n",
              sum(x$hi90 - x$lo90 > .40), 100*mean(x$hi90 - x$lo90 > .40)))
}

hdr("2. DECISION CHURN: does the funding decision survive the survey error?")
cat("\nRead the three quantities carefully; they answer different questions.\n")
cat("  leavers  = expected number of PUBLISHED-FUNDED tracts that fall off the list\n")
cat("  entrants = expected number of PUBLISHED-UNFUNDED tracts that take their place\n")
cat("  label changes = leavers + entrants = size of the symmetric difference.\n")
cat("  The headline is the LEAVER RATE. 'label changes' must never be divided by\n")
cat("  the number of funded tracts and called a churn percentage.\n")
for (d in names(DESIGNS)) {
  x <- res[design == d & is.finite(rpl0)]
  cat(sprintf("\n[%s design]  n = %d tracts\n", d, nrow(x)))
  for (tau in THRESH) {
    m <- churn_metrics(x, tau)
    cat(sprintf("  top %2d%%: %4d tracts funded on the published index\n",
                round(100*(1-tau)), m$n_funded))
    cat(sprintf("           expected leavers  %6.2f of %d  (%.1f%% of the published list)\n",
                m$expected_leavers, m$n_funded, 100*m$leaver_rate))
    cat(sprintf("           expected entrants %6.2f\n", m$expected_entrants))
    cat(sprintf("           expected label changes (symmetric difference) %6.2f\n",
                m$expected_label_changes))
    cat(sprintf("           funded tracts with P(funded) < 0.90: %d | unfunded with P(funded) > 0.10: %d\n",
                m$funded_p_lt_090, m$unfunded_p_gt_010))
    cat(sprintf("           funded tracts whose 90%% interval crosses the cutoff: %d\n",
                m$funded_interval_crosses))
  }
}

## ---------------------------------------------------------------------------
## AUDIT ITEM 4: the covariance decomposition, now identified.
## Previously the gap between "replicate" and "independent" was attributed to
## cross-tract covariance, but the comparison removed every covariance at once.
## The within_tract design removes ONLY the cross-tract term, so:
##     replicate vs within_tract  = the cross-tract contribution
##     within_tract vs no_cov     = the within-tract contribution
## ---------------------------------------------------------------------------
hdr("3. WHERE THE EXTRA DISPERSION COMES FROM (identified, three designs)")
W <- dcast(res[is.finite(rpl0), .(FIPS, design, sd_rpl)], FIPS ~ design, value.var = "sd_rpl")
cat(sprintf("\n  median SD   replicate %.4f | within_tract %.4f | no_cov %.4f\n",
            median(W$replicate), median(W$within_tract), median(W$no_cov)))
for (nm in c("replicate", "within_tract", "no_cov")) {
  x <- res[design == nm & is.finite(rpl0)]
  cat(sprintf("  %%tracts with a >40-point 90%% interval, %-13s: %5.1f%%\n",
              nm, 100*mean(x$hi90 - x$lo90 > .40)))
}
cat(sprintf("\n  per-tract SD ratio replicate/within_tract: p10=%.2f median=%.2f p90=%.2f  <- cross-tract term\n",
            quantile(W$replicate/W$within_tract, .10), median(W$replicate/W$within_tract),
            quantile(W$replicate/W$within_tract, .90)))
cat(sprintf("  per-tract SD ratio within_tract/no_cov  : p10=%.2f median=%.2f p90=%.2f  <- within-tract term\n",
            quantile(W$within_tract/W$no_cov, .10), median(W$within_tract/W$no_cov),
            quantile(W$within_tract/W$no_cov, .90)))
cat(sprintf("  per-tract SD ratio replicate/no_cov     : p10=%.2f median=%.2f p90=%.2f  <- both together\n",
            quantile(W$replicate/W$no_cov, .10), median(W$replicate/W$no_cov),
            quantile(W$replicate/W$no_cov, .90)))
cat(sprintf("  tracts where no_cov understates the replicate SD by >25%%: %d (%.1f%%)\n",
            sum(W$replicate/W$no_cov > 1.25), 100*mean(W$replicate/W$no_cov > 1.25)))

hdr("4. SENSITIVITY: the boundary clamps")
cat(sprintf("\n  median SD  full clamp %.4f  vs minimal clamp %.4f  (ratio %.3f)\n",
            median(W$replicate), median(W$replicate_minclamp),
            median(W$replicate)/median(W$replicate_minclamp)))
for (tau in THRESH) {
  a <- churn_metrics(res[design == "replicate"          & is.finite(rpl0)], tau)
  b <- churn_metrics(res[design == "replicate_minclamp" & is.finite(rpl0)], tau)
  cat(sprintf("  top %2d%% leaver rate: full clamp %.3f  vs minimal clamp %.3f\n",
              round(100*(1-tau)), a$leaver_rate, b$leaver_rate))
}

hdr("5. ASSUMPTION-FREE CHECK: the 80 published replicates, no Gaussian step")
sdr <- s$sd_rep80[is.finite(rpl0)]
sdg <- res[design == "replicate" & is.finite(rpl0)]$sd_rpl
cat(sprintf("\n  median SD of RPL_THEMES from the 80 replicates directly : %.4f\n", median(sdr, na.rm=TRUE)))
cat(sprintf("  median SD of RPL_THEMES from %d Gaussian draws           : %.4f\n", B, median(sdg)))
cat(sprintf("  ratio (Gaussian / direct) = %.3f;  correlation across tracts = %.3f\n",
            median(sdg)/median(sdr, na.rm=TRUE), cor(sdr, sdg, use = "complete.obs")))
cat("  80 replicate points give a coarse but model-free variance estimate. Close\n")
cat("  agreement means the Gaussian step is reproducing the replicate spread\n")
cat("  rather than manufacturing it.\n")

saveRDS(list(res = res, churn_metrics = churn_metrics),
        file.path(DIR_WORK, "reliability.rds"))
