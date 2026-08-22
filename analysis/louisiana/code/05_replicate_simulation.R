## ---------------------------------------------------------------------------
## 05_replicate_simulation.R
## WP1: how much of the SVI ranking is ACS survey noise?
##
## REVISED 2026-08-19 in response to the independent audit (items 4 and 5).
## The previous version ran two designs and attributed the gap between them to
## cross-tract covariance. That attribution was not identified: the comparison
## design removed *every* source of covariance at once. It also applied two
## non-linear boundary clamps without measuring how often they fired, and it
## defended the "the ranking step flattens subgroup differences in precision"
## claim with a regression adjustment rather than an experiment.
##
## Six designs now run. Four operate on counts; two operate directly on the
## sixteen estimated percentages so that input precision can be manipulated.
##
##  COUNT-LEVEL, all sharing the Gaussian model
##      X_b = X_0 + (2/sqrt(80)) * sum_r z_br (X_r - X_0),   z_br ~ N(0,1)
##  whose marginal variance is by construction the successive-difference-
##  replication variance the Census Bureau publishes.
##
##   (1) "replicate"      one z_b per DRAW, shared by every tract. Preserves
##                        within-tract cross-variable covariance AND cross-tract
##                        covariance (replicate r is a common perturbation of the
##                        whole sample).
##   (2) "within_tract"   one z_bt per TRACT per draw. Preserves within-tract
##                        cross-variable and numerator/denominator covariance;
##                        removes cross-tract covariance ONLY. This is the design
##                        the audit correctly said was missing: (1) vs (2)
##                        isolates the cross-tract term, (2) vs (3) isolates the
##                        within-tract term.
##   (3) "no_cov"         independent components with matched marginal SEs.
##                        Formerly and misleadingly called "independent"; it
##                        removes numerator/denominator, cross-variable and
##                        cross-tract covariance simultaneously.
##   (4) "replicate_minclamp"  design (1) with the boundary treatment relaxed to
##                        the minimum needed to keep a ratio defined (denominator
##                        floored at zero; numerator neither floored at zero nor
##                        capped at its denominator). Sensitivity analysis for the
##                        two non-linear clamps.
##
##  EP-LEVEL, a matched pair that answers "does the ranking step flatten it?"
##   (5) "ep_actual"      perturb the sixteen EP directly, using EP-level
##                        replicate deviations, shared z. Reproduces (1) closely
##                        and is the control for (6).
##   (6) "ep_equalised"   identical, except every tract's EP-level SE is rescaled
##                        to the cross-tract MEDIAN SE for that variable, so
##                        input precision is equal for every tract by
##                        construction. If the rank-SD-versus-rank-position curve
##                        is unchanged, the inverted U is mechanical and the
##                        flattening claim is an experimental result rather than
##                        a regression story.
##
## Also computed, with no Gaussian step at all: the pipeline evaluated on each of
## the 80 published replicate estimates. 80 points is coarse, but it is
## assumption-free, and it is the only check available on the Gaussian model.
##
## The full CDC pipeline (component rounding included) is re-run on every draw,
## because the policy operates on published, rounded, re-ranked numbers.
## ---------------------------------------------------------------------------
source(file.path(Sys.getenv("SVI_ROOT", ".."), "code", "00_config.R"))
suppressPackageStartupMessages({library(data.table)})
source(file.path(SVI_ROOT, "code", "03_svi_pipeline.R"))

B <- as.integer(Sys.getenv("SVI_B", "5000"))
RNGkind("Mersenne-Twister", "Inversion", "Rejection")
set.seed(20260818)

inp <- readRDS(file.path(DIR_WORK, "svi_inputs.rds"))
cdc <- fread(F_CDC, showProgress = FALSE,
             colClasses = list(character = "FIPS"))
setnames(cdc, names(cdc), sub("^﻿", "", names(cdc)))
keep <- match(cdc$FIPS, inp$fips)

NUM <- inp$NUM[keep, , , drop = FALSE]
DEN <- inp$DEN[keep, , , drop = FALSE]
cv  <- inp$comp_var
nt  <- nrow(NUM); nc <- ncol(NUM); R <- 80L

## Point estimates and replicate deviations.
N0 <- NUM[, , 1]; D0 <- DEN[, , 1]
dN <- NUM[, , 2:81, drop = FALSE] - array(N0, dim = c(nt, nc, R))
dD <- DEN[, , 2:81, drop = FALSE] - array(D0, dim = c(nt, nc, R))

## Successive-difference-replication standard errors (the marginal SEs).
seN <- sqrt(pmax(0, (4 / R) * apply(dN^2, c(1, 2), sum)))
seD <- sqrt(pmax(0, (4 / R) * apply(dD^2, c(1, 2), sum)))

## Flatten deviations to [tract*component, R] for fast draws.
fN <- matrix(dN, nrow = nt * nc, ncol = R)
fD <- matrix(dD, nrow = nt * nc, ncol = R)
rm(dN, dD); invisible(gc())

ref <- svi_pipeline(N0, D0, cv)
rpl0 <- ref$RPL_THEMES
rank0 <- ref$RPL

## ---------------------------------------------------------------------------
## AUDIT item 4: boundary-clamp instrumentation.
## Every clamp is counted, in total and per tract, so the write-up can state how
## often the non-linearity fires rather than asserting that it is harmless.
## `dropped` counts tracts that lose a valid overall percentile in a draw --
## a zero denominator removes the tract and shifts everyone else's rank.
## ---------------------------------------------------------------------------
new_counters <- function() list(
  n_num_cells = 0, n_den_cells = 0,
  neg_num = 0, neg_den = 0, capped_num = 0,
  neg_num_by_tract = numeric(nt), capped_num_by_tract = numeric(nt),
  draws_with_a_drop = 0L, dropped_by_tract = numeric(nt),
  n_valid_min = Inf, n_valid_max = -Inf,
  near_round_boundary = 0, n_ep_cells = 0
)

run_design <- function(design, clamp = c("full", "minimal")) {
  clamp <- match.arg(clamp)
  out_rpl <- matrix(NA_real_, B, nt)
  ct <- new_counters()
  cf <- 2 / sqrt(R)
  pb <- max(1L, B %/% 10L)
  for (b in seq_len(B)) {
    if (design == "replicate") {
      z  <- rnorm(R)
      Nb <- N0 + matrix(cf * (fN %*% z), nt, nc)
      Db <- D0 + matrix(cf * (fD %*% z), nt, nc)
    } else if (design == "within_tract") {
      ## One independent z per tract per draw: [nt x R] of standard normals.
      ## Deviations are [tract*component x R] in tract-major order, so the
      ## per-tract z must be recycled across that tract's components.
      Z  <- matrix(rnorm(nt * R), nt, R)
      Zc <- Z[rep(seq_len(nt), times = nc), , drop = FALSE]   # [tract*comp x R]
      Nb <- N0 + matrix(cf * rowSums(fN * Zc), nt, nc)
      Db <- D0 + matrix(cf * rowSums(fD * Zc), nt, nc)
    } else {                                                   # "no_cov"
      Nb <- N0 + seN * matrix(rnorm(nt * nc), nt, nc)
      Db <- D0 + seD * matrix(rnorm(nt * nc), nt, nc)
    }

    ct$n_num_cells <- ct$n_num_cells + length(Nb)
    ct$n_den_cells <- ct$n_den_cells + length(Db)
    negN <- Nb < 0; negD <- Db < 0
    ct$neg_num <- ct$neg_num + sum(negN)
    ct$neg_den <- ct$neg_den + sum(negD)
    ct$neg_num_by_tract <- ct$neg_num_by_tract + rowSums(negN)

    if (clamp == "full") {
      Nb[negN] <- 0; Db[negD] <- 0
      cap <- Nb > Db
      ct$capped_num <- ct$capped_num + sum(cap)
      ct$capped_num_by_tract <- ct$capped_num_by_tract + rowSums(cap)
      Nb <- pmin(Nb, Db)                    # a subset cannot exceed its universe
    } else {
      ## Minimal: only the denominator floor, which a ratio cannot do without.
      ## Percentages are then free to go negative or exceed 100.
      Db[negD] <- 0
      ct$capped_num <- ct$capped_num + sum(Nb > Db)
    }

    r <- svi_pipeline(Nb, Db, cv)
    ## How near are the simulated percentages to a rounding boundary? The
    ## round_sas() epsilon is 1e-9; this counts cells it could plausibly move.
    p <- 100 * Nb / Db
    p <- p[is.finite(p)]
    ct$near_round_boundary <- ct$near_round_boundary +
      sum(abs(abs(p * 10) %% 1 - 0.5) < 1e-8)
    ct$n_ep_cells <- ct$n_ep_cells + length(p)

    out_rpl[b, ] <- r$RPL_THEMES
    nv <- sum(is.finite(r$RPL_THEMES))
    ct$n_valid_min <- min(ct$n_valid_min, nv); ct$n_valid_max <- max(ct$n_valid_max, nv)
    lost <- is.finite(rpl0) & !is.finite(r$RPL_THEMES)
    if (any(lost)) { ct$draws_with_a_drop <- ct$draws_with_a_drop + 1L
                     ct$dropped_by_tract <- ct$dropped_by_tract + lost }
    if (b %% pb == 0) cat(sprintf("  %-20s %5.1f%%\n", design, 100 * b / B))
  }
  ct$retained_draws <- colSums(is.finite(out_rpl))
  list(rpl = out_rpl, counters = ct)
}

## ---------------------------------------------------------------------------
## EP-level designs. Deviations are taken at the level of the sixteen published
## percentages, which is where "input precision" is defined, so precision can be
## equalised across tracts without touching the correlation structure.
## ---------------------------------------------------------------------------
EPall <- lapply(1:81, function(k) svi_ep(inp$NUM[keep, , k], inp$DEN[keep, , k], cv))
EP0   <- EPall[[1]]
nv_ep <- ncol(EP0)
dEP   <- array(NA_real_, dim = c(nt, nv_ep, R), dimnames = list(NULL, colnames(EP0), NULL))
for (k in seq_len(R)) dEP[, , k] <- EPall[[k + 1]] - EP0
rm(EPall); invisible(gc())
seEP  <- (4 / R) * apply(dEP^2, c(1, 2), sum)
seEP[] <- sqrt(pmax(0, seEP))            # pmax() drops dim(); assign back in place
dimnames(seEP) <- list(NULL, colnames(EP0))

## Rescale each tract's deviations so its SE equals the cross-tract median for
## that variable. Tracts with zero SE (a degenerate estimate) are left alone.
med_se <- apply(seEP, 2, median, na.rm = TRUE)
scl <- sweep(seEP, 2, med_se, function(s, m) ifelse(is.finite(s) & s > 0, m / s, 1))
scl[!is.finite(scl)] <- 1
dEP_eq <- dEP * array(scl, dim = dim(dEP))

run_ep_design <- function(dev) {
  fE <- matrix(dev, nrow = nt * nv_ep, ncol = R)
  out_rpl <- matrix(NA_real_, B, nt)
  cf <- 2 / sqrt(R); pb <- max(1L, B %/% 10L)
  for (b in seq_len(B)) {
    z  <- rnorm(R)
    Eb <- EP0 + matrix(cf * (fE %*% z), nt, nv_ep, dimnames = dimnames(EP0))
    ## Percentages are bounded; MINRTY and the rest live on [0, 100].
    Eb[Eb < 0] <- 0; Eb[Eb > 100] <- 100
    Eb <- round_sas(Eb, 1)
    out_rpl[b, ] <- svi_rank(Eb)$RPL_THEMES
    if (b %% pb == 0) cat(sprintf("  %-20s %5.1f%%\n", "ep design", 100 * b / B))
  }
  list(rpl = out_rpl, counters = list(retained_draws = colSums(is.finite(out_rpl))))
}

cat(sprintf("B = %d draws, %d tracts, %d count components, %d EP variables\n",
            B, nt, nc, nv_ep))
tm <- function(lab, expr) { t0 <- Sys.time(); v <- force(expr)
  cat(sprintf("%-22s %s\n", lab, format(Sys.time() - t0))); v }

sim_rep   <- tm("replicate",          run_design("replicate"))
sim_wit   <- tm("within_tract",       run_design("within_tract"))
sim_ind   <- tm("no_cov",             run_design("no_cov"))
sim_mcl   <- tm("replicate_minclamp", run_design("replicate", clamp = "minimal"))
sim_epa   <- tm("ep_actual",          run_ep_design(dEP))
sim_epq   <- tm("ep_equalised",       run_ep_design(dEP_eq))

## ---------------------------------------------------------------------------
## Assumption-free check: the pipeline on the 80 published replicates themselves.
## No Gaussian step, no clamping. Coarse (80 points) but model-free.
## ---------------------------------------------------------------------------
rpl_rep80 <- t(vapply(2:81, function(k)
  svi_pipeline(inp$NUM[keep, , k], inp$DEN[keep, , k], cv)$RPL_THEMES,
  numeric(nt)))
## Fay-BRR scaling: SD of the estimator is 2/sqrt(80) * sqrt(sum of squared devs)
sd_rep80 <- sqrt(pmax(0, (4 / R) *
  colSums((rpl_rep80 - matrix(rpl0, R, nt, byrow = TRUE))^2, na.rm = TRUE)))
sd_rep80[!is.finite(rpl0)] <- NA_real_

saveRDS(list(fips = cdc$FIPS, B = B, rpl0 = rpl0, rank0 = rank0,
             ref = ref, seN = seN, seD = seD, seEP = seEP, comp_var = cv,
             sim_rep = sim_rep, sim_wit = sim_wit, sim_ind = sim_ind,
             sim_mcl = sim_mcl, sim_epa = sim_epa, sim_epq = sim_epq,
             sd_rep80 = sd_rep80,
             cdc = cdc[, .(FIPS, E_TOTPOP, EP_POV150, EP_MINRTY, EP_NOHSDP, EP_AGE65,
                           E_HH, E_HU, AREA_SQMI, COUNTY, RPL_THEMES)]),
        file.path(DIR_WORK, "sim.rds"))
cat("Saved work/sim.rds\n")

## ---------------------------------------------------------------------------
## Boundary-treatment report (audit item 4, point 4).
## ---------------------------------------------------------------------------
hdr <- function(x) cat("\n", strrep("=", 78), "\n", x, "\n", strrep("=", 78), "\n", sep = "")
hdr("BOUNDARY TREATMENT: how often the non-linear clamps fire")
for (nm in c("replicate", "within_tract", "no_cov", "replicate_minclamp")) {
  ct <- switch(nm, replicate = sim_rep, within_tract = sim_wit,
               no_cov = sim_ind, replicate_minclamp = sim_mcl)$counters
  cat(sprintf("\n[%s]\n", nm))
  cat(sprintf("  numerator cells drawn negative : %12.0f of %12.0f (%.3f%%)\n",
              ct$neg_num, ct$n_num_cells, 100 * ct$neg_num / ct$n_num_cells))
  cat(sprintf("  denominator cells drawn negative: %12.0f of %12.0f (%.4f%%)\n",
              ct$neg_den, ct$n_den_cells, 100 * ct$neg_den / ct$n_den_cells))
  cat(sprintf("  numerator > denominator         : %12.0f (%.4f%%)\n",
              ct$capped_num, 100 * ct$capped_num / ct$n_num_cells))
  cat(sprintf("  draws losing >=1 valid tract    : %d of %d;  valid tracts per draw %d-%d\n",
              ct$draws_with_a_drop, B, ct$n_valid_min, ct$n_valid_max))
  rd <- ct$retained_draws[is.finite(rpl0)]   # tracts CDC publishes a value for
  cat(sprintf("  retained draws per published tract: min %d, median %d, max %d\n",
              min(rd), as.integer(median(rd)), max(rd)))
  cat(sprintf("  simulated percentages within 1e-8 of a .05 rounding boundary: %.0f of %.0f (%.2g%%)\n",
              ct$near_round_boundary, ct$n_ep_cells,
              100 * ct$near_round_boundary / ct$n_ep_cells))
}

cat("\nIs the clamping concentrated where the subgroup claim lives?\n")
pv <- cdc$EP_POV150; q <- cut(pv, quantile(pv, 0:5/5, na.rm = TRUE),
                              include.lowest = TRUE, labels = 1:5)
a <- tapply(sim_rep$counters$neg_num_by_tract / (B * nc), q, mean)
cat(sprintf("  mean per-cell rate of negative numerator draws by poverty quintile:\n"))
cat(sprintf("    Q1=%.4f Q2=%.4f Q3=%.4f Q4=%.4f Q5=%.4f   Q5/Q1=%.2f\n",
            a[1], a[2], a[3], a[4], a[5], a[5]/a[1]))
