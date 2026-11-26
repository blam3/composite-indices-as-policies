## Louisiana regression test: the package's pipeline must map the frozen EP
## matrix to the published CDC/ATSDR SVI 2022 RPL_ values exactly, values AND
## missingness, for all 1,379 tracts.
##
## Fixture provenance
##   generated from commit 27449b3 (main, 2026-11-25), after PR #1 (line-number
##   verification) merged, by tests/testthat/fixtures/make_fixtures.R, from
##   analysis/louisiana/code/01_build_estimates.R output on the 16 ACS 2018-2022
##   5-year VRT files, with 04_validate_pipeline.R reporting 57,368/57,368 values
##   and 57,918/57,918 missingness cells immediately before.
##   Louisiana.csv md5            92e5e6d33ec28494435ae9baa354495d
##   fixtures/la_ep_rpl.rds md5   5eb29315d8f6b21d200db643aee84644
##   fixtures/la_counts.rds md5   01194ec83c18ab2cdb77ca4fd4145ef4
##
##   la_ep_rpl.rds  EP  [1379 x 16] derived EP_ (analysis copy of svi_ep)
##                  RPL [1379 x 5]  published RPL_THEME1-4, RPL_THEMES; -999 -> NA
##   la_counts.rds  NUM, DEN [1379 x 19 x 81] integer counts, slice 1 = estimate
##
## Comparison: missingness elementwise on unnamed masks (not identical() on a
## named column, which compares attributes), values with identical() on the
## unnamed finite cells. No tolerance.

fx <- readRDS(test_path("fixtures", "la_ep_rpl.rds"))

test_that("fixture has the expected shape", {
  expect_identical(dim(fx$EP), c(1379L, 16L))
  expect_identical(colnames(fx$EP), svichurn:::SVI_VARS)
  expect_identical(dim(fx$RPL), c(1379L, 5L))
})

test_that("EP -> RPL reproduces the published Louisiana file exactly", {
  r <- svichurn:::svi_rank(fx$EP)
  mine <- cbind(r$RPL, r$RPL_THEMES)
  for (j in seq_len(5)) {
    m <- unname(mine[, j]); p <- unname(fx$RPL[, j])
    expect_true(all(is.finite(m) == is.finite(p)), label = colnames(fx$RPL)[j])
    ok <- is.finite(p)
    expect_identical(m[ok], p[ok], label = colnames(fx$RPL)[j])
  }
})

test_that("counts -> EP reproduces the frozen EP exactly", {
  cx <- readRDS(test_path("fixtures", "la_counts.rds"))
  ep <- svichurn:::svi_ep(cx$NUM[, , 1] * 1, cx$DEN[, , 1] * 1, cx$comp_var)
  expect_identical(unname(is.finite(ep)), unname(is.finite(fx$EP)))
  ok <- is.finite(fx$EP)
  expect_identical(unname(ep)[ok], unname(fx$EP)[ok])
})

test_that("composite_churn's published score is RPL_THEMES", {
  cx <- readRDS(test_path("fixtures", "la_counts.rds"))
  out <- composite_churn(cx$NUM, cx$DEN,
                         list(comp_var = cx$comp_var, themes = svichurn:::SVI_THEMES),
                         B = 2)
  p <- fx$RPL[, "RPL_THEMES"]
  expect_identical(out$unit, names(p)[is.finite(p)])
  expect_identical(out$score0, unname(p[is.finite(p)]))
})
