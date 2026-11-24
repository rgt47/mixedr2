library(tinytest)

# fit_lmm returns expected structure
params <- solve_dgp_params(0.20, 0.30, n_fixed = 2)
dat <- generate_lmm_data(30, 10, params, seed = 42)
result <- fit_lmm(dat, re_structure = "intercept", n_fixed = 2)

expect_true(is.list(result))
expect_true(result$converged)
expect_true(is.logical(result$singular))
expect_true(is(result$model, "lmerMod"))

# fit_lmm handles slope structure
params <- solve_dgp_params(
  0.20, 0.30, n_fixed = 2, re_structure = "slope"
)
dat <- generate_lmm_data(30, 10, params, seed = 42)
result <- fit_lmm(dat, re_structure = "slope", n_fixed = 2)

expect_true(result$converged)

# extract_r2_nakagawa returns valid R2
params <- solve_dgp_params(0.20, 0.30, n_fixed = 2)
dat <- generate_lmm_data(50, 20, params, seed = 42)
fit <- fit_lmm(dat, re_structure = "intercept", n_fixed = 2)

r2 <- extract_r2_nakagawa(fit$model)
expect_equal(length(r2), 2L)
expect_equal(names(r2), c("R2m", "R2c"))
expect_true(r2[["R2m"]] >= 0 && r2[["R2m"]] <= 1)
expect_true(r2[["R2c"]] >= r2[["R2m"]])

# extract_r2_johnson returns valid R2
params <- solve_dgp_params(0.20, 0.30, n_fixed = 2)
dat <- generate_lmm_data(50, 20, params, seed = 42)
fit <- fit_lmm(dat, re_structure = "intercept", n_fixed = 2)

r2 <- extract_r2_johnson(fit$model)
expect_equal(length(r2), 2L)
expect_equal(names(r2), c("R2m", "R2c"))
expect_true(r2[["R2m"]] >= 0 && r2[["R2m"]] <= 1)

# compute_all_r2 returns tibble with 4 columns
params <- solve_dgp_params(0.20, 0.30, n_fixed = 2)
dat <- generate_lmm_data(50, 20, params, seed = 42)
fit <- fit_lmm(dat, re_structure = "intercept", n_fixed = 2)

r2_all <- compute_all_r2(fit$model)
expect_inherits(r2_all, "tbl_df")
expect_equal(nrow(r2_all), 1)
expect_true(
  all(c("nak_r2m", "nak_r2c", "joh_r2m", "joh_r2c")
      %in% names(r2_all))
)

# R2 estimates near truth for large samples
params <- solve_dgp_params(0.20, 0.30, n_fixed = 2)
dat <- generate_lmm_data(200, 50, params, seed = 42)
fit <- fit_lmm(dat, re_structure = "intercept", n_fixed = 2)

r2 <- extract_r2_nakagawa(fit$model)
expect_equal(r2[["R2m"]], params$true_r2m, tolerance = 0.10)
expect_equal(r2[["R2c"]], params$true_r2c, tolerance = 0.10)

# Regression guard for the referee finding (2026-11-17) that the two
# estimator arms were bitwise identical in every replicate. The NS
# (2013) arm uses the intercept variance only, so it must differ
# from the Johnson arm in a random-slope fit.
params <- solve_dgp_params(
  0.20, 0.40, n_fixed = 2, re_structure = 'slope'
)
dat <- generate_lmm_data(50, 20, params, seed = 7)
fit <- fit_lmm(dat, re_structure = 'slope', n_fixed = 2)
expect_false(fit$singular, info = 'slope fit is not singular')
r2_ns <- extract_r2_nakagawa(fit$model)
r2_j <- extract_r2_johnson(fit$model)
expect_true(
  abs(r2_ns[['R2c']] - r2_j[['R2c']]) > 1e-3,
  info = 'NS and Johnson R2c differ in a random-slope fit'
)
expect_true(
  r2_ns[['R2m']] > r2_j[['R2m']],
  info = 'NS omits slope variance, so its R2m denominator is smaller'
)

vc <- r2_variance_components(fit$model)
g_hat <- as.matrix(lme4::VarCorr(fit$model)$cluster_id)
z <- cbind(1, dat$x1)
expect_equal(
  vc[['var_joh']],
  sum(diag(z %*% g_hat %*% t(z))) / nrow(z),
  tolerance = 1e-10,
  info = 'Johnson variance equals mean of diag(Z G Z^T)'
)
expect_true(
  vc[['trace_term']] > 0,
  info = 'trace bias term of Var(X beta-hat) is positive'
)
r2_adj <- extract_r2m_adjusted(fit$model)
expect_true(
  r2_adj < r2_j[['R2m']],
  info = 'bias-adjusted R2m is below the plug-in Johnson R2m'
)

if (requireNamespace('MuMIn', quietly = TRUE)) {
  r2_mm <- extract_r2_mumin(fit$model)
  expect_equal(
    unname(r2_j), unname(r2_mm), tolerance = 1e-10,
    info = 'independent Johnson implementation matches MuMIn'
  )
}

# The two arms coincide for random-intercept fits.
params <- solve_dgp_params(0.20, 0.30, n_fixed = 2)
dat <- generate_lmm_data(50, 20, params, seed = 42)
fit <- fit_lmm(dat, re_structure = 'intercept', n_fixed = 2)
expect_equal(
  extract_r2_nakagawa(fit$model), extract_r2_johnson(fit$model),
  tolerance = 1e-12,
  info = 'NS and Johnson coincide for random-intercept fits'
)
expect_true(
  is.logical(fit$conv_warning),
  info = 'fit_lmm reports a convergence-warning flag'
)

# Null predictors do not perturb the generated data.
d0 <- generate_lmm_data(10, 5, params, seed = 3)
d1 <- generate_lmm_data(10, 5, params, seed = 3, n_null = 1)
expect_equal(
  d0$y, d1$y, info = 'adding a null predictor leaves y unchanged'
)
expect_true('x3' %in% names(d1), info = 'null predictor is x3')
