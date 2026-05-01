test_that("solve_dgp_params returns correct structure", {
  params <- solve_dgp_params(
    target_r2m = 0.10, target_icc = 0.40,
    n_fixed = 2, re_structure = "intercept"
  )
  expect_type(params, "list")
  expect_named(
    params,
    c("beta", "tau0", "tau1", "sigma", "var_fixed",
      "var_random", "var_total", "true_r2m", "true_r2c",
      "true_icc")
  )
  expect_length(params$beta, 2)
  expect_equal(params$tau1, 0)
})

test_that("solve_dgp_params recovers target R2m and ICC", {
  targets <- expand.grid(
    r2m = c(0.10, 0.40),
    icc = c(0.10, 0.40)
  )
  for (i in seq_len(nrow(targets))) {
    params <- solve_dgp_params(
      target_r2m = targets$r2m[i],
      target_icc = targets$icc[i],
      n_fixed = 2,
      re_structure = "intercept"
    )
    expect_equal(
      params$true_r2m, targets$r2m[i],
      tolerance = 1e-10,
      label = sprintf("R2m at r2m=%.2f, icc=%.2f",
                       targets$r2m[i], targets$icc[i])
    )
    expect_equal(
      params$true_icc, targets$icc[i],
      tolerance = 1e-10,
      label = sprintf("ICC at r2m=%.2f, icc=%.2f",
                       targets$r2m[i], targets$icc[i])
    )
  }
})

test_that("solve_dgp_params with slope structure", {
  params <- solve_dgp_params(
    target_r2m = 0.20, target_icc = 0.30,
    n_fixed = 2, re_structure = "slope"
  )
  expect_true(params$tau1 > 0)
  expect_true(params$true_r2c > params$true_r2m)
})

test_that("true_r2_marginal matches solve_dgp_params", {
  params <- solve_dgp_params(0.25, 0.30, n_fixed = 2)
  r2m <- true_r2_marginal(
    params$beta, params$tau0, params$tau1, params$sigma
  )
  expect_equal(r2m, params$true_r2m, tolerance = 1e-10)
})

test_that("true_r2_conditional matches solve_dgp_params", {
  params <- solve_dgp_params(0.25, 0.30, n_fixed = 2)
  r2c <- true_r2_conditional(
    params$beta, params$tau0, params$tau1, params$sigma
  )
  expect_equal(r2c, params$true_r2c, tolerance = 1e-10)
})

test_that("solve_dgp_params rejects invalid inputs", {
  expect_error(solve_dgp_params(0, 0.3))
  expect_error(solve_dgp_params(1, 0.3))
  expect_error(solve_dgp_params(0.3, 0))
  expect_error(solve_dgp_params(0.3, 1))
})
