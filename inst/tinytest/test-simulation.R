library(tinytest)

# run_single_replicate returns correct structure
params <- solve_dgp_params(0.20, 0.30, n_fixed = 2)
result <- run_single_replicate(
  params = params,
  n_clusters = 20, cluster_size = 10,
  re_structure = "intercept",
  n_fixed = 2, seed = 42
)

expect_true(inherits(result, "tbl_df"))
expect_equal(nrow(result), 1)
expected_cols <- c(
  "nak_r2m", "nak_r2c", "joh_r2m", "joh_r2c", "adj_r2m",
  "red_nak_r2m", "red_joh_r2m", "red_nak_r2c", "red_joh_r2c",
  "nul_nak_r2m", "nul_joh_r2m", "nul_nak_r2c", "nul_joh_r2c",
  "mis_r2m", "mis_r2c",
  "converged", "conv_warning", "singular"
)
expect_true(all(expected_cols %in% names(result)))
expect_true(result$converged)
expect_true(
  is.na(result$mis_r2m),
  info = "misspecified arm is fitted only in slope scenarios"
)

# Slope scenarios populate the omitted-slope (misspecified) arm
params_s <- solve_dgp_params(
  0.20, 0.30, n_fixed = 2, re_structure = "slope"
)
result_s <- run_single_replicate(
  params = params_s,
  n_clusters = 30, cluster_size = 10,
  re_structure = "slope",
  n_fixed = 2, seed = 42
)
expect_false(
  is.na(result_s$mis_r2m),
  info = "misspecified-fit R2m is computed in slope scenarios"
)
expect_true(
  result_s$nak_r2m != result_s$joh_r2m,
  info = "NS and Johnson arms differ in a slope replicate"
)

# run_scenario returns n_sim rows
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

# generate_simulated_results runs pilot
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
expect_identical(
  results$seed, grid$seed,
  info = 'per-replicate seed is stored in the results'
)

# A stored seed regenerates its replicate exactly
regen <- run_scenario(
  grid[2, ], 1, seeds = results$seed[2], use_parallel = FALSE
)
expect_identical(
  regen$joh_r2m, results$joh_r2m[2],
  info = 'replicate regenerates from its stored seed'
)

# tau_ratio in the grid reaches the data-generating parameters
grid_s <- create_scenario_grid(
  n_sim = 2, clusters = 20, cluster_sizes = 5, iccs = 0.30,
  r2ms = 0.20, re_structures = 'slope', tau_ratio = 1
)
res_s <- generate_simulated_results(
  grid_s, use_parallel = FALSE, verbose = FALSE
)
p_s <- solve_dgp_params(0.20, 0.30, re_structure = 'slope',
                        tau_ratio = 1)
expect_equal(res_s$true_r2c, rep(p_s$true_r2c, 2),
             info = 'tau_ratio used by run_scenario')
expect_true(all(res_s$tau_ratio == 1), info = 'tau_ratio recorded')

# Parallel and sequential runs give identical replicates. Workers
# must inherit the session RNG kind (bug found 2026-11-17).
if (requireNamespace("furrr", quietly = TRUE) &&
    requireNamespace("mixedr2", quietly = TRUE)) {
  old_kind <- RNGkind()
  RNGkind("L'Ecuyer-CMRG")
  row <- tibble::tibble(
    target_r2m = 0.10, icc = 0.10,
    n_clusters = 20, cluster_size = 5,
    re_structure = "intercept"
  )
  setup_parallel(workers = 2)
  r_par <- run_scenario(row, 3, seeds = 101:103, use_parallel = TRUE)
  teardown_parallel()
  r_seq <- run_scenario(row, 3, seeds = 101:103, use_parallel = FALSE)
  expect_equal(
    r_par$joh_r2m, r_seq$joh_r2m,
    info = "parallel and sequential replicates agree"
  )
  RNGkind(old_kind[1], old_kind[2], old_kind[3])
}
