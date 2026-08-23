## ---------------------------------------------------------------------------
## verify_line_numbers.R -- check the sixteen ACS line-number mappings in
## 01_build_estimates.R against the PUBLISHED 2018-2022 5-year table shells,
## not against the fact that the pipeline reproduces CDC's file.
##
## Produces every number quoted in docs/wp1-line-number-verification.md.
## Not part of run_all.sh: it is a one-off audit, and it needs the shell file.
##
##   Rscript code/exploratory/verify_line_numbers.R
##
## Four independent checks:
##   A  shell line count == VRT ORDER count, per table
##   B  every parent row in the shell's indent tree == sum of its children,
##      in the actual VRT estimates, for every tract.  This is what pins an
##      ambiguous leaf label ("30 percent or more") to its parent bracket.
##   C  the TITLE the VRT itself carries at every line the code indexes
##   D  the compensating-offset arithmetic for B27001 and B18101
##      (and the denominator-substitution identities)
## ---------------------------------------------------------------------------
source(file.path(Sys.getenv("SVI_ROOT", ".."), "code", "00_config.R"))
suppressPackageStartupMessages(library(data.table))

SHELL_URL <- paste0("https://www2.census.gov/programs-surveys/acs/summary_file/",
                    "2022/table-based-SF/documentation/ACS20225YR_Table_Shells.txt")
SHELL <- file.path(dirname(DIR_RAW), "ACS20225YR_Table_Shells.txt")
if (!file.exists(SHELL)) {
  cat("fetching table shells ->", SHELL, "\n")
  download.file(SHELL_URL, SHELL, quiet = TRUE)
}
sh <- fread(SHELL, sep = "|", header = TRUE, showProgress = FALSE)
setnames(sh, c("tbl", "line", "indent", "uid", "label", "title", "universe", "type"))
sh[, line := as.integer(line)]

TABLES <- c("B01001","B01003","B03002","B11012","B15002","B16005","B18101","B23025",
            "B25003","B25014","B25024","B25044","B25106","B26001","B27001","C17002")

vrt <- function(tb, cols = "ESTIMATE") {
  d <- fread(file.path(DIR_RAW, sprintf("%s_22.csv", tb)),
             select = c("GEOID", "ORDER", "TITLE", cols), showProgress = FALSE)
  d[!is.na(ORDER)]
}
wide <- function(tb, cols = "ESTIMATE") {
  d <- vrt(tb, cols)
  lapply(setNames(cols, cols),
         function(cl) as.matrix(dcast(d, GEOID ~ ORDER, value.var = cl)[, -1]))
}
fail <- 0L
say <- function(ok, fmt, ...) {
  if (!ok) fail <<- fail + 1L
  cat(sprintf("%s %s\n", if (ok) "  ok  " else "  FAIL", sprintf(fmt, ...)))
}

## --- A + B ----------------------------------------------------------------
cat("\n== A: shell line count vs VRT ORDER count ==\n")
cat("== B: shell indent tree vs VRT arithmetic (parent = sum of children) ==\n")
for (tb in TABLES) {
  s <- sh[sh[["tbl"]] == tb][order(line)]
  M <- wide(tb)$ESTIMATE
  say(nrow(s) == ncol(M), "%-7s shell lines %2d == VRT columns %2d", tb, nrow(s), ncol(M))
  np <- 0L; bad <- 0L
  for (i in seq_len(nrow(s))) {
    kids <- s$line[s$indent == s$indent[i] + 1L &
                   s$line > s$line[i] &
                   s$line < min(c(s$line[s$line > s$line[i] & s$indent <= s$indent[i]], Inf))]
    if (!length(kids)) next
    np <- np + 1L
    if (any(rowSums(M[, as.character(kids), drop = FALSE]) -
            M[, as.character(s$line[i])] != 0)) bad <- bad + 1L
  }
  if (np) say(bad == 0L, "%-7s %2d parent rows, %d tracts, %d mismatches",
              tb, np, nrow(M), bad)
}

## --- C --------------------------------------------------------------------
## (table, what, lines) transcribed by hand from 01_build_estimates.R,
## paired with the label the shell says those lines should carry.
cat("\n== C: VRT TITLE at every line 01_build_estimates.R indexes ==\n")
spec <- list(
  list("C17002","POV150 num", 2:5,                          "ratio below 1.50"),
  list("C17002","POV150 den", 1,                            "Total:"),
  list("B23025","UNEMP num",  5,                            "Unemployed"),
  list("B23025","UNEMP den",  3,                            "Civilian labor force:"),
  list("B25106","HBURD num",  c(6,10,14,18,28,32,36,40),    "30 percent or more"),
  list("B15002","NOHSDP num", c(3:10, 20:27),               "below HS diploma"),
  list("B15002","NOHSDP den", 1,                            "Total:"),
  list("B27001","UNINSUR num",c(seq(5,29,3), seq(33,57,3)), "No health insurance coverage"),
  list("B27001","UNINSUR den",1,                            "Total:"),
  list("B01001","AGE65 num",  c(20:25, 44:49),              "65+ age bands"),
  list("B01001","AGE17 num",  c(3:6, 27:30),                "under-18 age bands"),
  list("B18101","DISABL num", c(seq(4,19,3), seq(23,38,3)), "With a disability"),
  list("B18101","DISABL den", 1,                            "Total:"),
  list("B11012","SNGPNT num", c(10, 15),                    "With children of the householder under 18 years"),
  list("B16005","LIMENG num", c(7,8,12,13,17,18,22,23,29,30,34,35,39,40,44,45),
                                                            "not well / not at all"),
  list("B16005","LIMENG den", 1,                            "Total:"),
  list("B03002","MINRTY 1-3", c(1, 3),                      "Total: / White alone"),
  list("B25024","MUNIT num",  7:9,                          "10+ unit structures"),
  list("B25024","MOBILE num", 10,                           "Mobile home"),
  list("B25024","HU den",     1,                            "Total:"),
  list("B25014","CROWD num",  c(5,6,7,11,12,13),            ">1.00 occupants per room"),
  list("B25014","OCCHU den",  1,                            "Total:"),
  list("B25044","NOVEH num",  c(3, 10),                     "No vehicle available"),
  list("B26001","GROUPQ num", 1,                            "Total:"),
  list("B01003","TOTPOP den", 1,                            "Total"),
  list("B25003","HH den",     1,                            "Total:"))
tt <- list()
for (s in spec) {
  tb <- s[[1]]
  if (is.null(tt[[tb]])) {
    d <- unique(vrt(tb)[, .(ORDER, TITLE)])[order(ORDER)]
    stopifnot(!any(duplicated(d$ORDER)))   # one TITLE per ORDER, no drift by tract
    tt[[tb]] <- setNames(d$TITLE, d$ORDER)
  }
  cat(sprintf("  %-7s %-12s expect %s\n", tb, s[[2]], s[[4]]))
  for (l in s[[3]]) cat(sprintf("      %3d  %s\n", l, tt[[tb]][as.character(l)]))
}

## --- D1: denominator substitutions must be bit-identical, all 81 slices ----
cat("\n== D1: denominators the code takes from a different table ==\n")
VAL <- c("ESTIMATE", paste0("Var_Rep", 1:80))
cell <- function(tb, line) {
  d <- vrt(tb, VAL)[ORDER == line][order(GEOID)]
  list(g = d$GEOID, m = as.matrix(d[, ..VAL]))
}
same <- function(a, la, b, lb) {
  x <- cell(a, la); y <- cell(b, lb)
  stopifnot(identical(x$g, y$g))
  say(all(x$m == y$m), "%s L%d == %s L%d  (%d tracts x 81 slices, %d differing cells)",
      a, la, b, lb, length(x$g), sum(x$m != y$m))
}
same("B01003", 1, "B01001", 1); same("B01003", 1, "B03002", 1)
same("B25003", 1, "B25106", 1); same("B25003", 1, "B25044", 1)
same("B25003", 1, "B25014", 1); same("B25003", 1, "B11012", 1)

## --- D2: the compensating-offset arithmetic -------------------------------
cat("\n== D2: would an off-by-one in either half of an alternating sequence",
    "\n       change the reproduced total? ==\n")
offsets <- function(tb, den, variants) {
  M <- wide(tb)$ESTIMATE
  tot <- function(ln) sum(M[, as.character(ln), drop = FALSE])
  D <- tot(den); base <- tot(variants[[1]][[2]])
  cat(sprintf("\n  %s  denominator line %d = %s\n", tb, den, format(D, big.mark = ",")))
  for (v in variants)
    cat(sprintf("    %-26s N = %11s  EP = %6.2f%%  x%.3f\n", v[[1]],
                format(tot(v[[2]]), big.mark = ","), 100 * tot(v[[2]]) / D,
                tot(v[[2]]) / base))
  ## the structural reason: With + No == the table total, so both halves enter
  ## additively and no offset can cancel another.
  invisible(NULL)
}
offsets("B27001", 1, list(
  list("correct   5-29 / 33-57", c(seq(5,29,3), seq(33,57,3))),
  list("male -1   4-28 / 33-57", c(seq(4,28,3), seq(33,57,3))),
  list("female -1 5-29 / 32-56", c(seq(5,29,3), seq(32,56,3))),
  list("both -1   4-28 / 32-56", c(seq(4,28,3), seq(32,56,3))),
  list("male +1   6-30 / 33-57", c(seq(6,30,3), seq(33,57,3)))))
offsets("B18101", 1, list(
  list("correct   4-19 / 23-38", c(seq(4,19,3), seq(23,38,3))),
  list("male -1   3-18 / 23-38", c(seq(3,18,3), seq(23,38,3))),
  list("female -1 4-19 / 22-37", c(seq(4,19,3), seq(22,37,3))),
  list("both -1   3-18 / 22-37", c(seq(3,18,3), seq(22,37,3))),
  list("female +1 4-19 / 24-39", c(seq(4,19,3), seq(24,39,3)))))

for (tb in c("B27001", "B18101")) {
  M <- wide(tb)$ESTIMATE
  t2 <- function(ln) sum(M[, as.character(ln), drop = FALSE])
  w <- if (tb == "B27001") c(seq(4,28,3), seq(32,56,3)) else c(seq(5,20,3), seq(24,39,3))
  n <- if (tb == "B27001") c(seq(5,29,3), seq(33,57,3)) else c(seq(4,19,3), seq(23,38,3))
  say(t2(w) + t2(n) == t2(1),
      "%s: sum(other half) + sum(target half) == line 1 total (%s) -- both halves are additive, so no offset can compensate",
      tb, format(t2(1), big.mark = ","))
}

cat(sprintf("\n%s  (%d failed checks)\n",
            if (fail == 0L) "ALL CHECKS PASS" else "CHECKS FAILED", fail))
quit(status = if (fail == 0L) 0L else 1L)
