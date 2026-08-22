source(file.path(Sys.getenv("SVI_ROOT", ".."), "code", "00_config.R"))
suppressPackageStartupMessages({library(data.table); library(ggplot2); library(splines)})
source(file.path(SVI_ROOT, "code", "03_svi_pipeline.R"))
## REVISED 2026-08-19 (audit items 1 and 5): panel c reported the symmetric
## difference as if it were the share of the funded list that changes, and
## panel b asserted a causal claim the analysis had not tested. Panel c now
## reports the LEAVER RATE; panel b now shows the equalised-precision
## counterfactual from 09 alongside the observed curve.
P <- readRDS(file.path(DIR_WORK, "precision.rds")); d <- as.data.table(P$d); seEP <- P$seEP
s <- readRDS(file.path(DIR_WORK, "sim.rds")); cdc <- s$cdc
relL <- readRDS(file.path(DIR_WORK, "reliability.rds"))
m <- match(d$FIPS, cdc$FIPS)
B <- s$B
cm <- relL$churn_metrics(relL$res[design == "replicate" & is.finite(rpl0)], 0.90)

S1 <- "#2a78d6"; S2 <- "#eb6834"; SURF <- "#fcfcfb"; INK <- "#0b0b0b"; INK2 <- "#52514e"
th <- theme_minimal(base_size = 10) +
  theme(plot.background = element_rect(fill = SURF, colour = NA),
        panel.background = element_rect(fill = SURF, colour = NA),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(colour = "#e6e5e0", linewidth = .3),
        axis.text = element_text(colour = INK2), axis.title = element_text(colour = INK2),
        plot.title = element_text(colour = INK, face = "bold", size = 11),
        plot.subtitle = element_text(colour = INK2, size = 8.5), legend.position = "none")

## (a) regressive input precision -------------------------------------------
qp <- cut(d$EP_POV150, quantile(d$EP_POV150, 0:5/5), include.lowest = TRUE, labels = 1:5)
ra <- data.table(var = SVI_VARS, ratio = sapply(SVI_VARS, function(v) {
  a <- tapply(seEP[m, which(SVI_VARS == v)], qp, mean, na.rm = TRUE); a[5]/a[1] }))
ra[, var := factor(var, levels = var[order(ratio)])]
pa <- ggplot(ra, aes(ratio, var)) +
  geom_vline(xintercept = 1, colour = INK2, linewidth = .4, linetype = "22") +
  geom_segment(aes(x = 1, xend = ratio, yend = var), colour = S1, linewidth = 1.4, lineend = "round") +
  geom_point(colour = S1, size = 2.6) +
  geom_text(aes(label = sprintf("%.2f", ratio),
                hjust = ifelse(ratio >= 1, -0.35, 1.35)), size = 2.6, colour = INK2) +
  scale_x_continuous(limits = c(0.6, 3.5), breaks = c(1, 2, 3)) +
  labs(title = "a. Survey error is larger where deprivation is higher",
       subtitle = "Ratio of mean standard error, highest-poverty vs lowest-poverty quintile of tracts",
       x = "SE ratio (Q5 / Q1)", y = NULL) + th

## (b) rank noise is governed by rank position -------------------------------
EQ <- as.data.table(P$equalisation)
pb <- ggplot(d, aes(rpl0, sd_rpl)) +
  geom_point(colour = S1, alpha = .18, size = .7) +
  geom_smooth(method = "lm", formula = y ~ ns(x, 6), se = FALSE, colour = S2, linewidth = 1) +
  geom_smooth(data = EQ, aes(rpl0, sd_equal), method = "lm", formula = y ~ ns(x, 6),
              se = FALSE, colour = INK, linewidth = .8, linetype = "22") +
  annotate("text", x = .02, y = max(d$sd_rpl) * .98, hjust = 0, size = 2.6, colour = INK,
           label = "dashed: input precision equalised across tracts") +
  labs(title = "b. The shape belongs to rank position",
       subtitle = "Equalising input precision across tracts barely moves the curve (dashed)",
       x = "Published overall SVI percentile (RPL_THEMES)",
       y = sprintf("SD of percentile across %s draws", format(B, big.mark = ","))) + th

## (c) decision reliability ---------------------------------------------------
d[, funded := rpl0 >= 0.90]
pc <- ggplot(d, aes(rpl0, p_fund_10, colour = funded)) +
  geom_hline(yintercept = c(.1, .9), colour = "#e6e5e0", linewidth = .4) +
  geom_vline(xintercept = .90, colour = INK2, linewidth = .4, linetype = "22") +
  geom_point(alpha = .5, size = .8) +
  scale_colour_manual(values = c(`FALSE` = S1, `TRUE` = S2)) +
  annotate("text", x = .40, y = .97, hjust = 0, size = 2.7, colour = S2,
           label = sprintf("funded on the published index (n = %d)", sum(d$funded))) +
  annotate("text", x = .40, y = .88, hjust = 0, size = 2.7, colour = S1,
           label = sprintf("not funded (n = %d)", sum(!d$funded))) +
  labs(title = sprintf("c. %.0f%% of the funded list would fall off on a resample",
                       100 * cm$leaver_rate),
       subtitle = sprintf("P(top decile) over %s draws: %.1f leavers, %.1f entrants, %.1f label changes",
                          format(B, big.mark = ","), cm$expected_leavers, cm$expected_entrants,
                          cm$expected_label_changes),
       x = "Published overall SVI percentile", y = "P(in top decile)") + th

## (d) caterpillar for the funded set ----------------------------------------
f <- d[funded == TRUE][order(rpl0)][, i := .I]
pd <- ggplot(f, aes(i, rpl0)) +
  geom_linerange(aes(ymin = lo90, ymax = hi90), colour = S1, alpha = .45, linewidth = .5) +
  geom_point(size = .6, colour = INK) +
  geom_hline(yintercept = .90, colour = S2, linewidth = .5) +
  annotate("text", x = 4, y = .885, hjust = 0, size = 2.7, colour = S2, label = "top-decile cutoff") +
  labs(title = "d. Every funded tract, with its 90% interval",
       subtitle = sprintf("%d of %d funded tracts have an interval crossing the cutoff",
                          sum(f$lo90 < .90), nrow(f)),
       x = "Funded tracts, ordered by published percentile", y = "Overall SVI percentile") + th

g <- gridExtra::arrangeGrob(pa, pb, pc, pd, ncol = 2)
ggsave(file.path(DIR_OUT, "svi_decision_reliability.png"), g, width = 11, height = 8.2, dpi = 200, bg = SURF)
cat("wrote", file.path(DIR_OUT, "svi_decision_reliability.png"), "\n")
