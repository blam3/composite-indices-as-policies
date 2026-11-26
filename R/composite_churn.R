#' Decision churn of a thresholded composite index under survey sampling error
#'
#' Resamples the inputs of a composite index from their replicate variance
#' structure, recomputes the index on every draw exactly as the publisher
#' does, and reports how often each unit's funded / not-funded label differs
#' from the published one.
#'
#' Each draw is
#' \deqn{X_b = X_0 + \sqrt{s} \sum_r z_{br} (X_r - X_0),\quad z_{br} \sim N(0,1),}{X_b = X_0 + sqrt(s) * sum_r z_br (X_r - X_0), z_br ~ N(0,1),}
#' with one \eqn{z_b} shared by every unit and component, so the draw keeps
#' the covariance the replicates carry: numerator with its own denominator,
#' across components of the same unit, and across units. Its marginal
#' variance is the replicate variance \eqn{s \sum_r (X_r - X_0)^2}. Negative
#' draws are floored at zero and a numerator is capped at its denominator
#' (`clamp = TRUE`). The index is then recomputed in full, rounding and
#' re-ranking included, because the policy acts on published numbers.
#'
#' @param num,den Numeric arrays `[unit x component x (1 + R)]`. Slice 1 holds
#'   the point estimates, slices `2:(R + 1)` the `R` replicate estimates.
#'   Component `j` contributes the percentage `100 * num[, j] / den[, j]` to
#'   variable `spec$comp_var[j]`. Row names, if present, label the units. For
#'   an input that is not a ratio, pass `den` filled with 100 and
#'   `clamp = FALSE`.
#' @param spec A list describing the composite:
#'   \describe{
#'     \item{`comp_var`}{Required. Character, one entry per component: the
#'       variable it feeds. A variable fed by several components is the sum of
#'       their percentages.}
#'     \item{`themes`}{Named list of character vectors grouping the variables.
#'       Variables are summed within a theme, themes are summed into the
#'       overall score. Default: one theme holding every variable.}
#'     \item{`normalize`}{Function applied to each variable's column. Default:
#'       the CDC percentile rank `(min_rank - 1) / (n_valid - 1)` over units
#'       with a finite value.}
#'     \item{`weights`}{Named numeric, one per variable, applied after
#'       normalisation. Default `NULL` (unit weights; the sums are unweighted).}
#'     \item{`aggregate`}{`"rank"` (default) thresholds the percentile rank of
#'       the overall score, as SVI does; `"sum"` thresholds the score itself.}
#'     \item{`threshold`}{Numeric vector. A unit is funded when its score is
#'       `>= threshold`. Default `0.9` (top decile under `"rank"`).}
#'     \item{`cdc_rounding`}{Logical, default `TRUE`: round component
#'       percentages half away from zero to 1 decimal, and normalised values,
#'       sums and ranks to 4 decimals, as CDC/ATSDR SVI 2022 does.}
#'   }
#' @param B Number of draws.
#' @param scale Replicate variance multiplier `s`. The default `4 / R` is the
#'   successive-difference replication factor of the ACS variance replicate
#'   tables (`R = 80`).
#' @param clamp Floor negative draws at zero and cap numerators at their
#'   denominators.
#'
#' @return A data frame, one row per unit with a finite published score and
#'   per threshold: `unit`, `threshold`, `score0` (published score),
#'   `funded0` (published label), `p_funded`, `p_leave` (P(not funded), for
#'   published-funded units, else 0), `p_enter` (P(funded), for
#'   published-unfunded units, else 0), `p_change` (P(label differs from
#'   published)) and `n_draws` (draws in which the unit had a finite score).
#'   Attribute `"churn"` holds one row per threshold with `n_funded`,
#'   `expected_leavers`, `leaver_rate`, `expected_entrants` and
#'   `expected_label_changes`. Report leavers and entrants separately: their
#'   sum is the symmetric difference of the two funded sets and counts every
#'   replacement twice, so it must not be divided by `n_funded`.
#'
#' @examples
#' set.seed(1)
#' n <- 50; R <- 80
#' den <- array(1000, c(n, 2, R + 1))
#' num <- array(rbinom(n * 2 * (R + 1), 1000, 0.2), c(n, 2, R + 1))
#' out <- composite_churn(num, den, list(comp_var = c("a", "b")), B = 50)
#' attr(out, "churn")
#' @export
composite_churn <- function(num, den, spec, B = 1000L,
                            scale = 4 / (dim(num)[3] - 1L), clamp = TRUE) {
  stopifnot(is.array(num), length(dim(num)) == 3L, identical(dim(num), dim(den)),
            dim(num)[3] >= 2L, is.list(spec), length(spec$comp_var) == dim(num)[2],
            B >= 1)
  cv     <- spec$comp_var
  themes <- if (is.null(spec$themes)) list(all = unique(cv)) else spec$themes
  vars   <- unlist(themes, use.names = FALSE)
  stopifnot(!anyDuplicated(vars), setequal(vars, cv), !is.null(names(themes)))
  if (!is.null(spec$weights)) stopifnot(all(vars %in% names(spec$weights)))
  normalize <- if (is.null(spec$normalize)) pctrank else spec$normalize
  agg   <- match.arg(spec$aggregate, c("rank", "sum"))
  taus  <- if (is.null(spec$threshold)) 0.9 else spec$threshold
  cdc   <- if (is.null(spec$cdc_rounding)) TRUE else isTRUE(spec$cdc_rounding)

  score <- function(N, D) {
    r <- svi_rank(svi_ep(N, D, cv, round_components = cdc, vars = vars),
                  round_out = cdc, themes = themes, normalize = normalize,
                  weights = spec$weights)
    if (agg == "rank") r$RPL_THEMES else r$SPL_THEMES
  }

  ## The draw loop below is the "replicate" design of
  ## analysis/louisiana/code/05_replicate_simulation.R, moved unchanged.
  storage.mode(num) <- "double"; storage.mode(den) <- "double"
  nt <- dim(num)[1]; nc <- dim(num)[2]; R <- dim(num)[3] - 1L
  N0 <- num[, , 1]; D0 <- den[, , 1]
  dN <- num[, , 1 + seq_len(R), drop = FALSE] - array(N0, dim = c(nt, nc, R))
  dD <- den[, , 1 + seq_len(R), drop = FALSE] - array(D0, dim = c(nt, nc, R))
  fN <- matrix(dN, nrow = nt * nc, ncol = R)
  fD <- matrix(dD, nrow = nt * nc, ncol = R)
  rm(dN, dD)
  cf <- sqrt(scale)

  s0 <- score(N0, D0)
  M  <- matrix(NA_real_, B, nt)
  for (b in seq_len(B)) {
    z  <- stats::rnorm(R)
    Nb <- N0 + matrix(cf * (fN %*% z), nt, nc)
    Db <- D0 + matrix(cf * (fD %*% z), nt, nc)
    if (clamp) {
      Nb[Nb < 0] <- 0; Db[Db < 0] <- 0
      Nb <- pmin(Nb, Db)                    # a subset cannot exceed its universe
    }
    M[b, ] <- score(Nb, Db)
  }

  ## Per-unit probabilities and the three churn quantities, as in
  ## analysis/louisiana/code/07_decision_reliability.R (summarise_design() and
  ## churn_metrics()). Draws in which a unit has no score are dropped for that
  ## unit only.
  units <- if (is.null(rownames(N0))) seq_len(nt) else rownames(N0)
  ok <- is.finite(s0)
  per_tau <- lapply(taus, function(tau) {
    fund_b <- M >= tau
    a0 <- s0 >= tau
    p  <- colMeans(fund_b, na.rm = TRUE)
    fl <- colMeans(sweep(fund_b, 2, a0, `!=`), na.rm = TRUE)
    data.frame(unit = units[ok], threshold = tau, score0 = s0[ok],
               funded0 = a0[ok], p_funded = p[ok],
               p_leave = ifelse(a0[ok], 1 - p[ok], 0),
               p_enter = ifelse(a0[ok], 0, p[ok]),
               p_change = fl[ok], n_draws = colSums(is.finite(M))[ok],
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, per_tau)
  attr(out, "churn") <- do.call(rbind, lapply(per_tau, function(d) data.frame(
    threshold              = d$threshold[1],
    n_funded               = sum(d$funded0),
    expected_leavers       = sum(d$p_leave[d$funded0]),
    leaver_rate            = sum(d$p_leave[d$funded0]) / sum(d$funded0),
    expected_entrants      = sum(d$p_enter[!d$funded0]),
    expected_label_changes = sum(d$p_change))))
  out
}
