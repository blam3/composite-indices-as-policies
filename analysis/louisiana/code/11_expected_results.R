## Emit a machine-checkable manifest of every headline number, straight from the
## saved objects, so an auditor can diff rather than read prose.
##
## REVISED 2026-08-19 in response to the independent audit (items 1, 2, 6).
##  - churn is emitted as three separately named quantities (item 1)
##  - reproduction fidelity now includes the missingness-pattern check (item 2)
##  - `deterministic` and `monte_carlo` are separated at the top level so
##    run_all.sh can compare the first group EXACTLY and the second with
##    tolerance (item 2)
##  - the Monte Carlo error note is replaced with something true (item 6)
source(file.path(Sys.getenv("SVI_ROOT", ".."), "code", "00_config.R"))
suppressPackageStartupMessages({library(data.table); library(splines)})
source(file.path(SVI_ROOT, "code", "03_svi_pipeline.R"))
inp  <- readRDS(file.path(DIR_WORK, "svi_inputs.rds"))
s    <- readRDS(file.path(DIR_WORK, "sim.rds"))
relL <- readRDS(file.path(DIR_WORK, "reliability.rds"))
rel  <- relL$res
churn_metrics <- relL$churn_metrics
P    <- readRDS(file.path(DIR_WORK, "precision.rds"))
INF  <- readRDS(file.path(DIR_WORK, "inference.rds"))
V4   <- readRDS(file.path(DIR_WORK, "reference_run.rds"))
cdc  <- fread(F_CDC, showProgress=FALSE, colClasses=list(character="FIPS"))
setnames(cdc, names(cdc), sub("^﻿","",names(cdc)))
keep <- match(cdc$FIPS, inp$fips)

rp  <- rel[design=="replicate"    & is.finite(rpl0)]
wt  <- rel[design=="within_tract" & is.finite(rpl0)]
nc_ <- rel[design=="no_cov"       & is.finite(rpl0)]
mcl <- rel[design=="replicate_minclamp" & is.finite(rpl0)]
epa <- rel[design=="ep_actual"    & is.finite(rpl0)]
epq <- rel[design=="ep_equalised" & is.finite(rpl0)]

d <- as.data.table(P$d); seEP <- P$seEP; m <- match(d$FIPS, s$cdc$FIPS)
qp <- cut(d$EP_POV150, quantile(d$EP_POV150, 0:5/5), include.lowest=TRUE, labels=1:5)
seratio <- sapply(SVI_VARS, function(v){
  a <- tapply(seEP[m, v], qp, mean, na.rm=TRUE); unname(a[5]/a[1]) })

z <- function(x)(x-mean(x))/sd(x)
f0 <- lm(sd_rpl ~ ns(rpl0,6), data=d)
f1 <- lm(sd_rpl ~ ns(rpl0,6)+z(EP_POV150)+z(EP_MINRTY)+z(log(E_TOTPOP)), data=d)
fA <- lm(sd_rpl ~ z(EP_POV150)+z(EP_MINRTY)+z(EP_NOHSDP)+z(log(E_TOTPOP))+z(log(E_TOTPOP/AREA_SQMI)), data=d)
gg <- glm(flip_10 ~ ns(abs(rpl0-.90),5)+z(EP_POV150)+z(EP_MINRTY)+z(EP_NOHSDP)+z(log(E_TOTPOP))+z(log(E_TOTPOP/AREA_SQMI)),
          family=quasibinomial(), weights=rep(s$B,nrow(d)), data=d)

rs <- function(x) list(median_sd=median(x$sd_rpl), median_ci90_width=median(x$hi90-x$lo90),
                       frac_ci90_gt_20pts=mean(x$hi90-x$lo90 > .20),
                       frac_ci90_gt_40pts=mean(x$hi90-x$lo90 > .40))
cm <- function(x) lapply(list(top_decile=.90, top_quintile=.80, top_quartile=.75),
                         function(tau) churn_metrics(x, tau))

## --- Monte Carlo error, done properly (audit item 6) -----------------------
## The per-tract flip probability is a mean over B DRAWS, and draws ARE
## independent of one another (a fresh z_b every iteration). So 0.5/sqrt(B) is
## an UPPER bound on a per-tract MC standard error, attained at p = 0.5, not a
## lower bound as previously claimed -- but it only applies to a tract that
## retained all B draws, and a tract that lost draws to a zero denominator has
## fewer. Both are reported.
## Cross-tract AGGREGATES are a different matter: within a draw every tract
## shares one z_b, so the leaver total is one correlated sum per draw. Its MC
## error is estimated by block variation ACROSS draws.
retained <- rp$retained
B <- s$B
M   <- s$sim_rep$rpl
idx <- match(rp$FIPS, s$fips)
a0  <- rp$rpl0 >= .90
lv_by_draw <- rowSums(!(M[, idx, drop=FALSE][, a0, drop=FALSE] >= .90), na.rm = TRUE)
K <- 10L
blk <- split(seq_len(B), cut(seq_len(B), K, labels = FALSE))
lv_blocks <- vapply(blk, function(ix) mean(lv_by_draw[ix]), numeric(1))
mc <- list(
  per_tract_flip_se_upper_bound = 0.5/sqrt(B),
  retained_draws_min = min(retained), retained_draws_median = median(retained),
  retained_draws_max = max(retained),
  per_tract_flip_se_worst_case_retained = 0.5/sqrt(min(retained)),
  expected_leavers_top_decile = mean(lv_by_draw),
  expected_leavers_mc_se_blocked = sd(lv_blocks)/sqrt(K),
  expected_leavers_mc_se_naive_iid = sd(lv_by_draw)/sqrt(B),
  n_blocks = K,
  note = paste("0.5/sqrt(B) is an UPPER bound on a per-tract Monte Carlo SE for a tract",
               "retaining all B draws (draws are iid; the shared z is WITHIN a draw, across",
               "tracts, not across draws). Tracts losing draws to a zero denominator have a",
               "larger bound, given here. For cross-tract aggregates such as the expected",
               "leaver count, tracts within a draw are correlated, so the MC SE is estimated",
               "by variation across blocks of draws; the iid figure is shown for contrast.")
)

deterministic <- list(
  meta = list(state="Louisiana", state_fips="22", acs="2018-2022 5-year VRT, summary level 140",
              svi_edition="CDC/ATSDR SVI 2022",
              n_tracts_vrt=length(inp$fips), n_tracts_cdc=nrow(cdc),
              n_tracts_dropped_water=length(inp$fips)-nrow(cdc), n_components=ncol(inp$NUM),
              n_svi_inputs=length(SVI_VARS)),
  reproduction = list(values_compared=V4$values_compared, values_exact=V4$values_exact,
                      pct_exact=100*V4$values_exact/V4$values_compared,
                      cells_compared=V4$cells_compared,
                      missingness_match=V4$missingness_match,
                      values_ok=V4$values_ok, missing_ok=V4$missing_ok),
  se_ratio_povQ5_over_povQ1 = as.list(round(seratio,4))
)

monte_carlo <- list(
  meta = list(B_draws=s$B, seed=20260818, R_version=R.version.string,
              designs=names(relL$res[, unique(design)])),
  rank_stability = list(replicate=rs(rp), within_tract=rs(wt), no_cov=rs(nc_),
                        replicate_minclamp=rs(mcl), ep_actual=rs(epa), ep_equalised=rs(epq)),
  decisions_replicate          = cm(rp),
  decisions_within_tract       = list(top_decile=churn_metrics(wt, .90)),
  decisions_no_cov             = list(top_decile=churn_metrics(nc_, .90)),
  decisions_replicate_minclamp = list(top_decile=churn_metrics(mcl, .90)),
  covariance_decomposition = list(
    median_sd_replicate    = median(rp$sd_rpl),
    median_sd_within_tract = median(wt$sd_rpl),
    median_sd_no_cov       = median(nc_$sd_rpl),
    ratio_crosstract_term  = median(rp$sd_rpl)/median(wt$sd_rpl),
    ratio_withintract_term = median(wt$sd_rpl)/median(nc_$sd_rpl),
    frac_gt40_replicate    = mean(rp$hi90-rp$lo90 > .40),
    frac_gt40_within_tract = mean(wt$hi90-wt$lo90 > .40),
    frac_gt40_no_cov       = mean(nc_$hi90-nc_$lo90 > .40)),
  equalisation_experiment = list(
    median_sd_ep_actual    = median(epa$sd_rpl),
    median_sd_ep_equalised = median(epq$sd_rpl),
    r2_rankposition_actual    = summary(lm(sd_actual ~ ns(rpl0,6), data=as.data.table(P$equalisation)))$r.squared,
    r2_rankposition_equalised = summary(lm(sd_equal  ~ ns(rpl0,6), data=as.data.table(P$equalisation)))$r.squared,
    decile_profile_correlation = local({
      E <- as.data.table(P$equalisation); q <- cut(E$rpl0, seq(0,1,.1), include.lowest=TRUE)
      cor(as.numeric(tapply(E$sd_actual,q,mean)), as.numeric(tapply(E$sd_equal,q,mean))) })),
  assumption_free_check = list(
    median_sd_from_80_replicates = median(s$sd_rep80[is.finite(s$rpl0)], na.rm=TRUE),
    median_sd_from_gaussian_draws = median(rp$sd_rpl),
    correlation_across_tracts = cor(s$sd_rep80[is.finite(s$rpl0)], rp$sd_rpl, use="complete.obs")),
  subgroup_models = list(
    unconditional_sd_model_r2 = summary(fA)$r.squared,
    unconditional_coefs = as.list(round(coef(fA),6)),
    rank_position_only_r2 = summary(f0)$r.squared,
    rank_position_plus_covariates_r2 = summary(f1)$r.squared,
    conditional_coefs = as.list(round(coef(f1)[!grepl("^ns\\(",names(coef(f1)))],6)),
    flip_glm_odds_ratios = as.list(round(exp(coef(gg)[!grepl("^ns\\(|Intercept",names(coef(gg)))]),4)),
    cor_imprecision_ranksd = cor(d$imprecision, d$sd_rpl),
    partial_cor_given_rank_position = cor(resid(lm(imprecision~ns(rpl0,6),data=d)), resid(lm(sd_rpl~ns(rpl0,6),data=d))),
    inference_note = paste("Coefficients are DESCRIPTIVE associations for Louisiana 2022.",
                           "Naive p-values are not reported; see se_cluster (county-clustered CR1)",
                           "and se_drawblock (block bootstrap over draws) in 08's output."),
    se_drawblock = as.list(round(INF$boot_se[!grepl("^ns\\(", names(INF$boot_se))], 6)),
    se_cluster_flip_glm = as.list(round(setNames(INF$cluster_tab_B[, "se_cluster"],
                                                 rownames(INF$cluster_tab_B)), 6))),
  monte_carlo_error = mc
)

out <- list(deterministic = deterministic, monte_carlo = monte_carlo)
j <- jsonlite::toJSON(out, auto_unbox=TRUE, pretty=TRUE, digits=8)
writeLines(j, file.path(DIR_OUT, "EXPECTED-RESULTS.json"))
cat("wrote", file.path(DIR_OUT, "EXPECTED-RESULTS.json"), "\n")
