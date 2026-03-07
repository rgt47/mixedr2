test_that("run_single_replicate returns correct structure", {
  params <- solve_dgp_params(0.20, 0.30, n_fixed = 2)
  result <- run_single_replicate(
    params = params,
    n_clusters = 20, cluster_size = 10,
    re_structure = "intercept",
    n_fixed = 2, seed = 42
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expected_cols <- c(
    "nak_r2m", "nak_r2c", "joh_r2m", "joh_r2c",
    "red_nak_r2m", "red_joh_r2m",
    "converged", "singular"
  )
  expect_true(all(expected_cols %in% names(result)))
  expect_true(result$converged)
})

test_that("run_scenario returns n_sim rows", {
  params_row <- tibble::tibble(
    target_r2m = 0.20, icc = 0.30,
    n_clusters = 20, cluster_size = 10,
    re_structure = "intercept"
  )
  results <- run_scenario(
    scenario_row = params_row,
    n_sim = 5,
    seeds = 1:5,
    use_parallel = FALSE
  )

  expect_equal(nrow(results), 5)
  expect_true("true_r2m" %in% names(results))
  expect_true("true_r2c" %in% names(results))
})

test_that("generate_simulated_results runs pilot", {
  grid <- create_scenario_grid(
    n_sim = 3,
    clusters = 20,
    cluster_sizes = 5,
    iccs = 0.30,
    r2ms = 0.20,
    re_structures = "intercept"
  )

  results <- generate_simulated_results(
    grid, use_parallel = FALSE, verbose = FALSE
  )

  expect_equal(nrow(results), 3)
  expect_true("scenario_id" %in% names(results))
})
