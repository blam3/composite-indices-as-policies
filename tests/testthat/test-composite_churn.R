sim <- function(n = 40, R = 80, sd = 30) {
  set.seed(7)
  den <- array(1000, c(n, 2, R + 1))
  base <- matrix(rep(seq(50, 400, length.out = n), 2), n, 2)
  num <- array(base, c(n, 2, R + 1))
  num[, , -1] <- num[, , -1] + rnorm(n * 2 * R, 0, sd)
  list(num = num, den = den, spec = list(comp_var = c("a", "b")))
}

test_that("no replicate variance means no churn", {
  s <- sim(sd = 0)
  out <- composite_churn(s$num, s$den, s$spec, B = 20, scale = 4 / 80)
  ch <- attr(out, "churn")
  expect_equal(ch$expected_leavers, 0)
  expect_equal(ch$expected_label_changes, 0)
  expect_true(all(out$p_change == 0))
})

test_that("label changes are leavers plus entrants, never leavers twice", {
  s <- sim()
  s$spec$threshold <- c(0.9, 0.75)
  out <- composite_churn(s$num, s$den, s$spec, B = 200)
  ch <- attr(out, "churn")
  expect_identical(ch$threshold, c(0.9, 0.75))
  expect_equal(ch$expected_label_changes, ch$expected_leavers + ch$expected_entrants)
  expect_equal(ch$leaver_rate, ch$expected_leavers / ch$n_funded)
  expect_true(all(out$p_leave[!out$funded0] == 0), all(out$p_enter[out$funded0] == 0))
  expect_true(all(out$p_change >= 0 & out$p_change <= 1))
})

test_that("weights, normalisation and aggregation are honoured", {
  s <- sim()
  s$spec$weights <- c(a = 2, b = 0)
  s$spec$aggregate <- "sum"
  s$spec$threshold <- 1.5
  s$spec$normalize <- function(x) x / max(x, na.rm = TRUE)
  out <- composite_churn(s$num, s$den, s$spec, B = 5)
  ep <- svichurn:::round_sas(100 * s$num[, 1, 1] / 1000, 1)
  expect_identical(out$score0, round(2 * round(ep / max(ep), 4), 4))
  expect_identical(out$funded0, out$score0 >= 1.5)
})

test_that("bad input is rejected", {
  s <- sim()
  expect_error(composite_churn(s$num, s$den[, , 1], s$spec))
  expect_error(composite_churn(s$num, s$den, list(comp_var = "a")))
  expect_error(composite_churn(s$num, s$den, list(comp_var = c("a", "b"),
                                                  themes = list(t = "a"))))
})
