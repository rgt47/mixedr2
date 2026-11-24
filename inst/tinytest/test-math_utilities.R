library(tinytest)

# solve_dgp_params returns correct structure
params <- solve_dgp_params(
  target_r2m = 0.10, target_icc = 0.40,
  n_fixed = 2, re_structure = "intercept"
)
expect_true(is.list(params))
expect_equal(
  names(params),
  c("beta", "tau0", "tau1", "sigma", "var_fixed",
    "var_random", "var_total", "true_r2m", "true_r2c",
    "true_icc")
)
expect_equal(length(params$beta), 2L)
expect_equal(params$tau1, 0)

# solve_dgp_params recovers target R2m and ICC
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
    info = sprintf("R2m at r2m=%.2f, icc=%.2f",
                   targets$r2m[i], targets$icc[i])
  )
  expect_equal(
    params$true_icc, targets$icc[i],
    tolerance = 1e-10,
    info = sprintf("ICC at r2m=%.2f, icc=%.2f",
                   targets$r2m[i], targets$icc[i])
  )
}

# solve_dgp_params with slope structure
params <- solve_dgp_params(
  target_r2m = 0.20, target_icc = 0.30,
  n_fixed = 2, re_structure = "slope"
)
expect_true(params$tau1 > 0)
expect_true(params$true_r2c > params$true_r2m)

# true_r2_marginal matches solve_dgp_params
params <- solve_dgp_params(0.25, 0.30, n_fixed = 2)
r2m <- true_r2_marginal(
  params$beta, params$tau0, params$tau1, params$sigma
)
expect_equal(r2m, params$true_r2m, tolerance = 1e-10)

# true_r2_conditional matches solve_dgp_params
params <- solve_dgp_params(0.25, 0.30, n_fixed = 2)
r2c <- true_r2_conditional(
  params$beta, params$tau0, params$tau1, params$sigma
)
expect_equal(r2c, params$true_r2c, tolerance = 1e-10)

# solve_dgp_params rejects invalid inputs
expect_error(solve_dgp_params(0, 0.3))
expect_error(solve_dgp_params(1, 0.3))
expect_error(solve_dgp_params(0.3, 0))
expect_error(solve_dgp_params(0.3, 1))

# tau_ratio: the default reproduces the hard-coded 0.5 of the main
# simulation; other ratios scale tau1 and keep the target R2m
p_def <- solve_dgp_params(0.40, 0.10, re_structure = 'slope')
p_half <- solve_dgp_params(
  0.40, 0.10, re_structure = 'slope', tau_ratio = 0.5
)
expect_identical(p_def, p_half, info = 'default tau_ratio is 0.5')
expect_equal(p_def$tau1, 0.5 * p_def$tau0, info = 'tau1 = 0.5 tau0')
p_one <- solve_dgp_params(
  0.40, 0.10, re_structure = 'slope', tau_ratio = 1
)
expect_equal(p_one$tau1, p_one$tau0, info = 'tau_ratio = 1')
expect_equal(p_one$true_r2m, 0.40, tolerance = 1e-12,
             info = 'target R2m held at tau_ratio = 1')
expect_true(p_one$true_r2c > p_def$true_r2c,
            info = 'larger slope variance raises true R2c')
p_int <- solve_dgp_params(
  0.40, 0.10, re_structure = 'intercept', tau_ratio = 1
)
expect_equal(p_int$tau1, 0, info = 'tau_ratio ignored for intercept')
expect_error(solve_dgp_params(0.3, 0.3, tau_ratio = 0),
             info = 'tau_ratio must be positive')
