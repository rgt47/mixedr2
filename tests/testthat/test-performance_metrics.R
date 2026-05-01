test_that("calculate_bias is correct", {
  expect_equal(calculate_bias(c(1.1, 0.9, 1.0), 1.0), 0.0)
  expect_equal(calculate_bias(c(1.2, 1.2, 1.2), 1.0), 0.2)
})

test_that("calculate_relative_bias is correct", {
  expect_equal(calculate_relative_bias(c(1.2, 1.2), 1.0), 0.2)
  expect_true(is.na(calculate_relative_bias(c(1.0), 0)))
})

test_that("calculate_mse is correct", {
  expect_equal(calculate_mse(c(1.0, 1.0), 1.0), 0.0)
  expect_equal(calculate_mse(c(2.0, 0.0), 1.0), 1.0)
})

test_that("calculate_monotonicity_rate is correct", {
  full <- c(0.5, 0.6, 0.4)
  reduced <- c(0.3, 0.7, 0.3)
  expect_equal(calculate_monotonicity_rate(full, reduced), 2 / 3)
})

test_that("calculate_boundary_violations detects violations", {
  expect_equal(calculate_boundary_violations(c(0.5, -0.1, 1.1)), 2 / 3)
  expect_equal(calculate_boundary_violations(c(0.5, 0.3)), 0)
})

test_that("calculate_mcse_bias is positive", {
  est <- rnorm(100, mean = 0.5, sd = 0.1)
  mcse <- calculate_mcse_bias(est)
  expect_true(mcse > 0)
  expect_true(mcse < 0.05)
})

test_that("calculate_mcse_proportion handles edge cases", {
  expect_equal(
    calculate_mcse_proportion(0.5, 100),
    sqrt(0.25 / 100)
  )
  expect_true(is.na(calculate_mcse_proportion(NA, 100)))
})
