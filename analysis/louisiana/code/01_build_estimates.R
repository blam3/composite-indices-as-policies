## ---------------------------------------------------------------------------
## 01_build_estimates.R
## Assemble CDC/ATSDR SVI 2022 inputs for STATE_NAME census tracts from the
## ACS 2018-2022 5-year Variance Replicate Tables (summary level 140, STATE_FIPS).
##
## The 16 SVI percentages are built from 19 "components": a numerator (a set of
## lines from one detailed table) over a denominator. Thirteen variables are a
## single component. Three -- SNGPNT, MUNIT, CROWD -- are the sum of two
## components each, because CDC rounds each component to one decimal BEFORE
## summing (see 03_svi_pipeline.R). That detail is not in CDC's documentation;
## it was recovered by reverse-engineering the published Louisiana 2022 file
## and is required to reproduce EP_SNGPNT, EP_MUNIT and EP_CROWD exactly.
##
## Output: ~/svi/work/svi_inputs.rds
##   NUM, DEN: [tract, component, 81] -- slice 1 is the point estimate,
##   slices 2:81 are the 80 variance replicate estimates.
## ---------------------------------------------------------------------------
source(file.path(Sys.getenv("SVI_ROOT", ".."), "code", "00_config.R"))
suppressPackageStartupMessages(library(data.table))
RAW <- DIR_RAW
VALCOLS <- c("ESTIMATE", paste0("Var_Rep", 1:80))

read_vrt <- function(tbl) {
  d <- fread(VRT_FILE(tbl),
             select = c("GEOID", "ORDER", VALCOLS), showProgress = FALSE)
  d <- d[!is.na(ORDER)]
  d[, fips := substr(GEOID, 10, 20)]
  setorder(d, fips, ORDER)
  f <- unique(d$fips); nl <- max(d$ORDER)
  stopifnot(nrow(d) == length(f) * nl)
  a <- aperm(array(as.matrix(d[, ..VALCOLS]), dim = c(nl, length(f), 81)), c(2, 1, 3))
  dimnames(a) <- list(f, NULL, NULL)
  a
}

tables <- c("B01001","B01003","B03002","B11012","B15002","B16005","B18101","B23025",
            "B25003","B25014","B25024","B25044","B25106","B26001","B27001","C17002")
cat("Reading variance replicate tables...\n")
A <- setNames(lapply(tables, function(t) { cat("  ", t, "\n"); read_vrt(t) }), tables)
fips <- dimnames(A[[1]])[[1]]
for (t in tables) stopifnot(identical(dimnames(A[[t]])[[1]], fips))
cat(sprintf("%d tracts, %d tables\n", length(fips), length(tables)))

S <- function(tbl, lines) {
  x <- A[[tbl]][, lines, , drop = FALSE]
  if (length(lines) == 1L) x[, 1, ] else apply(x, c(1, 3), sum)
}

## --- universes ------------------------------------------------------------
TOTPOP <- S("B01003", 1)   # total population
HU     <- S("B25024", 1)   # housing units
HH     <- S("B25003", 1)   # households (occupied housing units)
POVUNI <- S("C17002", 1)   # population for whom poverty status is determined
CLF    <- S("B23025", 3)   # civilian labor force
POP25  <- S("B15002", 1)   # population 25 years and over
CNIPOP <- S("B27001", 1)   # civilian noninstitutionalized population
DISUNI <- S("B18101", 1)   # civilian noninstitutionalized population (disability)
POP5   <- S("B16005", 1)   # population 5 years and over
OCCHU  <- S("B25014", 1)   # occupied housing units (crowding universe)

## --- components: list(variable, numerator, denominator) -------------------
comps <- list(
  ## Theme 1: Socioeconomic Status
  list("POV150",  S("C17002", 2:5),                                POVUNI),
  list("UNEMP",   S("B23025", 5),                                  CLF),
  list("HBURD",   S("B25106", c(6,10,14,18, 28,32,36,40)),         HH),
  list("NOHSDP",  S("B15002", c(3:10, 20:27)),                     POP25),
  list("UNINSUR", S("B27001", c(seq(5,29,3), seq(33,57,3))),       CNIPOP),
  ## Theme 2: Household Characteristics
  list("AGE65",   S("B01001", c(20:25, 44:49)),                    TOTPOP),
  list("AGE17",   S("B01001", c(3:6, 27:30)),                      TOTPOP),
  list("DISABL",  S("B18101", c(seq(4,19,3), seq(23,38,3))),       DISUNI),
  list("SNGPNT",  S("B11012", 10),                                 HH),   # female householder
  list("SNGPNT",  S("B11012", 15),                                 HH),   # male householder
  list("LIMENG",  S("B16005", c(7,8,12,13,17,18,22,23,
                                29,30,34,35,39,40,44,45)),         POP5),
  ## Theme 3: Racial and Ethnic Minority Status
  list("MINRTY",  S("B03002", 1) - S("B03002", 3),                 TOTPOP),
  ## Theme 4: Housing Type / Transportation
  list("MUNIT",   S("B25024", 7),                                  HU),   # 10 to 19 units
  list("MUNIT",   S("B25024", 8:9),                                HU),   # 20 or more units
  list("MOBILE",  S("B25024", 10),                                 HU),
  list("CROWD",   S("B25014", c(5, 11)),                           OCCHU),# 1.01-1.50 per room
  list("CROWD",   S("B25014", c(6, 7, 12, 13)),                    OCCHU),# 1.51+ per room
  list("NOVEH",   S("B25044", c(3, 10)),                           HH),
  list("GROUPQ",  S("B26001", 1),                                  TOTPOP)
)

comp_var <- vapply(comps, `[[`, "", 1)
nc <- length(comps)
NUM <- DEN <- array(NA_real_, dim = c(length(fips), nc, 81),
                    dimnames = list(fips, comp_var, NULL))
for (j in seq_len(nc)) { NUM[, j, ] <- comps[[j]][[2]]; DEN[, j, ] <- comps[[j]][[3]] }

saveRDS(list(fips = fips, comp_var = comp_var, NUM = NUM, DEN = DEN,
             extra = list(TOTPOP = TOTPOP, HU = HU, HH = HH)),
        file.path(DIR_WORK, "svi_inputs.rds"))
cat(sprintf("Saved svi_inputs.rds: %d tracts x %d components x 81 draws\n", length(fips), nc))
