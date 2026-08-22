## ---------------------------------------------------------------------------
## 03_svi_pipeline.R -- the CDC/ATSDR SVI 2022 aggregation rule as a function.
##
## Conventions recovered from the published 2022 file and verified exactly:
##   1. Each component percentage is 100*num/den rounded to 1 decimal,
##      half away from zero (SAS ROUND), not R's round-half-to-even.
##   2. A variable's EP is the SUM of its rounded component percentages.
##   3. EPL = (min-rank - 1) / (n_valid - 1), over tracts with a valid EP,
##      rounded to 4 decimals.
##   4. SPL_THEMEk = sum of that theme's EPL; RPL_THEMEk = percentile rank of it.
##   5. SPL_THEMES = sum of the four SPL; RPL_THEMES = percentile rank of it.
##   6. Tracts with a zero denominator are excluded (CDC codes them -999) and
##      are excluded from the rank denominator n_valid.
## ---------------------------------------------------------------------------

SVI_THEMES <- list(
  theme1 = c("POV150","UNEMP","HBURD","NOHSDP","UNINSUR"),
  theme2 = c("AGE65","AGE17","DISABL","SNGPNT","LIMENG"),
  theme3 = c("MINRTY"),
  theme4 = c("MUNIT","MOBILE","CROWD","NOVEH","GROUPQ")
)
SVI_VARS <- unlist(SVI_THEMES, use.names = FALSE)

## SAS-style round half away from zero.
round_sas <- function(x, digits = 1) {
  z <- x * 10^digits
  sign(z) * floor(abs(z) + 0.5 + 1e-9) / 10^digits
}

## CDC percentile rank.
pctrank <- function(x) {
  ok <- is.finite(x); out <- rep(NA_real_, length(x)); n <- sum(ok)
  if (n > 1L) out[ok] <- (rank(x[ok], ties.method = "min") - 1) / (n - 1)
  out
}

## Component percentages -> the 16 EP variables. num/den are [tract x component].
svi_ep <- function(num, den, comp_var, round_components = TRUE) {
  p <- 100 * num / den
  p[!is.finite(p)] <- NA_real_
  if (round_components) p <- round_sas(p, 1)
  EP <- matrix(NA_real_, nrow(p), length(SVI_VARS),
               dimnames = list(rownames(num), SVI_VARS))
  for (v in SVI_VARS) {
    j <- which(comp_var == v)
    EP[, v] <- if (length(j) == 1L) p[, j] else rowSums(p[, j, drop = FALSE])
  }
  ## Summing two 1-decimal components in binary floating point leaves values
  ## that print as equal but do not compare as equal (0.1 + 0.2 != 0.3), which
  ## silently breaks ties in the percentile rank. Re-quantise to 1 decimal.
  if (round_components) EP <- round_sas(EP, 1)
  EP
}

## EP -> the full CDC ranking.
svi_rank <- function(EP, round_out = TRUE) {
  EPL <- apply(EP, 2, pctrank)
  dimnames(EPL) <- dimnames(EP)
  if (round_out) EPL <- round(EPL, 4)
  ## Re-quantise the sums for the same floating-point reason as EP above:
  ## summed 4-decimal ranks must compare equal when they are equal.
  SPL <- sapply(SVI_THEMES, function(v) rowSums(EPL[, v, drop = FALSE]))
  if (round_out) SPL <- round(SPL, 4)
  RPL <- apply(SPL, 2, pctrank)
  SPL_THEMES <- rowSums(SPL)
  if (round_out) SPL_THEMES <- round(SPL_THEMES, 4)
  RPL_THEMES <- pctrank(SPL_THEMES)
  if (round_out) { RPL <- round(RPL, 4); RPL_THEMES <- round(RPL_THEMES, 4) }
  list(EPL = EPL, SPL = SPL, RPL = RPL,
       SPL_THEMES = SPL_THEMES, RPL_THEMES = RPL_THEMES)
}

svi_pipeline <- function(num, den, comp_var, ...) {
  EP <- svi_ep(num, den, comp_var, ...)
  c(list(EP = EP), svi_rank(EP, ...))
}
