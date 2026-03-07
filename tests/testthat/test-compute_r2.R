test_that("fit_lmm returns expected structure", {
  params <- solve_dgp_params(0.20, 0.30, n_fixed = 2)
  dat <- generate_lmm_data(30, 10, params, seed = 42)
  result <- fit_lmm(dat, re_structure = "intercept", n_fixed = 2)

  expect_type(result, "list")
  expect_true(result$converged)
  expect_type(result$singular, "logical")
  expect_s4_class(result$model, "lmerMod")
})

test_that("fit_lmm handles slope structure", {
  params <- solve_dgp_params(
    0.20, 0.30, n_fixed = 2, re_structure = "slope"
  )
  dat <- generate_lmm_data(30, 10, params, seed = 42)
  result <- fit_lmm(dat, re_structure = "slope", n_fixed = 2)

  expect_true(result$converged)
})

test_that("extract_r2_nakagawa returns valid R2", {
  params <- solve_dgp_params(0.20, 0.30, n_fixed = 2)
  dat <- generate_lmm_data(50, 20, params, seed = 42)
  fit <- fit_lmm(dat, re_structure = "intercept", n_fixed = 2)

  r2 <- extract_r2_nakagawa(fit$model)
  expect_length(r2, 2)
  expect_named(r2, c("R2m", "R2c"))
  expect_true(r2[["R2m"]] >= 0 && r2[["R2m"]] <= 1)
  expect_true(r2[["R2c"]] >= r2[["R2m"]])
})

test_that("extract_r2_johnson returns valid R2", {
  params <- solve_dgp_params(0.20, 0.30, n_fixed = 2)
  dat <- generate_lmm_data(50, 20, params, seed = 42)
  fit <- fit_lmm(dat, re_structure = "intercept", n_fixed = 2)

  r2 <- extract_r2_johnson(fit$model)
  expect_length(r2, 2)
  expect_named(r2, c("R2m", "R2c"))
  expect_true(r2[["R2m"]] >= 0 && r2[["R2m"]] <= 1)
})

test_that("compute_all_r2 returns tibble with 4 columns", {
  params <- solve_dgp_params(0.20, 0.30, n_fixed = 2)
  dat <- generate_lmm_data(50, 20, params, seed = 42)
  fit <- fit_lmm(dat, re_structure = "intercept", n_fixed = 2)

  r2_all <- compute_all_r2(fit$model)
  expect_s3_class(r2_all, "tbl_df")
  expect_equal(nrow(r2_all), 1)
  expect_true(
    all(c("nak_r2m", "nak_r2c", "joh_r2m", "joh_r2c")
        %in% names(r2_all))
  )
})

test_that("R2 estimates near truth for large samples", {
  params <- solve_dgp_params(0.20, 0.30, n_fixed = 2)
  dat <- generate_lmm_data(200, 50, params, seed = 42)
  fit <- fit_lmm(dat, re_structure = "intercept", n_fixed = 2)

  r2 <- extract_r2_nakagawa(fit$model)
  expect_equal(r2[["R2m"]], params$true_r2m, tolerance = 0.10)
  expect_equal(r2[["R2c"]], params$true_r2c, tolerance = 0.10)
})
