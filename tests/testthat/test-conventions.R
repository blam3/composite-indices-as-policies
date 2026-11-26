## The three CDC conventions reverse-engineered from the published 2022 file,
## each tested in isolation (docs/STATUS.md section 2).

test_that("1. SAS-style rounding is half away from zero", {
  expect_identical(svichurn:::round_sas(c(0.25, -0.25, 2.45, -2.45), 1),
                   c(0.3, -0.3, 2.5, -2.5))
  expect_identical(svichurn:::round_sas(c(0.5, 1.5, 2.5, -2.5), 0), c(1, 2, 3, -3))
  ## 0.15 is stored just below 0.15: base R rounds it down, SAS up.
  expect_identical(round(0.15, 1), 0.1)
  expect_identical(svichurn:::round_sas(0.15, 1), 0.2)
  ## a ratio landing on a half: 100 * 1 / 8 = 12.5
  expect_identical(svichurn:::round_sas(100 * 1 / 8, 0), 13)
  expect_identical(svichurn:::round_sas(c(0.04, 0.06, NA), 1), c(0, 0.1, NA))
})

test_that("2. percentile rank is (min_rank - 1) / (n_valid - 1), ties low", {
  ## n_valid = 4, not 5: missing values are out of the denominator too
  expect_identical(svichurn:::pctrank(c(10, 20, 20, 30, NA)),
                   c(0, 1, 1, 3, NA) / 3)
  expect_identical(svichurn:::pctrank(c(5, 5, 5)), c(0, 0, 0))
  expect_identical(svichurn:::pctrank(c(1, NA)), NA_real_ + c(0, 0))
  expect_identical(svichurn:::pctrank(c(Inf, 1, 2)), c(NA, 0, 1))
})

test_that("3a. component percentages are re-quantised after summation", {
  ## unit 1: 0.1% + 0.2%; unit 2: 0.3% + 0%. Raw sums differ in binary.
  num <- cbind(c(1, 3), c(2, 0)); den <- matrix(1000, 2, 2)
  expect_false(0.1 + 0.2 == 0.3)
  ep <- svichurn:::svi_ep(num, den, c("X", "X"), vars = "X")
  expect_identical(ep[1, "X"], ep[2, "X"])
  expect_identical(svichurn:::pctrank(c(ep[, "X"], 0.2)), c(0.5, 0.5, 0))
})

test_that("3b. summed ranks are re-quantised before re-ranking", {
  ## 11 units, EPL = value / 10. Unit 1: 0.1 + 0.2; unit 2: 0.3 + 0.
  A <- c(1, 3, 0, 2, 4:10); B <- c(2, 0, 1, 3:10)
  r <- svichurn:::svi_rank(cbind(A = A, B = B), themes = list(t = c("A", "B")))
  expect_false(1 / 10 + 2 / 10 == 3 / 10 + 0)
  expect_identical(r$SPL_THEMES[1], r$SPL_THEMES[2])
  expect_identical(r$RPL_THEMES[1], r$RPL_THEMES[2])
})
