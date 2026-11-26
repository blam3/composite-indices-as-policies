## ---------------------------------------------------------------------------
## Regenerate the frozen Louisiana fixtures. Not run by R CMD check.
##
## Needs the staged inputs (data/README.md) and a prior run of
## analysis/louisiana/code/01_build_estimates.R. Run from the repository root:
##
##   export SVI_ROOT=/path/with/code-and-data      # as for run_all.sh
##   Rscript $SVI_ROOT/code/01_build_estimates.R
##   Rscript $SVI_ROOT/code/04_validate_pipeline.R # must PASS first
##   Rscript tests/testthat/fixtures/make_fixtures.R
##
## EP is derived with the ANALYSIS copy of the pipeline
## (analysis/louisiana/code/03_svi_pipeline.R), not the package's, so the
## regression test checks the package against the code the gate validated.
## ---------------------------------------------------------------------------
root <- Sys.getenv("SVI_ROOT")
stopifnot(nzchar(root))
source("analysis/louisiana/code/03_svi_pipeline.R")

inp <- readRDS(file.path(root, "work", "svi_inputs.rds"))
cdc <- utils::read.csv(file.path(root, "data", "raw", "Louisiana.csv"),
                       colClasses = c(FIPS = "character"), check.names = FALSE,
                       fileEncoding = "UTF-8-BOM")
keep <- match(cdc$FIPS, inp$fips)
stopifnot(!anyNA(keep), length(keep) == 1379L)

## 1. EP -> RPL regression fixture: derived EP, published RPL (-999 -> NA).
EP <- svi_ep(inp$NUM[keep, , 1], inp$DEN[keep, , 1], inp$comp_var)
rpl_cols <- c(sprintf("RPL_THEME%d", 1:4), "RPL_THEMES")
RPL <- as.matrix(cdc[, rpl_cols])
RPL[RPL == -999] <- NA_real_
dimnames(RPL) <- list(cdc$FIPS, rpl_cols)
saveRDS(list(EP = EP, RPL = RPL), "tests/testthat/fixtures/la_ep_rpl.rds",
        compress = "xz")

## 2. Count-level inputs with all 80 replicates, for the vignette and the
##    count -> EP test. ACS counts are integers; stored as integer to halve size.
NUM <- inp$NUM[keep, , ]; DEN <- inp$DEN[keep, , ]
stopifnot(all(NUM == round(NUM)), all(DEN == round(DEN)))
storage.mode(NUM) <- "integer"; storage.mode(DEN) <- "integer"
saveRDS(list(NUM = NUM, DEN = DEN, comp_var = inp$comp_var),
        "tests/testthat/fixtures/la_counts.rds", compress = "xz")

print(tools::md5sum(c("tests/testthat/fixtures/la_ep_rpl.rds",
                      "tests/testthat/fixtures/la_counts.rds")))
